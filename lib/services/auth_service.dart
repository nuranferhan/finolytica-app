import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import '../core/supabase.dart';
import '../models/user.dart';
import '../controllers/home_controller.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('E-mail veya şifre hatalı');
      }
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.message));
    } catch (e) {
      throw Exception('Giriş yapılamadı: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {
          'full_name': fullName, 
        },
      );
      
      if (response.user != null) {
        await _createUserProfileWithContext(response.user!.id, email, fullName);
        
        print('DEBUG: User created with full_name: $fullName');
        print('DEBUG: User metadata: ${response.user!.userMetadata}');
      } else {
        throw Exception('Hesap oluşturulamadı');
      }
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.message));
    } catch (e) {
      throw Exception('Kayıt işlemi başarısız: $e');
    }
  }

  Future<void> _createUserProfileWithContext(String userId, String email, String fullName) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName, 
        'currency': 'TRY',
      });
      
      print('DEBUG: Profile created with full_name: $fullName');
    } catch (e) {
      print('Profile creation error: $e');
 
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:3000', 
        );
      } else {
        await _client.auth.signInWithOAuth(OAuthProvider.google);
      }
    } on AuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.message));
    } catch (e) {
      throw Exception('Google girişi başarısız: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        print('DEBUG: Retrieved user profile: ${response['full_name']}');
        return UserModel.fromMap(response);
      }
      return null;
    } catch (e) {
      print('getUserProfile error: $e');
      return null;
    }
  }

  Future<void> createUserProfile(String userId, String email, String fullName) async {
    try {
      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'full_name': fullName, 
        'currency': 'TRY',
      });
      
      print('DEBUG: Profile upserted with full_name: $fullName');
    } catch (e) {
      print('createUserProfile error: $e');
      
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _client
          .from('users')
          .update(user.toMap())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Profil güncellenemedi: $e');
    }
  }

  Future<void> signOut() async {
    try {
      try {
        final homeController = Get.find<HomeController>();
        homeController.clearAndReloadData();
      } catch (e) {
        print('Controller not found during signOut: $e');
      }
      
      await _client.auth.signOut();
      
      print('DEBUG: User signed out successfully');
    } catch (e) {
      print('SignOut error: $e');
    }
  }

  String _getAuthErrorMessage(String message) {
    switch (message.toLowerCase()) {
      case 'invalid login credentials':
        return 'E-mail veya şifre hatalı';
      case 'email not confirmed':
        return 'E-mail adresiniz doğrulanmamış';
      case 'user already registered':
        return 'Bu e-mail adresi zaten kayıtlı';
      case 'password should be at least 6 characters':
        return 'Şifre en az 6 karakter olmalı';
      case 'signup is disabled':
        return 'Kayıt işlemi şu anda kapalı';
      case 'new row violates row-level security policy':
        return 'Güvenlik politikası hatası - lütfen tekrar deneyin';
      default:
        return message;
    }
  }
}