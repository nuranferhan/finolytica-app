import '../core/supabase.dart';
import '../models/investment.dart';
import '../models/savings_goal.dart';
import '../models/watchlist.dart';
import '../models/transaction.dart';
import 'alpha_vantage_service.dart';

class InvestmentService {
  final _client = SupabaseConfig.client;

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final userId = SupabaseConfig.currentUser?.id;
    print('🔍 getSavingsGoals - User ID: $userId'); // Debug log
    
    if (userId == null) {
      print('❌ User not authenticated');
      return [];
    }

    try {
      final response = await _client
          .from('savings_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('✅ getSavingsGoals success - ${response.length} goals found');
      return (response as List)
          .map((item) => SavingsGoal.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Error in getSavingsGoals: $e');
      return [];
    }
  }

  Future<SavingsGoal> addSavingsGoal(SavingsGoal goal) async {
    final userId = SupabaseConfig.currentUser?.id;
    print('🔍 addSavingsGoal - User ID: $userId'); // Debug log
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final goalMap = goal.toMap();
    goalMap['user_id'] = userId;

    print('📤 Adding goal with data: $goalMap'); // Debug log

    try {
      final response = await _client
          .from('savings_goals')
          .insert(goalMap)
          .select()
          .single();

      print('✅ addSavingsGoal success');
      return SavingsGoal.fromMap(response);
    } catch (e) {
      print('❌ Error in addSavingsGoal: $e');
      throw e;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    if (goal.id == null || goal.id!.isEmpty) {
      throw Exception('Goal ID is required for update');
    }

    final goalMap = goal.toMap();
    goalMap.remove('user_id'); // Update'te user_id gönderme

    await _client
        .from('savings_goals')
        .update(goalMap)
        .eq('id', goal.id!);
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    if (goalId.isEmpty) {
      throw Exception('Goal ID is required for delete');
    }

    await _client
        .from('goal_transactions')
        .delete()
        .eq('goal_id', goalId);
    
    await _client
        .from('savings_goals')
        .delete()
        .eq('id', goalId);
  }

  Future<void> addToGoal(String goalId, double amount, String description) async {
    final userId = SupabaseConfig.currentUser?.id;
    
    print('🔍 addToGoal Debug Info:');
    print('   Goal ID: "$goalId" (length: ${goalId.length})');
    print('   User ID: "$userId" (is null: ${userId == null})');
    print('   Amount: $amount');
    print('   Description: "$description"');
    
    if (userId == null || userId.isEmpty) {
      print('❌ User not authenticated or empty');
      throw Exception('User not authenticated');
    }

    if (goalId.isEmpty) {
      print('❌ Goal ID is empty');
      throw Exception('Goal ID is required');
    }

    if (amount <= 0) {
      print('❌ Amount is not positive: $amount');
      throw Exception('Amount must be positive');
    }

    try {
      print('🔄 Starting goal transaction...');
      
      final goalCheck = await _client
          .from('savings_goals')
          .select('id, title, user_id, current_amount, target_amount')
          .eq('id', goalId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (goalCheck == null) {
        throw Exception('Hedef bulunamadı veya size ait değil');
      }
      
      print('✅ Goal found: ${goalCheck['title']}');
      
      final balanceResult = await _client
          .rpc('calculate_user_balance', params: {'user_uuid': userId});
      
      final currentBalance = (balanceResult as num?)?.toDouble() ?? 0.0;
      print('💰 Current user balance: $currentBalance');
      
      if (currentBalance < amount) {
        throw Exception('Yetersiz bakiye! Mevcut bakiye: ₺${currentBalance.toStringAsFixed(2)}');
      }
      
      final goalTransactionData = {
        'user_id': userId,
        'goal_id': goalId,
        'amount': amount,
        'description': description.isEmpty ? 'Para eklendi' : description,
        'transaction_date': DateTime.now().toIso8601String().split('T')[0],
      };

      print('📤 Inserting goal transaction: $goalTransactionData');
      
      final goalTransactionResult = await _client
          .from('goal_transactions')
          .insert(goalTransactionData)
          .select()
          .single();

      print('✅ Goal transaction inserted: ${goalTransactionResult['id']}');
      print('🎯 SQL triggers will automatically:');
      print('   - Update goal current_amount');
      print('   - Check completion status');
      print('   - Sync to main transactions table');
      print('✅ addToGoal completed successfully');
      
    } catch (e) {
      print('❌ Database error in addToGoal: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getGoalTransactions(String goalId) async {
    if (goalId.isEmpty) return [];

    try {
      final response = await _client
          .from('goal_transactions')
          .select()
          .eq('goal_id', goalId)
          .order('transaction_date', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error in getGoalTransactions: $e');
      return [];
    }
  }

  
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      return {
        'totalGoalsTarget': 0.0,
        'totalGoalsCurrent': 0.0,
        'completedGoals': 0,
        'totalGoals': 0,
        'watchlistItems': 0,
        'goalsProgress': 0.0,
      };
    }

    try {
      print('📊 Getting financial summary for user: $userId');
      
      final summaryResult = await _client
          .rpc('get_financial_summary', params: {'user_uuid': userId});
      
      if (summaryResult != null && summaryResult.isNotEmpty) {
        final summary = summaryResult[0] as Map<String, dynamic>;
        
        print('✅ Financial summary from SQL:');
        print('   Total Goals Target: ${summary['total_goals_target']}');
        print('   Total Goals Current: ${summary['total_goals_current']}');
        print('   Completed Goals: ${summary['completed_goals']}');
        print('   Total Goals: ${summary['total_goals']}');
        print('   Goals Progress: ${summary['goals_progress']}%');
        
        return {
          'totalGoalsTarget': (summary['total_goals_target'] ?? 0).toDouble(),
          'totalGoalsCurrent': (summary['total_goals_current'] ?? 0).toDouble(),
          'completedGoals': summary['completed_goals'] ?? 0,
          'totalGoals': summary['total_goals'] ?? 0,
          'watchlistItems': 0, // Watchlist ayrı olarak hesaplanabilir
          'goalsProgress': (summary['goals_progress'] ?? 0).toDouble(),
        };
      } else {
        print('⚠️ No summary data returned from SQL function');
      }
    } catch (e) {
      print('❌ Error getting financial summary from SQL: $e');
      print('🔄 Falling back to manual calculation...');
    }

    try {
      final goals = await getSavingsGoals();
      final watchlistItems = await getWatchlist();
      
      double totalGoalsTarget = goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
      double totalGoalsCurrent = goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
      int completedGoals = goals.where((goal) => goal.isCompleted).length;
      
      print('📊 Manual calculation results:');
      print('   Total Goals Target: $totalGoalsTarget');
      print('   Total Goals Current: $totalGoalsCurrent');
      print('   Completed Goals: $completedGoals');
      print('   Total Goals: ${goals.length}');
      
      return {
        'totalGoalsTarget': totalGoalsTarget,
        'totalGoalsCurrent': totalGoalsCurrent,
        'completedGoals': completedGoals,
        'totalGoals': goals.length,
        'watchlistItems': watchlistItems.length,
        'goalsProgress': totalGoalsTarget > 0 ? (totalGoalsCurrent / totalGoalsTarget) * 100 : 0.0,
      };
    } catch (e) {
      print('❌ Error in manual financial summary calculation: $e');
      return {
        'totalGoalsTarget': 0.0,
        'totalGoalsCurrent': 0.0,
        'completedGoals': 0,
        'totalGoals': 0,
        'watchlistItems': 0,
        'goalsProgress': 0.0,
      };
    }
  }

  
  Future<List<WatchlistItem>> getWatchlist() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('watchlist')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => WatchlistItem.fromMap(item))
          .toList();
    } catch (e) {
      print('Error in getWatchlist: $e');
      return [];
    }
  }

  Future<WatchlistItem> addToWatchlist(WatchlistItem item) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final itemMap = item.toMap();
    itemMap['user_id'] = userId;

    print('Adding to watchlist with data: $itemMap'); // Debug log

    final response = await _client
        .from('watchlist')
        .insert(itemMap)
        .select()
        .single();

    return WatchlistItem.fromMap(response);
  }

