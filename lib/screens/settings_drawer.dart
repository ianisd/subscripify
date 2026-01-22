import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Subscripfy", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Manage your money", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          // Dark Mode Switch
          ValueListenableBuilder(
            valueListenable: settingsBox.listenable(),
            builder: (context, Box box, _) {
              bool isDark = box.get('isDark', defaultValue: false);
              return SwitchListTile(
                title: const Text("Dark Mode"),
                secondary: const Icon(Icons.dark_mode),
                value: isDark,
                onChanged: (val) => box.put('isDark', val),
              );
            },
          ),

          const Divider(),

          // Currency Selector
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text("Currency Symbol"),
            trailing: DropdownButton<String>(
              value: settingsBox.get('currency', defaultValue: '\$'),
              underline: Container(), // Hides the line
              items: ['\$', '€', '£', 'R', '¥', '₹'].map((String val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) {
                settingsBox.put('currency', val);
              },
            ),
          ),

          // ... After the currency selector ...

          const Divider(),

          // PREMIUM STATUS TILE
          ValueListenableBuilder(
            valueListenable: settingsBox.listenable(),
            builder: (context, Box box, _) {
              bool isPremium = box.get('isPremium', defaultValue: false);

              if (isPremium) {
                return const ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text("Premium Active", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  subtitle: Text("Thank you for your support!"),
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.indigo),
                  title: const Text("Unlock Premium"),
                  subtitle: const Text("Remove ads & Unlimited subs"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(10)),
                    child: const Text("PRO", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
    onTap: () {
    showDialog(
    context: context,
    builder: (ctx) {
    final codeController = TextEditingController();
    return AlertDialog(
    title: const Text("Unlock Premium"),
    content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    const Text("Support the developer! Donate \$3 to remove ads and unlock unlimited subscriptions."),
    const SizedBox(height: 15),
    const Text("Already donated? Enter your code below:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    TextField(
    controller: codeController,
    decoration: const InputDecoration(
    hintText: "Enter Code (e.g. PRO2026)",
    border: OutlineInputBorder(),
    ),
    ),
    ],
    ),
    actions: [
    // BUTTON 1: DONATE (Opens Browser)
    TextButton(
    onPressed: () async {
    // Replace this with your actual PayPal/Ko-fi link
    final Uri url = Uri.parse('https://ko-fi.com/iandlamini');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    // Handle error if link doesn't open
    }
    },
    child: const Text("Donate \$3")
    ),

    // BUTTON 2: UNLOCK (Checks Code)
    ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
    onPressed: () {
    // CHECK THE CODE
    if (codeController.text.trim().toUpperCase() == "PRO3000") {
    box.put('isPremium', true); // SAVE TO DB
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome to Premium!")));
    } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Code. Please donate to get one.")));
    }
    },
    child: const Text("Unlock")
    ),
    ],
    );
    }
    );
    },
                );
              }
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Reset All Data", style: TextStyle(color: Colors.red)),
              onTap: () async {
                // PRO MODE: Clear all pending notifications
                await NotificationService.cancelAll();

                await Hive.box('settings').clear();
                await Hive.box<Subscription>('subscriptions').clear();

                if (context.mounted) Navigator.pop(context);
              },
          )
        ],
      ),
    );
  }
}