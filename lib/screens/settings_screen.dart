import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String _appVersion = '';
  String _buildNumber = '';

  // Notification settings
  bool _pushNotificationsEnabled = true;
  bool _breakingNewsAlerts = true;
  bool _dailyDigestNotifications = true;
  bool _sportScoreNotifications = false;
  bool _weatherAlerts = true;
  bool _localNewsAlerts = true;

  // Content preferences
  bool _showLocalNews = true;
  bool _showPolitics = true;
  bool _showSports = true;
  bool _showClassifieds = true;
  bool _showObituaries = true;
  bool _showWeather = true;
  String _locationPreference = 'Current Location';

  // Display settings
  String _textSize = 'Medium';
  bool _darkModeEnabled = false;
  bool _reducedMotion = false;
  bool _highContrastMode = false;

  // Privacy settings
  bool _locationPermission = true;
  bool _analyticsEnabled = true;
  bool _adPersonalization = false;
  bool _allowCookies = true;
  DateTime _lastDataSync = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load app version
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Notification settings
        _pushNotificationsEnabled =
            prefs.getBool('pushNotificationsEnabled') ?? true;
        _breakingNewsAlerts = prefs.getBool('breakingNewsAlerts') ?? true;
        _dailyDigestNotifications =
            prefs.getBool('dailyDigestNotifications') ?? true;
        _sportScoreNotifications =
            prefs.getBool('sportScoreNotifications') ?? false;
        _weatherAlerts = prefs.getBool('weatherAlerts') ?? true;
        _localNewsAlerts = prefs.getBool('localNewsAlerts') ?? true;

        // Content preferences
        _showLocalNews = prefs.getBool('showLocalNews') ?? true;
        _showPolitics = prefs.getBool('showPolitics') ?? true;
        _showSports = prefs.getBool('showSports') ?? true;
        _showClassifieds = prefs.getBool('showClassifieds') ?? true;
        _showObituaries = prefs.getBool('showObituaries') ?? true;
        _showWeather = prefs.getBool('showWeather') ?? true;
        _locationPreference =
            prefs.getString('locationPreference') ?? 'Current Location';

        // Display settings
        _textSize = prefs.getString('textSize') ?? 'Medium';
        _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
        _reducedMotion = prefs.getBool('reducedMotion') ?? false;
        _highContrastMode = prefs.getBool('highContrastMode') ?? false;

        // Privacy settings
        _locationPermission = prefs.getBool('locationPermission') ?? true;
        _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;
        _adPersonalization = prefs.getBool('adPersonalization') ?? false;
        _allowCookies = prefs.getBool('allowCookies') ?? true;

        // Last data sync time
        final lastSyncTimeMillis = prefs.getInt('lastDataSync');
        if (lastSyncTimeMillis != null) {
          _lastDataSync = DateTime.fromMillisecondsSinceEpoch(
            lastSyncTimeMillis,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Notification settings
      await prefs.setBool(
        'pushNotificationsEnabled',
        _pushNotificationsEnabled,
      );
      await prefs.setBool('breakingNewsAlerts', _breakingNewsAlerts);
      await prefs.setBool(
        'dailyDigestNotifications',
        _dailyDigestNotifications,
      );
      await prefs.setBool('sportScoreNotifications', _sportScoreNotifications);
      await prefs.setBool('weatherAlerts', _weatherAlerts);
      await prefs.setBool('localNewsAlerts', _localNewsAlerts);

      // Content preferences
      await prefs.setBool('showLocalNews', _showLocalNews);
      await prefs.setBool('showPolitics', _showPolitics);
      await prefs.setBool('showSports', _showSports);
      await prefs.setBool('showClassifieds', _showClassifieds);
      await prefs.setBool('showObituaries', _showObituaries);
      await prefs.setBool('showWeather', _showWeather);
      await prefs.setString('locationPreference', _locationPreference);

      // Display settings
      await prefs.setString('textSize', _textSize);
      await prefs.setBool('darkModeEnabled', _darkModeEnabled);
      await prefs.setBool('reducedMotion', _reducedMotion);
      await prefs.setBool('highContrastMode', _highContrastMode);

      // Privacy settings
      await prefs.setBool('locationPermission', _locationPermission);
      await prefs.setBool('analyticsEnabled', _analyticsEnabled);
      await prefs.setBool('adPersonalization', _adPersonalization);
      await prefs.setBool('allowCookies', _allowCookies);

      // Update sync time
      final now = DateTime.now();
      await prefs.setInt('lastDataSync', now.millisecondsSinceEpoch);
      setState(() => _lastDataSync = now);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF2d2c31),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFd2982a),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account section
                    _buildSectionHeader('Account'),
                    _buildAccountSettings(),

                    const SizedBox(height: 24),

                    // Notifications section
                    _buildSectionHeader('Notifications'),
                    _buildNotificationSettings(),

                    const SizedBox(height: 24),

                    // Content preferences section
                    _buildSectionHeader('Content Preferences'),
                    _buildContentSettings(),

                    const SizedBox(height: 24),

                    // Display settings section
                    _buildSectionHeader('Display & Accessibility'),
                    _buildDisplaySettings(),

                    const SizedBox(height: 24),

                    // Privacy & data section
                    _buildSectionHeader('Privacy & Data'),
                    _buildPrivacySettings(),

                    const SizedBox(height: 24),

                    // Storage & data section
                    _buildSectionHeader('Storage & Data'),
                    _buildStorageSettings(),

                    const SizedBox(height: 24),

                    // About section
                    _buildSectionHeader('About'),
                    _buildAboutSettings(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFd2982a),
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAccountSettings() {
    final user = _auth.currentUser;

    return Column(
      children: [
        if (user != null)
          ListTile(
            title: const Text('Email'),
            subtitle: Text(user.email ?? 'Not available'),
            leading: const Icon(Icons.email, color: Color(0xFFd2982a)),
            contentPadding: EdgeInsets.zero,
          ),

        ListTile(
          title: const Text('Manage Subscriptions'),
          leading: const Icon(Icons.subscriptions, color: Color(0xFFd2982a)),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            // Navigate to subscription management screen or show dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription management coming soon'),
              ),
            );
          },
        ),

        ListTile(
          title: const Text('Change Password'),
          leading: const Icon(Icons.lock_outline, color: Color(0xFFd2982a)),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showChangePasswordDialog();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Enable or disable all notifications'),
          value: _pushNotificationsEnabled,
          onChanged: (value) {
            setState(() => _pushNotificationsEnabled = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        if (_pushNotificationsEnabled) ...[
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Breaking News'),
            subtitle: const Text('Get alerts for important breaking news'),
            value: _breakingNewsAlerts,
            onChanged: (value) {
              setState(() => _breakingNewsAlerts = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Daily Digest'),
            subtitle: const Text('Receive a daily summary of top news'),
            value: _dailyDigestNotifications,
            onChanged: (value) {
              setState(() => _dailyDigestNotifications = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Sports Scores'),
            subtitle: const Text('Get local sports score updates'),
            value: _sportScoreNotifications,
            onChanged: (value) {
              setState(() => _sportScoreNotifications = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Weather Alerts'),
            subtitle: const Text('Receive severe weather warnings'),
            value: _weatherAlerts,
            onChanged: (value) {
              setState(() => _weatherAlerts = value);
            },
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Local News'),
            subtitle: const Text('Get alerts for important local stories'),
            value: _localNewsAlerts,
            onChanged: (value) {
              setState(() => _localNewsAlerts = value);
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildContentSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Local News'),
          value: _showLocalNews,
          onChanged: (value) {
            setState(() => _showLocalNews = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Politics'),
          value: _showPolitics,
          onChanged: (value) {
            setState(() => _showPolitics = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Sports'),
          value: _showSports,
          onChanged: (value) {
            setState(() => _showSports = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Classifieds'),
          value: _showClassifieds,
          onChanged: (value) {
            setState(() => _showClassifieds = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Obituaries'),
          value: _showObituaries,
          onChanged: (value) {
            setState(() => _showObituaries = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Weather'),
          value: _showWeather,
          onChanged: (value) {
            setState(() => _showWeather = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 8),

        ListTile(
          title: const Text('Location Preference'),
          subtitle: Text(_locationPreference),
          contentPadding: EdgeInsets.zero,
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () {
            _showLocationPreferenceDialog();
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      children: [
        ListTile(
          title: const Text('Text Size'),
          subtitle: Text(_textSize),
          trailing: const Icon(Icons.arrow_drop_down),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showTextSizeDialog();
          },
        ),

        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark colors for the app interface'),
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() => _darkModeEnabled = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Reduced Motion'),
          subtitle: const Text('Minimize animations throughout the app'),
          value: _reducedMotion,
          onChanged: (value) {
            setState(() => _reducedMotion = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('High Contrast Mode'),
          subtitle: const Text('Increase color contrast for better visibility'),
          value: _highContrastMode,
          onChanged: (value) {
            setState(() => _highContrastMode = value);
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Location Services'),
          subtitle: const Text(
            'Allow access to your location for weather and local news',
          ),
          value: _locationPermission,
          onChanged: (value) {
            setState(() => _locationPermission = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Analytics'),
          subtitle: const Text('Allow us to collect anonymous usage data'),
          value: _analyticsEnabled,
          onChanged: (value) {
            setState(() => _analyticsEnabled = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Ad Personalization'),
          subtitle: const Text(
            'Allow personalized ads based on your interests',
          ),
          value: _adPersonalization,
          onChanged: (value) {
            setState(() => _adPersonalization = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        SwitchListTile(
          title: const Text('Cookies'),
          subtitle: const Text(
            'Allow the app to store cookies for better performance',
          ),
          value: _allowCookies,
          onChanged: (value) {
            setState(() => _allowCookies = value);
          },
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 8),

        ListTile(
          title: const Text('Privacy Policy'),
          leading: const Icon(
            Icons.privacy_tip_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('https://www.neusenews.com/privacy-policy');
          },
        ),

        ListTile(
          title: const Text('Terms of Service'),
          leading: const Icon(
            Icons.description_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('https://www.neusenews.com/terms-of-service');
          },
        ),

        ListTile(
          title: const Text('Data Collection & Usage'),
          leading: const Icon(
            Icons.data_usage_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('https://www.neusenews.com/data-collection');
          },
        ),

        ListTile(
          title: const Text('Request My Data'),
          leading: const Icon(
            Icons.download_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showRequestDataDialog();
          },
        ),

        ListTile(
          title: const Text('Delete My Data'),
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showDeleteDataDialog();
          },
        ),
      ],
    );
  }

  Widget _buildStorageSettings() {
    return Column(
      children: [
        ListTile(
          title: const Text('Clear Cache'),
          subtitle: const Text('Free up space by clearing cached content'),
          leading: const Icon(
            Icons.cleaning_services_outlined,
            color: Color(0xFFd2982a),
          ),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showClearCacheDialog();
          },
        ),

        ListTile(
          title: const Text('Download Quality'),
          subtitle: const Text('Media download quality for offline viewing'),
          leading: const Icon(
            Icons.high_quality_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Text('Standard'),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _showDownloadQualityDialog();
          },
        ),

        ListTile(
          title: const Text('Last Data Sync'),
          subtitle: Text(
            DateFormat('MMM d, yyyy h:mm a').format(_lastDataSync),
          ),
          leading: const Icon(Icons.sync, color: Color(0xFFd2982a)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAboutSettings() {
    return Column(
      children: [
        ListTile(
          title: const Text('Version'),
          subtitle: Text('$_appVersion (Build $_buildNumber)'),
          leading: const Icon(Icons.info_outline, color: Color(0xFFd2982a)),
          contentPadding: EdgeInsets.zero,
        ),

        ListTile(
          title: const Text('Rate the App'),
          leading: const Icon(Icons.star_outline, color: Color(0xFFd2982a)),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            // Launch app store page
            _launchURL(
              'https://play.google.com/store/apps/details?id=com.wordnerd.neusenews',
            );
          },
        ),

        ListTile(
          title: const Text('Send Feedback'),
          leading: const Icon(
            Icons.feedback_outlined,
            color: Color(0xFFd2982a),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('mailto:feedback@neusenews.com?subject=App%20Feedback');
          },
        ),

        ListTile(
          title: const Text('Help Center'),
          leading: const Icon(Icons.help_outline, color: Color(0xFFd2982a)),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('https://www.neusenews.com/help');
          },
        ),

        ListTile(
          title: const Text('About Neuse News'),
          leading: const Icon(Icons.business, color: Color(0xFFd2982a)),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            _launchURL('https://www.neusenews.com/about');
          },
        ),

        const SizedBox(height: 16),

        const Center(
          child: Text(
            '© 2025 Neuse News. All Rights Reserved.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Dialog methods
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Re-authenticate user before changing password
                    final user = _auth.currentUser;
                    if (user != null && user.email != null) {
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPasswordController.text,
                      );
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPasswordController.text);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: Color(0xFFd2982a)),
                ),
              ),
            ],
          ),
    );
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Text Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextSizeOption('Small'),
                _buildTextSizeOption('Medium'),
                _buildTextSizeOption('Large'),
                _buildTextSizeOption('Extra Large'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextSizeOption(String size) {
    return RadioListTile<String>(
      title: Text(size),
      value: size,
      groupValue: _textSize,
      onChanged: (value) {
        setState(() => _textSize = value!);
        Navigator.pop(context);
      },
      activeColor: const Color(0xFFd2982a),
    );
  }

  void _showLocationPreferenceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Preference'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLocationOption('Current Location'),
                _buildLocationOption('Kinston, NC'),
                _buildLocationOption('New Bern, NC'),
                _buildLocationOption('Goldsboro, NC'),
                _buildLocationOption('Greenville, NC'),
                ListTile(
                  title: const Text('Enter Zip Code...'),
                  onTap: () {
                    Navigator.pop(context);
                    _showZipCodeDialog();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildLocationOption(String location) {
    return RadioListTile<String>(
      title: Text(location),
      value: location,
      groupValue: _locationPreference,
      onChanged: (value) {
        setState(() => _locationPreference = value!);
        Navigator.pop(context);
      },
      activeColor: const Color(0xFFd2982a),
    );
  }

  void _showZipCodeDialog() {
    final zipController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Zip Code'),
            content: TextField(
              controller: zipController,
              decoration: const InputDecoration(
                labelText: 'Zip Code',
                hintText: 'e.g. 28577',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final zip = zipController.text;
                  if (zip.length == 5) {
                    setState(() => _locationPreference = 'Zip: $zip');
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid 5-digit zip code'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Color(0xFFd2982a)),
                ),
              ),
            ],
          ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'This will clear all cached images and data. The app might take longer to load content until the cache is rebuilt. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Mock cache clearing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully')),
                  );
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showDownloadQualityDialog() {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Download Quality'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: const Text('Low (Data Saver)'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: const Text('Standard'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: const Text('High'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: const Text('WiFi Only (High)'),
              ),
            ],
          ),
    );
  }

  void _showRequestDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Request Your Data'),
            content: const Text(
              'You can request a copy of all your personal data we have stored. '
              'We will prepare your data and send it to your registered email address '
              'within 7 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Mock data request
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data request submitted. You will receive an email when your data is ready.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Request',
                  style: TextStyle(color: Color(0xFFd2982a)),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Your Data'),
            content: const Text(
              'This will permanently delete all your personal data from our servers. '
              'This action cannot be undone and may affect your user experience. '
              'Your account will remain active, but all personalization data will be removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show confirmation dialog
                  _showDeleteDataConfirmationDialog();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDataConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Data Deletion'),
            content: const Text(
              'Are you absolutely sure you want to delete all your personal data? '
              'This process cannot be reversed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Mock data deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your data deletion request has been submitted. '
                        'All personal data will be removed within 30 days.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Yes, Delete Everything',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }
}