  Future<void> removeFromWatchlist(String itemId) async {
    if (itemId.isEmpty) {
      throw Exception('Item ID is required for removal');
    }

    await _client
        .from('watchlist')
        .delete()
        .eq('id', itemId);
  }

  Future<void> updateExchangeRates() async {
    print('🔄 Updating exchange rates from Alpha Vantage...');
    
    try {
      final forexRates = await AlphaVantageService.getPopularForexRates();
      
      for (var rate in forexRates) {
        try {
          await _client
              .from('exchange_rates')
              .upsert({
                'base_currency': 'TRY',
                'target_currency': rate['symbol'],
                'rate': 1 / rate['current_price'], // TRY -> Foreign currency
                'last_updated': DateTime.now().toIso8601String(),
              });

          final userId = SupabaseConfig.currentUser?.id;
          if (userId != null) {
            final existingData = await _client
                .from('watchlist')
                .select('current_price')
                .eq('user_id', userId)
                .eq('symbol', rate['symbol'])
                .eq('type', 'forex')
                .maybeSingle();

            if (existingData != null) {
              await _client
                  .from('watchlist')
                  .update({
                    'previous_price': existingData['current_price'],
                    'current_price': rate['current_price'],
                    'last_updated': DateTime.now().toIso8601String(),
                  })
                  .eq('user_id', userId)
                  .eq('symbol', rate['symbol'])
                  .eq('type', 'forex');
              
              print('✅ Updated ${rate['symbol']}: ${rate['current_price']}');
            }
          }
        } catch (e) {
          print('❌ Error updating exchange rate for ${rate['symbol']}: $e');
        }
      }
      
      print('✅ Exchange rates update completed');
    } catch (e) {
      print('❌ Error in updateExchangeRates: $e');
      await _updateMockRates();
    }
  }


