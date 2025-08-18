import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class SupabaseConfig {
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseKey => AppConfig.supabaseAnonKey;
  
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}