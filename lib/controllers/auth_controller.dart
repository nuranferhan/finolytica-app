import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();
  
  var user = Rx<User?>(null);
  var isLoading = false.obs;
  var userProfile = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    user.value = SupabaseConfig.currentUser;
    _listenToAuthChanges();
    if (user.value != null) {
      getUserProfile();
    }
  }

  void _listenToAuthChanges() {
    SupabaseConfig.authStateChanges.listen((data) {
      user.value = data.session?.user;
      if (user.value != null) {
        getUserProfile();
      } else {
        userProfile.value = null;
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signInWithEmail(email, password);
      
      await _transactionService.ensureUserHasCategories();
      
      Get.snackbar(
        'Başarılı', 
        'Giriş yapıldı',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      Get.offAllNamed('/home');
      
    } catch (e) {
      Get.snackbar(
        'Hata', 
        e.toString(),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    try {
      isLoading.value = true;
      await _authService.signUpWithEmail(email, password, fullName);
      
      Get.snackbar(
        'Başarılı', 
        'Hesap oluşturuldu. Lütfen giriş yapın.',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: Duration(seconds: 3),
      );
      
      Get.back();
      
    } catch (e) {
      Get.snackbar(
        'Hata', 
        e.toString(),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
      
      await _transactionService.ensureUserHasCategories();
      
      Get.offAllNamed('/home');
      
    } catch (e) {
      Get.snackbar(
        'Hata', 
        e.toString(),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserProfile() async {
    if (user.value != null) {
      try {
        userProfile.value = await _authService.getUserProfile(user.value!.id);
        
        if (userProfile.value == null) {
          await _authService.createUserProfile(
            user.value!.id, 
            user.value!.email!, 
            user.value!.userMetadata?['full_name'] ?? 'Kullanıcı'
          );
          userProfile.value = await _authService.getUserProfile(user.value!.id);
        }
        
        await _transactionService.ensureUserHasCategories();
        
        
      } catch (e) {
        print('Profile fetch error: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      user.value = null;
      userProfile.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Hata', 'Çıkış yapılamadı');
    }
  }
}