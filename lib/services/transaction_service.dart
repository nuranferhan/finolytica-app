import '../core/supabase.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';

class TransactionService {
  final _client = SupabaseConfig.client;

  
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG getRecentTransactions - Current user ID: $userId');
      
      if (userId == null) {
        print('DEBUG: No user logged in');
        return [];
      }

      final response = await _client
          .from('transactions')
          .select('''
            id,
            title,
            amount,
            type,
            description,
            date,
            created_at,
            user_id,
            category_id,
            categories (
              id,
              name,
              icon,
              color,
              type
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      print('DEBUG: Raw response from Supabase: $response');
      print('DEBUG: Response length: ${(response as List).length}');

      return (response as List)
          .map((item) => TransactionModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getRecentTransactions error: $e');
      return [];
    }
  }

  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG addTransaction - Adding for user: $userId');
      print('DEBUG addTransaction - Current user ID: $userId');
      print('DEBUG addTransaction - Transaction user ID: ${transaction.userId}');
      print('DEBUG addTransaction - Transaction data: ${transaction.toMap()}');
      
      // Güvenlik kontrolü
      if (userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      if (transaction.userId != userId) {
        throw Exception('Güvenlik hatası: Kullanıcı ID uyumsuzluğu');
      }
      
      final response = await _client
          .from('transactions')
          .insert(transaction.toMap())
          .select('''
            id,
            title,
            amount,
            type,
            description,
            date,
            created_at,
            user_id,
            category_id,
            categories (
              id,
              name,
              icon,
              color,
              type,
              created_at
            )
          ''')
          .single();

      print('DEBUG addTransaction - Response: $response');
      return TransactionModel.fromMap(response);
    } catch (e) {
      print('DEBUG addTransaction - Error: $e');
      throw Exception('İşlem eklenirken hata oluştu: $e');
    }
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG getTransactionsByDateRange - Current user ID: $userId');
      
      if (userId == null) return [];

      final response = await _client
          .from('transactions')
          .select('''
            id,
            title,
            amount,
            type,
            description,
            date,
            created_at,
            user_id,
            category_id,
            categories (
              id,
              name,
              icon,
              color,
              type,
              created_at
            )
          ''')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first)
          .order('date', ascending: false);

      print('DEBUG getTransactionsByDateRange - Response length: ${(response as List).length}');

      return (response as List)
          .map((item) => TransactionModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getTransactionsByDateRange error: $e');
      return [];
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG updateTransaction - Current user ID: $userId');
      
      if (userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      if (transaction.userId != userId) {
        throw Exception('Güvenlik hatası: Bu işlemi güncelleme yetkiniz yok');
      }
      
      await _client
          .from('transactions')
          .update(transaction.toMap())
          .eq('id', transaction.id!)
          .eq('user_id', userId); // Ekstra güvenlik
    } catch (e) {
      throw Exception('İşlem güncellenirken hata oluştu: $e');
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG deleteTransaction - Current user ID: $userId');
      
      if (userId == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      await _client
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', userId); // Ekstra güvenlik
    } catch (e) {
      throw Exception('İşlem silinirken hata oluştu: $e');
    }
  }

  Future<Map<String, double>> getMonthlyStats(DateTime month) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG getMonthlyStats - Current user ID: $userId');
      
      if (userId == null) return {'income': 0, 'expense': 0};

      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);

      final response = await _client
          .from('transactions')
          .select('amount, type')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      print('DEBUG getMonthlyStats - Response length: ${response.length}');

      double income = 0;
      double expense = 0;

      for (var item in response) {
        if (item['type'] == 'income') {
          income += (item['amount'] as num).toDouble();
        } else {
          expense += (item['amount'] as num).toDouble();
        }
      }

      return {'income': income, 'expense': expense};
    } catch (e) {
      print('getMonthlyStats error: $e');
      return {'income': 0, 'expense': 0};
    }
  }

  Future<List<TransactionModel>> getAllTransactions({int? limit, int? offset}) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      print('DEBUG getAllTransactions - Current user ID: $userId');
      
      if (userId == null) return [];

      var query = _client
          .from('transactions')
          .select('''
            id,
            title,
            amount,
            type,
            description,
            date,
            created_at,
            user_id,
            category_id,
            categories (
              id,
              name,
              icon,
              color,
              type,
              created_at
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      print('DEBUG getAllTransactions - Response length: ${(response as List).length}');

      return (response as List)
          .map((item) => TransactionModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getAllTransactions error: $e');
      return [];
    }
  }

  Future<void> createDefaultCategories() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı girişi gerekli');

      print('DEBUG createDefaultCategories - Creating for user: $userId');

      final existingCategories = await _client
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if ((existingCategories as List).isNotEmpty) {
        print('DEBUG: User already has categories, skipping default creation');
        return;
      }

      final categoriesToInsert = <Map<String, dynamic>>[];
      
      for (var cat in AppConstants.defaultCategories) {
        if (cat['type'] == 'both') {
          categoriesToInsert.add({
            'name': cat['name'],
            'icon': cat['icon'],
            'color': cat['color'].toString(),
            'type': 'expense',
            'user_id': userId,
          });
          categoriesToInsert.add({
            'name': cat['name'],
            'icon': cat['icon'],
            'color': cat['color'].toString(),
            'type': 'income',
            'user_id': userId,
          });
        } else {
          categoriesToInsert.add({
            'name': cat['name'],
            'icon': cat['icon'],
            'color': cat['color'].toString(),
            'type': cat['type'],
            'user_id': userId,
          });
        }
      }

      await _client.from('categories').insert(categoriesToInsert);
      print('DEBUG: Default categories created successfully - ${categoriesToInsert.length} categories');
    } catch (e) {
      print('createDefaultCategories error: $e');
      throw Exception('Default kategoriler oluşturulurken hata: $e');
    }
  }

  Future<List<CategoryModel>> getCategoriesByType(CategoryType type) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      final typeString = type == CategoryType.income ? 'income' : 'expense';
      
      print('DEBUG getCategoriesByType - User: $userId, Type: $typeString');
      
      final response = await _client
          .from('categories')
          .select('id, name, icon, color, type, user_id, created_at')
          .eq('user_id', userId)
          .eq('type', typeString)
          .order('name');

      print('DEBUG getCategoriesByType - Found ${(response as List).length} categories');

      return (response as List)
          .map((item) => CategoryModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getCategoriesByType error: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('categories')
          .select('id, name, icon, color, type, user_id, created_at')
          .eq('user_id', userId)
          .order('type')
          .order('name');

      return (response as List)
          .map((item) => CategoryModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getAllCategories error: $e');
      return [];
    }
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı girişi gerekli');

      if (category.userId != userId) {
        throw Exception('Güvenlik hatası: Kullanıcı ID uyumsuzluğu');
      }

      final response = await _client
          .from('categories')
          .insert(category.toMap())
          .select('id, name, icon, color, type, user_id, created_at')
          .single();

      return CategoryModel.fromMap(response);
    } catch (e) {
      print('addCategory error: $e');
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı girişi gerekli');

      if (category.userId != userId) {
        throw Exception('Güvenlik hatası: Bu kategoriyi güncelleme yetkiniz yok');
      }

      await _client
          .from('categories')
          .update(category.toMap())
          .eq('id', category.id!)
          .eq('user_id', userId); // Ekstra güvenlik
    } catch (e) {
      throw Exception('Kategori güncellenirken hata oluştu: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı girişi gerekli');

      await _client
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .eq('user_id', userId); // Ekstra güvenlik
    } catch (e) {
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }

  Future<List<TransactionModel>> getTransactionsByCategory(String categoryId) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('transactions')
          .select('''
            id,
            title,
            amount,
            type,
            description,
            date,
            created_at,
            user_id,
            category_id,
            categories (
              id,
              name,
              icon,
              color,
              type,
              created_at
            )
          ''')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => TransactionModel.fromMap(item))
          .toList();
    } catch (e) {
      print('getTransactionsByCategory error: $e');
      return [];
    }
  }

  Future<Map<String, double>> getCategoryStatsForMonth(DateTime month, CategoryType type) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return {};

      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      final typeString = type == CategoryType.income ? 'income' : 'expense';

      final response = await _client
          .from('transactions')
          .select('''
            amount,
            categories (
              name
            )
          ''')
          .eq('user_id', userId)
          .eq('type', typeString)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      Map<String, double> categoryStats = {};

      for (var item in response) {
        final categoryName = item['categories']?['name'] ?? 'Kategori Yok';
        final amount = (item['amount'] as num).toDouble();
        
        categoryStats[categoryName] = (categoryStats[categoryName] ?? 0) + amount;
      }

      return categoryStats;
    } catch (e) {
      print('getCategoryStatsForMonth error: $e');
      return {};
    }
  }

  Future<void> ensureUserHasCategories() async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) return;

      print('DEBUG ensureUserHasCategories - Checking for user: $userId');

      final existingCategories = await _client
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if ((existingCategories as List).isEmpty) {
        print('DEBUG ensureUserHasCategories - No categories found, creating defaults');
        await createDefaultCategories();
      } else {
        print('DEBUG ensureUserHasCategories - User already has categories');
      }
    } catch (e) {
      print('ensureUserHasCategories error: $e');
    }
  }
  
}