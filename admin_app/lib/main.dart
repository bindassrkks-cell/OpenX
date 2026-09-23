import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        useMaterial3: true,
      ),
      home: const AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String botToken = "7663258345:AAFWanmBg6FD_DQTz2q9tkvHX-8M9vAWkUA";
  bool isPolling = false;
  int lastUpdateId = 0;
  Timer? pollTimer;
  List<String> botLogs = [];

  final List<Map<String, dynamic>> orders = [
    {
      "id": "ORD_101",
      "customer": "Mohammad Nisarul",
      "item": "Anime Oversized Tee (L)",
      "amount": 499,
      "status": "PAYMENT_PENDING",
      "utr": "428901239841",
    },
    {
      "id": "ORD_102",
      "customer": "Rahul Sharma",
      "item": "Acid Wash Black Tee (XL)",
      "amount": 549,
      "status": "CONFIRMED",
      "utr": "981273981273",
    }
  ];

  @override
  void initState() {
    super.initState();
    startTelegramPolling();
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  // In-app Telegram Bot Polling Engine
  void startTelegramPolling() {
    setState(() => isPolling = true);
    pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final url = Uri.parse("https://api.telegram.org/bot$botToken/getUpdates?offset=${lastUpdateId + 1}&timeout=3");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final updates = data['result'] as List;

          for (var update in updates) {
            lastUpdateId = update['update_id'];
            if (update.containsKey('message')) {
              final chatId = update['message']['chat']['id'];
              final text = update['message']['text'] ?? "";

              _handleBotMessage(chatId, text);
            }
          }
        }
      } catch (e) {
        // Connection silently resumes next cycle
      }
    });
  }

  void _handleBotMessage(dynamic chatId, String text) async {
    String reply = "Welcome Boss! Admin Panel is active.\nType /orders to see pending orders.";
    if (text == "/orders") {
      reply = "📦 *Pending Orders:* \nORD_101 - ₹499 (Mohammad Nisarul) UTR: 428901239841";
    }

    final sendUrl = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");
    await http.post(sendUrl, body: {
      "chat_id": chatId.toString(),
      "text": reply,
      "parse_mode": "Markdown",
    });

    setState(() {
      botLogs.insert(0, "Bot query: '$text' from chat: $chatId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Control & Bot Manager", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(12)),
            child: const Text("Bot Polling: Active", style: TextStyle(color: Colors.white, fontSize: 11)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _metricCard("Total Revenue", "₹14,890", Colors.green),
              const SizedBox(width: 12),
              _metricCard("Pending Orders", "1 New", Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Recent Orders & Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...orders.map((o) => Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order #${o['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("₹${o['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                  Text("Customer: ${o['customer']}"),
                  Text("Product: ${o['item']}"),
                  Text("UTR: ${o['utr']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const Divider(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order #${o['id']} Approved!")));
                        },
                        child: const Text("Approve Payment"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: const Text("Shiprocket Dispatch"),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Courier Pickup Scheduled!")));
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          )),
          const SizedBox(height: 20),
          const Text("Telegram Bot Live Polling Logs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 140,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
            child: botLogs.isEmpty
                ? const Center(child: Text("Listening for Telegram commands (/orders, /start)...", style: TextStyle(color: Colors.white54, fontSize: 12)))
                : ListView.builder(
                    itemCount: botLogs.length,
                    itemBuilder: (ctx, i) => Text(botLogs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ),
          )
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