  Future<WatchlistItem> addStockToWatchlist(String symbol) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final stockData = await AlphaVantageService.getStockQuote(symbol);
      if (stockData == null) {
        throw Exception('Stock data not found for $symbol');
      }

      final item = WatchlistItem(
        userId: userId,
        symbol: symbol.toUpperCase(),
        name: AlphaVantageService.getStockName(symbol.toUpperCase()), // Public metod kullanımı
        type: 'stock',
        currentPrice: stockData['price'],
        previousPrice: stockData['price'] - stockData['change'],
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      return await addToWatchlist(item);
    } catch (e) {
      print('❌ Error adding stock to watchlist: $e');
      throw e;
    }
  }

  Future<WatchlistItem> addCryptoToWatchlist(String symbol) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final cryptoData = await AlphaVantageService.getCryptoQuote(symbol);
      if (cryptoData == null) {
        throw Exception('Crypto data not found for $symbol');
      }

      final item = WatchlistItem(
        userId: userId,
        symbol: symbol.toUpperCase(),
        name: AlphaVantageService.getCryptoName(symbol.toUpperCase()), // Public metod kullanımı
        type: 'crypto',
        currentPrice: cryptoData['price_try'],
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      return await addToWatchlist(item);
    } catch (e) {
      print('❌ Error adding crypto to watchlist: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await AlphaVantageService.searchSymbols(query);
    } catch (e) {
      print('❌ Error searching symbols: $e');
      return [];
    }
  }

  Future<void> updateWatchlistPrices() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return;

    try {
      final watchlistItems = await getWatchlist();
      
      for (var item in watchlistItems) {
        try {
          Map<String, dynamic>? newData;
          
          switch (item.type) {
            case 'forex':
              newData = await AlphaVantageService.getForexRate(item.symbol, 'TRY');
              if (newData != null) {
                await _client
                    .from('watchlist')
                    .update({
                      'previous_price': item.currentPrice,
                      'current_price': newData['rate'],
                      'last_updated': DateTime.now().toIso8601String(),
                    })
                    .eq('id', item.id!);
              }
              break;
              
            case 'stock':
              newData = await AlphaVantageService.getStockQuote(item.symbol);
              if (newData != null) {
                await _client
                    .from('watchlist')
                    .update({
                      'previous_price': item.currentPrice,
                      'current_price': newData['price'],
                      'last_updated': DateTime.now().toIso8601String(),
                    })
                    .eq('id', item.id!);
              }
              break;
              
            case 'crypto':
              newData = await AlphaVantageService.getCryptoQuote(item.symbol);
              if (newData != null) {
                await _client
                    .from('watchlist')
                    .update({
                      'previous_price': item.currentPrice,
                      'current_price': newData['price_try'],
                      'last_updated': DateTime.now().toIso8601String(),
                    })
                    .eq('id', item.id!);
              }
              break;
          }
          
          await Future.delayed(Duration(seconds: 1));
          
        } catch (e) {
          print('❌ Error updating ${item.symbol}: $e');
        }
      }
      
      print('✅ Watchlist prices updated');
    } catch (e) {
      print('❌ Error in updateWatchlistPrices: $e');
    }
  }

