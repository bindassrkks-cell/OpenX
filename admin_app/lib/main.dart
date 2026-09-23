import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Control Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        useMaterial3: true,
      ),
      home: const AdminHome(),
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final String botToken = "7663258345:AAFWanmBg6FD_DQTz2q9tkvHX-8M9vAWkUA";
  Timer? timer;
  int lastUpdateId = 0;
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startPolling() {
    timer = Timer.periodic(const Duration(seconds: 4), (t) async {
      try {
        final url = Uri.parse("https://api.telegram.org/bot$botToken/getUpdates?offset=${lastUpdateId + 1}&timeout=2");
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final updates = data['result'] as List;
          for (var u in updates) {
            lastUpdateId = u['update_id'];
            if (u.containsKey('message')) {
              final chatId = u['message']['chat']['id'];
              final text = u['message']['text'] ?? "";
              _respond(chatId, text);
            }
          }
        }
      } catch (_) {}
    });
  }

  void _respond(dynamic chatId, String text) async {
    String reply = "Store Admin is Active. Type /orders to see list.";
    if (text == "/orders") reply = "Orders: #ORD_101 (Rs. 499) - Tokyo Anime Tee";
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");
    await http.post(url, body: {"chat_id": chatId.toString(), "text": reply});
    setState(() => logs.insert(0, "Chat: $chatId sent '$text'"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin & Telegram Poller", style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            child: const Text("Polling Active", style: TextStyle(color: Colors.white, fontSize: 11)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Order #ORD_101", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Item: Tokyo Anime Tee (L) - Rs. 499"),
                  const Text("UTR: 498129038102", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Approved!"))),
                        child: const Text("Approve"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shiprocket Courier Dispatched!"))),
                        child: const Text("Dispatch"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Telegram Bot Live Logs", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 160,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: logs.isEmpty
                ? const Center(child: Text("Listening for Telegram commands...", style: TextStyle(color: Colors.white60, fontSize: 12)))
                : ListView.builder(itemCount: logs.length, itemBuilder: (c, i) => Text(logs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 12))),
          )
        ],
      ),
    );
  }
}
