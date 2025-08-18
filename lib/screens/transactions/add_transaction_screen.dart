import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme.dart';
import '../../core/supabase.dart';
import '../../controllers/home_controller.dart';
import '../../models/category.dart';
import '../../services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final HomeController homeController = Get.find();
  final TransactionService _transactionService = TransactionService();
  
  String selectedType = 'expense'; // Varsayılan değer
  DateTime selectedDate = DateTime.now();
  CategoryModel? selectedCategory;
  List<CategoryModel> categories = [];
  bool isLoadingCategories = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromParameters();
    _loadCategories();
  }

  void _initializeFromParameters() {
    final String? typeParam = Get.parameters['type'];
    if (typeParam != null && (typeParam == 'income' || typeParam == 'expense')) {
      setState(() {
        selectedType = typeParam;
      });
      print('DEBUG _initializeFromParameters - URL parametresinden tip ayarlandı: $selectedType');
    } else {
      print('DEBUG _initializeFromParameters - Varsayılan tip kullanılıyor: $selectedType');
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    setState(() => isLoadingCategories = true);
    try {
      final categoryType = selectedType == 'income' ? CategoryType.income : CategoryType.expense;
      categories = await _transactionService.getCategoriesByType(categoryType);
      
      print('DEBUG _loadCategories - Loaded ${categories.length} categories for type: $selectedType');
      
      if (categories.isNotEmpty && selectedCategory == null) {
        selectedCategory = categories.first;
        print('DEBUG _loadCategories - Auto selected category: ${selectedCategory?.name}');
      }
    } catch (e) {
      print('Kategori yükleme hatası: $e');
      if (mounted) {
        Get.snackbar(
          'Hata', 
          'Kategoriler yüklenirken hata oluştu: $e',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingCategories = false);
      }
    }
  }

  Future<void> _onTypeChanged(String newType) async {
    if (selectedType == newType) return;
    
    setState(() {
      selectedType = newType;
      selectedCategory = null; // Kategori seçimini sıfırla
    });
    
    await _loadCategories(); // Yeni tipe göre kategorileri yükle
  }

  Future<void> _saveTransaction() async {
    if (!formKey.currentState!.validate()) return;
    
    if (selectedCategory == null) {
      Get.snackbar(
        'Hata', 
        'Lütfen bir kategori seçin',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    final currentUser = SupabaseConfig.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Hata', 
        'Lütfen önce giriş yapın',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final transactionData = {
        'userId': currentUser.id,
        'categoryId': selectedCategory!.id,
        'title': titleController.text.trim(),
        'amount': double.parse(amountController.text),
        'description': descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        'type': selectedType,
        'date': selectedDate,
      };
      
      print('DEBUG _saveTransaction - Prepared data: $transactionData');
      
      await homeController.addTransaction(transactionData);
      
      if (mounted) {
        Get.back();
        Get.snackbar(
          'Başarılı', 
          'İşlem eklendi',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      print('DEBUG _saveTransaction error: $e');
      if (mounted) {
        Get.snackbar(
          'Hata', 
          'İşlem kaydedilirken hata oluştu',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('İşlem Ekle'),
        actions: [
          if (isSaving)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.appBarTheme.iconTheme?.color ?? theme.primaryColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: Text(
                'KAYDET',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Selector
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTypeChanged('expense'),
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selectedType == 'expense' 
                                  ? AppTheme.errorColor 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Gider',
                                style: TextStyle(
                                  color: selectedType == 'expense' 
                                      ? Colors.white 
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTypeChanged('income'),
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selectedType == 'income' 
                                  ? AppTheme.successColor 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Gelir',
                                style: TextStyle(
                                  color: selectedType == 'income' 
                                      ? Colors.white 
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                isLoadingCategories
                    ? Container(
                        height: 56,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[800] : Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Kategoriler yükleniyor...',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<CategoryModel>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          prefixIcon: Icon(
                            Icons.category_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                        ),
                        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem<CategoryModel>(
                            value: category,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category.icon ?? '📊',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (CategoryModel? newCategory) {
                          setState(() {
                            selectedCategory = newCategory;
                          });
                          print('DEBUG - Selected category: ${newCategory?.name}');
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Lütfen bir kategori seçin';
                          }
                          return null;
                        },
                      ),
                SizedBox(height: 16),

                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    prefixIcon: Icon(
                      Icons.monetization_on_outlined,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    suffixText: '₺',
                    suffixStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tutar gerekli';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    if (parsed == null) {
                      return 'Geçerli bir tutar giriniz';
                    }
                    if (parsed <= 0) {
                      return 'Tutar 0\'dan büyük olmalı';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: titleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    prefixIcon: Icon(
                      Icons.title_outlined,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık gerekli';
                    }
                    if (value.trim().length < 2) {
                      return 'Başlık en az 2 karakter olmalı';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                SizedBox(height: 16),

                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: theme.copyWith(
                            dialogBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined, 
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tarih',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right, 
                          color: isDark ? Colors.white54 : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Kaydediliyor...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'İşlemi Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}