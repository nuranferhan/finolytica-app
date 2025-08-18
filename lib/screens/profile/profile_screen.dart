import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  final AuthController authController = Get.find();
  final ThemeController themeController = Get.find();

  ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingsSection(),
                  SizedBox(height: 24),
                  _buildAccountSection(),
                  SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Çıkış Yap'),
        content: Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 16),
                Obx(() => Text(
                  authController.userProfile.value?.fullName ?? 'Kullanıcı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                SizedBox(height: 4),
                Obx(() => Text(
                  authController.user.value?.email ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayarlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Karanlık Tema',
                subtitle: 'Görünümü karanlık yap',
                trailing: Obx(() => Switch(
                  value: themeController.themeMode.value == ThemeMode.dark,
                  onChanged: (value) => themeController.toggleTheme(),
                  activeColor: AppTheme.primaryColor,
                )),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Bildirim ayarlarını yönet',
                onTap: () => _showNotificationSettings(),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              _buildSettingsItem(
                icon: Icons.language_outlined,
                title: 'Dil',
                subtitle: 'Türkçe',
                onTap: () => _showLanguageSettings(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hesap',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.security_outlined,
                title: 'Güvenlik',
                subtitle: 'Şifre ve güvenlik ayarları',
                onTap: () => _showSecuritySettings(),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik',
                subtitle: 'Gizlilik politikası ve ayarları',
                onTap: () {
                  
                },
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Yardım ve Destek',
                subtitle: 'SSS ve destek talebi',
                onTap: () => _showHelpAndSupport(),
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'Hakkında',
                subtitle: 'Uygulama bilgileri',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null 
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor.withOpacity(0.1),
            AppTheme.errorColor.withOpacity(0.05),
          ],
        ),
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: Icon(Icons.logout, color: AppTheme.errorColor),
        label: Text(
          'Çıkış Yap',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Bildirim Ayarları',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildNotificationOption('Uygulama Bildirimleri', true),
              _buildNotificationOption('E-posta Bildirimleri', false),
              _buildNotificationOption('SMS Bildirimleri', false),
              _buildNotificationOption('Özel Teklifler', true),
              _buildNotificationOption('Güvenlik Uyarıları', true),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('İptal'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('Başarılı', 'Bildirim ayarları kaydedildi',
                          backgroundColor: Colors.green, colorText: Colors.white);
                    },
                    child: Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationOption(String title, bool initialValue) {
    RxBool isEnabled = initialValue.obs;
    return Obx(() => SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 14)),
      value: isEnabled.value,
      onChanged: (value) => isEnabled.value = value,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    ));
  }

  void _showLanguageSettings() {
    List<Map<String, String>> languages = [
      {'code': 'tr', 'name': 'Türkçe'},
      {'code': 'en', 'name': 'English'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'es', 'name': 'Español'},
    ];
    
    RxString selectedLanguage = 'tr'.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.language_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Dil Seçimi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ...languages.map((language) => 
                Obx(() => RadioListTile<String>(
                  title: Text(language['name']!),
                  value: language['code']!,
                  groupValue: selectedLanguage.value,
                  onChanged: (value) => selectedLanguage.value = value!,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                )),
              ).toList(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('İptal'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('Başarılı', 'Dil ayarı kaydedildi',
                          backgroundColor: Colors.green, colorText: Colors.white);
                    },
                    child: Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecuritySettings() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Güvenlik Ayarları',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildSecurityOption(
                icon: Icons.lock_outline,
                title: 'Şifre Değiştir',
                subtitle: 'Hesap şifrenizi güncelleyin',
                onTap: () => _showChangePasswordDialog(),
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildSecurityOption(
                icon: Icons.fingerprint,
                title: 'Biyometrik Giriş',
                subtitle: 'Parmak izi/Yüz tanıma ile giriş',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildSecurityOption(
                icon: Icons.security,
                title: 'İki Faktörlü Doğrulama',
                subtitle: 'Ekstra güvenlik katmanı ekleyin',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildSecurityOption(
                icon: Icons.devices,
                title: 'Aktif Oturumlar',
                subtitle: 'Diğer cihazlardaki oturumları yönetin',
                onTap: () => _showActiveSessionsDialog(),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Kapat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Şifre Değiştir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('İptal'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Şifre değiştirme işlemi
                      Get.back();
                      Get.snackbar('Başarılı', 'Şifreniz başarıyla değiştirildi',
                          backgroundColor: Colors.green, colorText: Colors.white);
                    },
                    child: Text('Değiştir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveSessionsDialog() {
    List<Map<String, String>> sessions = [
      {'device': 'iPhone 12', 'location': 'İstanbul, TR', 'time': '2 dakika önce', 'current': 'true'},
      {'device': 'Windows PC', 'location': 'İstanbul, TR', 'time': '1 saat önce', 'current': 'false'},
      {'device': 'Android Phone', 'location': 'Ankara, TR', 'time': '2 gün önce', 'current': 'false'},
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktif Oturumlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          session['current'] == 'true' ? Icons.smartphone : Icons.devices,
                          color: session['current'] == 'true' ? Colors.green : Colors.grey,
                        ),
                        title: Text(session['device']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session['location']!),
                            Text(session['time']!, style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: session['current'] == 'true' 
                            ? Chip(label: Text('Mevcut', style: TextStyle(fontSize: 10)))
                            : IconButton(
                                icon: Icon(Icons.logout, color: Colors.red),
                                onPressed: () {
                                  // Oturumu sonlandır
                                  Get.snackbar('Başarılı', 'Oturum sonlandırıldı',
                                      backgroundColor: Colors.green, colorText: Colors.white);
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Kapat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpAndSupport() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Yardım ve Destek',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildHelpOption(
                icon: Icons.quiz_outlined,
                title: 'Sık Sorulan Sorular',
                subtitle: 'En çok merak edilen konular',
                onTap: () => _showFAQDialog(),
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildHelpOption(
                icon: Icons.chat_outlined,
                title: 'Canlı Destek',
                subtitle: 'Anlık destek alın',
                onTap: () {
                  Get.back();
                  Get.snackbar('Bilgi', 'Canlı destek bağlantısı kuruluyor...',
                      backgroundColor: Colors.blue, colorText: Colors.white);
                },
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildHelpOption(
                icon: Icons.email_outlined,
                title: 'E-posta Desteği',
                subtitle: 'Sizin için buradayız',
                onTap: () {
                  Get.back();
                  Get.snackbar('Bilgi', 'E-posta uygulaması açılıyor...',
                      backgroundColor: Colors.blue, colorText: Colors.white);
                },
              ),
              Divider(color: Colors.grey.withOpacity(0.1)),
              _buildHelpOption(
                icon: Icons.bug_report_outlined,
                title: 'Hata Bildir',
                subtitle: 'Karşılaştığınız sorunları bildirin',
                onTap: () => _showBugReportDialog(),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Kapat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showFAQDialog() {
    List<Map<String, String>> faqs = [
      {'question': 'Şifremi unuttum, ne yapmalıyım?', 'answer': 'Giriş ekranında "Şifremi Unuttum" linkine tıklayarak yeni şifre oluşturabilirsiniz.'},
      {'question': 'Hesabımı nasıl silebilirim?', 'answer': 'Hesap silme işlemi için destek ekibimizle iletişime geçmeniz gerekmektedir.'},
      {'question': 'Bildirimler neden gelmiyor?', 'answer': 'Cihaz ayarlarınızdan uygulama bildirimlerinin açık olduğunu kontrol edin.'},
      {'question': 'Verilerim güvende mi?', 'answer': 'Tüm verileriniz şifreli olarak saklanır ve güvenlik protokollerimiz sürekli güncellenir.'},
    ];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sık Sorulan Sorular',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return ExpansionTile(
                      title: Text(faq['question']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(faq['answer']!, style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Kapat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBugReportDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hata Bildir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Hata Başlığı',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Hata Açıklaması',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('İptal'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('Başarılı', 'Hata raporunuz gönderildi',
                          backgroundColor: Colors.green, colorText: Colors.white);
                    },
                    child: Text('Gönder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showAboutDialog() {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Uygulama Hakkında',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
                children: [
                  TextSpan(text: 'Uygulama Adı: Finolytica\nSürüm: 1.4.9\n\n'),
                  TextSpan(
                    text: '© 2025 Nuran Ferhan\nTüm hakları saklıdır',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey.withOpacity(0.1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Bilgi', 'Gizlilik politikası gösteriliyor...',
                        backgroundColor: Colors.blue, colorText: Colors.white);
                  },
                  child: Text('Gizlilik Politikası', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Bilgi', 'Kullanım şartları gösteriliyor...',
                        backgroundColor: Colors.blue, colorText: Colors.white);
                  },
                  child: Text('Kullanım Şartları', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}