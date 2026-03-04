import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../utils/font_size_listener.dart';
import '../providers/language_provider.dart';
import '../l10n/app_translations.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _editing = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {

    try {

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        return;
      }

      final data = await SupabaseService().getUserProfile(userId);

      setState(() {

        _userData = data;

        nameController.text = data?['name'] ?? "";
        phoneController.text = data?['phone_number'] ?? "";

        _loading = false;

      });

    } catch (e) {

      setState(() {
        _loading = false;
      });

    }

  }

  Future<void> updateProfile() async {

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    await SupabaseService().updateUserProfile(userId, {
      'name': nameController.text,
      'phone_number': phoneController.text
    });

    setState(() {
      _editing = false;
      _userData!['name'] = nameController.text;
      _userData!['phone_number'] = phoneController.text;
    });

  }

  Future<void> logout() async {

    await SupabaseService().logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen())
    );

  }

  @override
  Widget build(BuildContext context) {

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {

        return FontSizeListener(
          child: const SizedBox(),
          builder: (context, fontSize) {

            return Scaffold(

              appBar: AppBar(
                title: Text(
                    AppTranslations.translate(context, 'my_profile'),
                    style: TextStyle(fontSize: fontSize + 4)
                ),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),

              body: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : buildBody(fontSize),

            );

          },
        );

      },
    );

  }

  Widget buildBody(double fontSize) {

    if (_userData == null) {
      return const Center(child: Text("User data not found"));
    }

    String name = _userData?['name'] ?? "User";

    String avatar =
    name.isNotEmpty ? name[0].toUpperCase() : "U";

    double balance = 0;

    if (_userData?['balance'] != null) {
      balance = (_userData!['balance'] as num).toDouble();
    }

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Column(

        children: [

          /// Avatar
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            name,
            style: TextStyle(
                fontSize: fontSize + 4,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          /// Balance Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const Icon(Icons.account_balance_wallet, size: 30),

                  const SizedBox(height: 10),

                  Text(
                    "Balance",
                    style: TextStyle(fontSize: fontSize),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "RM ${balance.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: fontSize + 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// Personal Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "Personal Info",
                        style: TextStyle(
                            fontSize: fontSize + 2,
                            fontWeight: FontWeight.bold),
                      ),

                      if (!_editing)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _editing = true;
                            });
                          },
                        )

                    ],
                  ),

                  const SizedBox(height: 10),

                  if (!_editing) ...[

                    buildInfo(Icons.badge,
                        "IC Number",
                        _userData?['ic_number'] ?? "N/A",
                        fontSize),

                    buildInfo(Icons.email,
                        "Email",
                        _userData?['email'] ?? "N/A",
                        fontSize),

                    buildInfo(Icons.phone,
                        "Phone",
                        _userData?['phone_number'] ?? "N/A",
                        fontSize),

                  ],

                  if (_editing) ...[

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: "Name"),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                          labelText: "Phone"),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _editing = false;
                              });
                            },
                            child: const Text("Cancel"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: updateProfile,
                            child: const Text("Save"),
                          ),
                        ),

                      ],
                    )

                  ]

                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Change Password
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const ChangePasswordScreen()));

              },
            ),
          ),

          const SizedBox(height: 20),

          /// Logout
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: logout,
            child: const Text("Logout"),
          )

        ],
      ),
    );
  }

  Widget buildInfo(
      IconData icon,
      String label,
      String value,
      double fontSize) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [

          Icon(icon),

          const SizedBox(width: 10),

          Text("$label: ",
              style: TextStyle(fontSize: fontSize)),

          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold)),
          )

        ],
      ),
    );
  }

}