Future<void> _updateMockRates() async {
  final mockRates = {
    'USD': 33.45 + (DateTime.now().millisecond % 100 - 50) * 0.01,
    'EUR': 36.20 + (DateTime.now().millisecond % 100 - 50) * 0.01,
    'GBP': 42.15 + (DateTime.now().millisecond % 100 - 50) * 0.01,
    'CHF': 37.80 + (DateTime.now().millisecond % 100 - 50) * 0.01,
  };

  for (var entry in mockRates.entries) {
    try {
      await _client
          .from('exchange_rates')
          .upsert({
            'base_currency': 'TRY',
            'target_currency': entry.key,
            'rate': 1 / entry.value,
            'last_updated': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating mock rate for ${entry.key}: $e');
    }
  }
}

  Future<void> addDefaultWatchlistItems() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final defaultItems = [
      {'symbol': 'USD', 'name': 'Amerikan Doları', 'type': 'forex'},
      {'symbol': 'EUR', 'name': 'Euro', 'type': 'forex'},
      {'symbol': 'GBP', 'name': 'İngiliz Sterlini', 'type': 'forex'},
    ];

    for (var item in defaultItems) {
      try {
        final existing = await _client
            .from('watchlist')
            .select('id')
            .eq('user_id', userId)
            .eq('symbol', item['symbol']!)
            .maybeSingle();

        if (existing == null) {
          await addToWatchlist(WatchlistItem(
            userId: userId,
            symbol: item['symbol']!,
            name: item['name']!,
            type: item['type']!,
            lastUpdated: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        }
      } catch (e) {
        print('Item already exists or error: ${item['symbol']} - $e');
      }
    }
  }

  
  Future<List<InvestmentModel>> getInvestments() async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('investments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => InvestmentModel.fromMap(item))
        .toList();
  }

  Future<InvestmentModel> addInvestment(InvestmentModel investment) async {
    final response = await _client
        .from('investments')
        .insert(investment.toMap())
        .select()
        .single();

    return InvestmentModel.fromMap(response);
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _client
        .from('investments')
        .update(investment.toMap())
        .eq('id', investment.id!);
  }

  Future<void> deleteInvestment(String investmentId) async {
    await _client
        .from('investments')
        .delete()
        .eq('id', investmentId);
  }
}