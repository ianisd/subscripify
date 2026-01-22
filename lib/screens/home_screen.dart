import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/subscription.dart';
import 'add_subscription_screen.dart';
import 'settings_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    final settingsBox = Hive.box('settings');
    bool isPremium = settingsBox.get('isPremium', defaultValue: false);

    if (!isPremium) {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-4023310784068443/3017923187', // Test ID
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isAdLoaded = true),
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      )..load();
    }
  }

  double _calculateMonthlyTotal(List<Subscription> subs) {
    double total = 0;
    for (var sub in subs) {
      if (sub.period == 'Monthly') total += sub.amount;
      if (sub.period == 'Yearly') total += sub.amount / 12;
      if (sub.period == 'Weekly') total += sub.amount * 4.33;
    }
    return total;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Entertainment': return Icons.movie;
      case 'Utilities': return Icons.lightbulb;
      case 'Work': return Icons.work;
      case 'Health': return Icons.fitness_center;
      case 'Personal': return Icons.person;
      default: return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subBox = Hive.box<Subscription>('subscriptions');
    final settingsBox = Hive.box('settings');

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Subscriptions", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      drawer: const SettingsDrawer(),
      body: ValueListenableBuilder(
        valueListenable: subBox.listenable(),
        builder: (context, Box<Subscription> box, _) {
          final subs = box.values.toList().cast<Subscription>();
          final double monthlyTotal = _calculateMonthlyTotal(subs);

          return ValueListenableBuilder(
            valueListenable: settingsBox.listenable(),
            builder: (context, Box settings, _) {
              String currency = settings.get('currency', defaultValue: '\$');
              bool isPremium = settings.get('isPremium', defaultValue: false);

              return Column(
                children: [
                  // --- TOTAL CARD ---
                  if (subs.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          const Text("Average Monthly Spend", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 5),
                          Text(
                            "$currency${monthlyTotal.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // --- LIST OF SUBS ---
                  Expanded(
                    child: subs.isEmpty
                        ? const Center(child: Text("Tap + to add your first bill."))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: subs.length,
                      itemBuilder: (context, index) {
                        final sub = subs[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Icon(_getCategoryIcon(sub.category), color: Colors.indigo),
                            ),
                            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("${sub.period} • ${DateFormat('MMM d').format(sub.nextBillDate)}"),
                            trailing: Text(
                              "$currency${sub.amount.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => AddSubscriptionScreen(subscription: sub))),
                          ),
                        );
                      },
                    ),
                  ),

                  // --- AD BANNER (Hidden if Premium) ---
                  if (_isAdLoaded && !isPremium)
                    SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // --- FREEMIUM LOGIC: LIMIT TO 5 SUBS ---
          bool isPremium = settingsBox.get('isPremium', defaultValue: false);
          if (!isPremium && subBox.length >= 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Free limit reached! Upgrade to add more.")),
            );
            return; // Stop here
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSubscriptionScreen()));
        },
        label: const Text("Add New"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}