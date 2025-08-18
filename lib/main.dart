import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; 
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:device_preview/device_preview.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'core/theme.dart';
import 'core/config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/investment_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/investments/investments_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env dosyası başarıyla yüklendi");
    print("✅ Supabase URL: ${AppConfig.supabaseUrl.isNotEmpty ? 'Ayarlandı' : 'Eksik'}");
    print("✅ Alpha Vantage API: ${AppConfig.alphaVantageApiKey.isNotEmpty ? 'Ayarlandı' : 'Eksik'}");
    
  } catch (e) {
    print("❌ .env dosyası yüklenemedi: $e");
    print("⚠️  Lütfen .env dosyasının proje kök dizininde olduğundan emin olun");
  }
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 800), // iPhone benzeri boyut
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: Size(350, 600), // Minimum boyut
      maximumSize: Size(450, 900), // Maximum boyut
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    print("✅ Supabase başarıyla başlatıldı");
  } catch (e) {
    print("❌ Supabase başlatma hatası: $e");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    DevicePreview(
      enabled: !Platform.isAndroid && !Platform.isIOS, // Sadece desktop'ta aktif
      defaultDevice: Devices.ios.iPhoneSE, // Varsayılan cihaz
      devices: [
        // Popüler telefon boyutları
        Devices.ios.iPhoneSE,
        Devices.ios.iPhone12,
        Devices.ios.iPhone13ProMax,
        Devices.android.samsungGalaxyS20,
        Devices.android.samsungGalaxyNote20,
      ],
      builder: (context) => const FinolyticaApp(),
    ),
  );
}

class FinolyticaApp extends StatelessWidget {
  const FinolyticaApp({super.key});

@override
Widget build(BuildContext context) {
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(HomeController()); 
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!Get.isRegistered<InvestmentController>()) {
      try {
        Get.put(InvestmentController());
        print('✅ InvestmentController initialized after HomeController');
      } catch (e) {
        print('❌ Error initializing InvestmentController: $e');
        
        Future.delayed(Duration(milliseconds: 500), () {
          try {
            Get.put(InvestmentController());
            print('✅ InvestmentController initialized with delay');
          } catch (e) {
            print('❌ Critical error initializing InvestmentController: $e');
          }
        });
      }
    }
  });

  return GetMaterialApp(
    title: 'Finolytica',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: Get.find<ThemeController>().themeMode.value,
    
    useInheritedMediaQuery: true,
    locale: DevicePreview.locale(context),
    builder: DevicePreview.appBuilder,
    
    home: const AuthCheck(),
    getPages: [
      GetPage(name: '/login', page: () => LoginScreen()),
      GetPage(name: '/home', page: () => HomeScreen()),
      GetPage(name: '/add_transaction', page: () => AddTransactionScreen()),
      GetPage(name: '/analytics', page: () => AnalyticsScreen()),
      GetPage(name: '/investments', page: () => InvestmentsScreen()),
    ],
  );
}
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        if (authController.user.value != null) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}