import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kFirebaseDbUrl = "https://meesho-tshirt-store-default-rtdb.firebaseio.com";
const String kBotToken = "7663258345:AAFWanmBg6FD_DQTz2q9tkvHX-8M9vAWkUA";

void main() {
  runApp(const MeeshoAdminDarkApp());
}

class MeeshoAdminDarkApp extends StatelessWidget {
  const MeeshoAdminDarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Admin & Poller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        cardColor: const Color(0xFF1C1C22),
        primaryColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Timer? pollTimer;
  Timer? firebaseTimer;
  int lastUpdateId = 0;
  List<String> logs = [];
  List<Map<String, dynamic>> orders = [];
  bool pollingActive = true;

  @override
  void initState() {
    super.initState();
    startTelegramPolling();
    fetchFirebaseOrders();
    // Auto-refresh orders every 5 seconds
    firebaseTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchFirebaseOrders());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    firebaseTimer?.cancel();
    super.dispose();
  }

  // Realtime Telegram Polling Engine
  void startTelegramPolling() {
    pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final url = Uri.parse("https://api.telegram.org/bot$kBotToken/getUpdates?offset=${lastUpdateId + 1}&timeout=2");
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final updates = data['result'] as List;
          for (var u in updates) {
            lastUpdateId = u['update_id'];
            if (u.containsKey('message')) {
              final chatId = u['message']['chat']['id'];
              final text = u['message']['text'] ?? "";
              _respondTelegram(chatId, text);
            }
          }
        }
      } catch (_) {}
    });
  }

  void _respondTelegram(dynamic chatId, String text) async {
    String reply = "👑 *Boss! Store Admin Active.*\n\nCommands:\n• `/orders` - View pending orders\n• `/stats` - Total sales summary";
    if (text == "/orders") {
      reply = "📦 *Recent Orders count:* ${orders.length} orders recorded in Firebase.";
    }

    await http.post(
      Uri.parse("https://api.telegram.org/bot$kBotToken/sendMessage"),
      body: {"chat_id": chatId.toString(), "text": reply, "parse_mode": "Markdown"},
    );
    setState(() => logs.insert(0, "Bot received '$text' from$chatId"));
  }

  // Fetch Orders from Firebase RTDB
  Future<void> fetchFirebaseOrders() async {
    try {
      final res = await http.get(Uri.parse("$kFirebaseDbUrl/orders.json"));
      if (res.statusCode == 200 && res.body != "null") {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<Map<String, dynamic>> loaded = [];
        data.forEach((k, v) => loaded.add(Map<String, dynamic>.from(v)));
        setState(() => orders = loaded.reversed.toList());
      }
    } catch (_) {}
  }

  // Update Order Status in Firebase
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await http.patch(
        Uri.parse("$kFirebaseDbUrl/orders/$orderId.json"),
        body: jsonEncode({"status": newStatus}),
      );
      fetchFirebaseOrders();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order #$orderId marked as$newStatus!")));
    } catch (_) {}
  }

  // Dialog to Add Live Product into Firebase RTDB
  void showAddProductDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    String category = "Anime";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text("Add New T-Shirt Live", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title (e.g. Dragon Ball Tee)", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: priceCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Price (e.g. 499)", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number),
              TextField(controller: imgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Image URL", labelStyle: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2E93)),
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newP = {
                  "title": titleCtrl.text.trim(),
                  "price": double.tryParse(priceCtrl.text) ?? 499,
                  "original_price": 999,
                  "discount": "50% OFF",
                  "rating": "4.8 ★",
                  "category": category,
                  "image": imgCtrl.text.trim().isEmpty ? "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500" : imgCtrl.text.trim()
                };
                await http.post(Uri.parse("$kFirebaseDbUrl/products.json"), body: jsonEncode(newP));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("T-Shirt added live to Customer App!")));
              }
            },
            child: const Text("Add Product", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141A),
        title: const Text("Admin & Telegram Poller", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(12)),
            child: const Text("Polling Active", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF2E93),
        onPressed: showAddProductDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add T-Shirt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Stats
          Row(
            children: [
              _statBox("Total Orders", "${orders.length}", const Color(0xFF00E676)),
              const SizedBox(width: 10),
              _statBox("Bot Polling", "Connected", const Color(0xFFFF2E93)),
            ],
          ),
          const SizedBox(height: 18),
          const Text("Live Firebase Orders", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          orders.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text("Firebase me koi order nahi hai.", style: TextStyle(color: Colors.white54))),
                )
              : Column(
                  children: orders.map((o) {
                    final isPending = o['status'] == "PAYMENT_PENDING";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF272733))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Order #${o['id']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("₹${o['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676), fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Customer: ${o['customer_name']} (${o['customer_phone']})", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("Item: ${o['item']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text("UTR: ${o['utr']}", style: const TextStyle(color: Color(0xFFFF2E93), fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Status: ${o['status']}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (isPending)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                                  onPressed: () => updateOrderStatus(o['id'], "CONFIRMED"),
                                  child: const Text("Approve", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => updateOrderStatus(o['id'], "SHIPPED (AWB: SR92019)"),
                                child: const Text("Shiprocket Dispatch", style: TextStyle(color: Colors.white70)),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 18),
          const Text("Telegram Bot Live Polling Logs", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 140,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E2E38))),
            child: logs.isEmpty
                ? const Center(child: Text("Listening for Telegram commands (/orders, /stats)...", style: TextStyle(color: Colors.white38, fontSize: 12)))
                : ListView.builder(itemCount: logs.length, itemBuilder: (ctx, i) => Text(logs[i], style: const TextStyle(color: Color(0xFF00E676), fontSize: 12))),
          )
        ],
      ),
    );
  }

  Widget _statBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
