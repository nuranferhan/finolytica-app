import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../core/theme.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionCard({
    Key? key, 
    required this.transaction,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.type == 'income';
    
    final categoryColor = transaction.category?.color != null 
        ? Color(int.parse(transaction.category!.color!)) 
        : (isIncome ? AppTheme.successColor : AppTheme.errorColor);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isDark ? 8 : 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Kategori ikonu ve rengi
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: transaction.category?.icon != null 
                  ? Center(
                      child: Text(
                        transaction.category!.icon!,
                        style: TextStyle(fontSize: 24),
                      ),
                    )
                  : Icon(
                      isIncome ? Icons.add_circle : Icons.remove_circle,
                      color: categoryColor,
                      size: 24,
                    ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  // Kategori adını göster
                  if (transaction.category?.name != null)
                    Text(
                      transaction.category!.name,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (transaction.description?.isNotEmpty == true) ...[
                    SizedBox(height: 2),
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy', 'tr_TR').format(transaction.date),
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}₺${NumberFormat('#,##0.00', 'tr_TR').format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
                if (onDelete != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline, 
                          color: isDark ? Colors.grey[500] : Colors.grey[400], 
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}