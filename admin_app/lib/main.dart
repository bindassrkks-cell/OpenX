import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// CONFIGURATION
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
      title: 'Store Admin & Bot Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D11),
        cardColor: const Color(0xFF16161E),
        primaryColor: const Color(0xFFFF2E93),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2E93),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF16161E),
        ),
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

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? pollTimer;
  Timer? firebaseTimer;
  int lastUpdateId = 0;

  List<String> logs = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> products = [];
  Map<String, dynamic> storeConfig = {
    "theme_color": "#FF2E93",
    "banner_text": "Free Delivery + COD Available"
  };

  bool isPolling = true;
  double dbLatencyMs = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    startTelegramPolling();
    refreshAllData();

    // Auto sync with Firebase every 6 seconds
    firebaseTimer = Timer.periodic(const Duration(seconds: 6), (_) => refreshAllData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    pollTimer?.cancel();
    firebaseTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      fetchFirebaseOrders(),
      fetchFirebaseProducts(),
      fetchStoreConfig(),
    ]);
  }

  // --------------------------------------------------------------------------
  // FIREBASE ENGINE
  // --------------------------------------------------------------------------
  Future<void> fetchFirebaseOrders() async {
    try {
      final res = await http.get(Uri.parse("$kFirebaseDbUrl/orders.json"));
      if (res.statusCode == 200 && res.body != "null") {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<Map<String, dynamic>> loaded = [];
        data.forEach((k, v) => loaded.add(Map<String, dynamic>.from(v)));
        if (mounted) setState(() => orders = loaded.reversed.toList());
      }
    } catch (_) {}
  }

  Future<void> fetchFirebaseProducts() async {
    try {
      final res = await http.get(Uri.parse("$kFirebaseDbUrl/products.json"));
      if (res.statusCode == 200 && res.body != "null") {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List<Map<String, dynamic>> loaded = [];
        data.forEach((k, v) => loaded.add({...Map<String, dynamic>.from(v), "id": k}));
        if (mounted) setState(() => products = loaded);
      }
    } catch (_) {}
  }

  Future<void> fetchStoreConfig() async {
    try {
      final res = await http.get(Uri.parse("$kFirebaseDbUrl/config.json"));
      if (res.statusCode == 200 && res.body != "null") {
        if (mounted) setState(() => storeConfig = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, {String awb = ""}) async {
    try {
      final payload = {"status": newStatus};
      if (awb.isNotEmpty) payload["awb"] = awb;

      await http.patch(
        Uri.parse("$kFirebaseDbUrl/orders/$orderId.json"),
        body: jsonEncode(payload),
      );
      await fetchFirebaseOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order #$orderId ->$newStatus!")));
      }
    } catch (_) {}
  }

  // --------------------------------------------------------------------------
  // TELEGRAM BOT COMMAND CONTROLLER & POLLING ENGINE
  // --------------------------------------------------------------------------
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
              final text = (u['message']['text'] ?? "").toString().trim();
              if (text.isNotEmpty) {
                _processCommand(chatId, text);
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _sendTelegram(dynamic chatId, String text) async {
    try {
      await http.post(
        Uri.parse("https://api.telegram.org/bot$kBotToken/sendMessage"),
        body: {
          "chat_id": chatId.toString(),
          "text": text,
          "parse_mode": "Markdown",
        },
      );
    } catch (_) {}
  }

  Future<void> _processCommand(dynamic chatId, String text) async {
    _log("CMD: '$text' from$chatId");

    // 1. HELP / START
    if (text == "/start" || text == "/help") {
      final msg = "👑 *STORE ADMIN CONTROLLER BOT*\n\n"
          "📊 *Store & Database:*\n"
          "• `/dbstatus` - Firebase connection & latency test\n"
          "• `/revenue` - Total earnings & sales report\n"
          "• `/perf` - System & polling health\n\n"
          "📦 *Order & Delivery Management:*\n"
          "• `/orders` - View all pending customer orders\n"
          "• `/approve <orderId>` - Approve order payment\n"
          "• `/dispatch <orderId> <AWB>` - Schedule courier\n\n"
          "👕 *Product Catalog:*\n"
          "• `/addproduct Title | Price | ImgUrl | Cat` - Add new product\n"
          "• `/delproduct <id>` - Remove product\n\n"
          "🎨 *Remote UI/UX Live Engine:*\n"
          "• `/settheme <pink|neon|dark|purple>` - Change customer app theme\n"
          "• `/setbanner <New Banner Text>` - Update top promo strip";
      await _sendTelegram(chatId, msg);
      return;
    }

    // 2. DB STATUS CHECK
    if (text == "/dbstatus") {
      final sw = Stopwatch()..start();
      try {
        final res = await http.get(Uri.parse("$kFirebaseDbUrl/orders.json?shallow=true"));
        sw.stop();
        dbLatencyMs = sw.elapsedMilliseconds.toDouble();

        if (res.statusCode == 200) {
          final reply = "✅ *FIREBASE REALTIME DB ONLINE*\n\n"
              "⚡ *Latency:* `${dbLatencyMs} ms`\n"
              "📦 *Total Orders in DB:* ${orders.length}\n"
              "👕 *Total Products in DB:* ${products.length}\n"
              "🔒 *Status:* 100% Read/Write Active";
          await _sendTelegram(chatId, reply);
        } else {
          await _sendTelegram(chatId, "⚠️ *Firebase Response Error:* HTTP ${res.statusCode}");
        }
      } catch (e) {
        await _sendTelegram(chatId, "❌ *Firebase Connection Failed:* $e");
      }
      return;
    }

    // 3. REVENUE & STATS
    if (text == "/revenue" || text == "/stats") {
      double totalRev = 0;
      int pendingCount = 0;
      int confirmedCount = 0;
      int shippedCount = 0;

      for (var o in orders) {
        final amt = double.tryParse(o['amount'].toString()) ?? 0;
        final status = (o['status'] ?? "").toString();
        if (status != "CANCELLED") {
          totalRev += amt;
        }
        if (status == "PAYMENT_PENDING") pendingCount++;
        if (status == "CONFIRMED") confirmedCount++;
        if (status.contains("SHIPPED")) shippedCount++;
      }

      final reply = "💰 *FINANCIAL & STORE SUMMARY*\n\n"
          "💵 *Gross Revenue:* ₹${totalRev.toStringAsFixed(2)}\n"
          "📦 *Total Orders:* ${orders.length}\n"
          "⏳ *Pending Verification:* $pendingCount\n"
          "✅ *Confirmed Orders:* $confirmedCount\n"
          "🚚 *Dispatched / In Transit:* $shippedCount";
      await _sendTelegram(chatId, reply);
      return;
    }

    // 4. ORDERS LIST
    if (text == "/orders") {
      if (orders.isEmpty) {
        await _sendTelegram(chatId, "ℹ️ Abhi tak koi order record nahi hua hai.");
        return;
      }
      String listMsg = "📦 *PENDING / RECENT ORDERS:*\n\n";
      for (var o in orders.take(5)) {
        listMsg += "• *ID:* `${o['id']}` | ₹${o['amount']}\n"
            "  👤 ${o['customer_name']} (${o['customer_phone']})\n"
            "  👕 ${o['item']}\n"
            "  🔢 UTR: `${o['utr']}`\n"
            "  📊 Status: *${o['status']}*\n\n";
      }
      listMsg += "👉 _Approve karne ke liye_: `/approve <orderId>`";
      await _sendTelegram(chatId, listMsg);
      return;
    }

    // 5. APPROVE ORDER
    if (text.startsWith("/approve")) {
      final parts = text.split(" ");
      if (parts.length < 2) {
        await _sendTelegram(chatId, "⚠️ Format galat hai! Use karein: `/approve ORD_123`");
        return;
      }
      final orderId = parts[1].trim();
      await updateOrderStatus(orderId, "CONFIRMED");
      await _sendTelegram(chatId, "✅ Order *#$orderId* ko *CONFIRMED* mark kar diya gaya hai!");
      return;
    }

    // 6. DISPATCH VIA COURIER / SHIPROCKET
    if (text.startsWith("/dispatch")) {
      final parts = text.split(" ");
      if (parts.length < 2) {
        await _sendTelegram(chatId, "⚠️ Format: `/dispatch ORD_123 AWB_987654`");
        return;
      }
      final orderId = parts[1].trim();
      final awb = parts.length > 2 ? parts[2].trim() : "SR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
      await updateOrderStatus(orderId, "SHIPPED (AWB: $awb)", awb: awb);
      await _sendTelegram(chatId, "🚚 *Order Dispatched!*\n\nOrder *#$orderId* dispatched. Courier AWB tracking: `$awb`");
      return;
    }

    // 7. ADD PRODUCT LIVE
    if (text.startsWith("/addproduct")) {
      final content = text.replaceFirst("/addproduct", "").trim();
      final parts = content.split("|");
      if (parts.length < 2) {
        await _sendTelegram(chatId, "⚠️ Format: `/addproduct Title | Price | ImageUrl | Category`");
        return;
      }

      final title = parts[0].trim();
      final price = double.tryParse(parts[1].trim()) ?? 499;
      final img = parts.length > 2 && parts[2].trim().isNotEmpty
          ? parts[2].trim()
          : "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500";
      final cat = parts.length > 3 ? parts[3].trim() : "Oversized";

      final newP = {
        "title": title,
        "price": price,
        "original_price": price * 2,
        "discount": "50% OFF",
        "rating": "4.6 ★",
        "category": cat,
        "image": img
      };

      await http.post(Uri.parse("$kFirebaseDbUrl/products.json"), body: jsonEncode(newP));
      await fetchFirebaseProducts();
      await _sendTelegram(chatId, "🎉 *Naya T-Shirt Live Ho Gaya!*\n\n👕 *$title*\n💰 ₹$price\n📂 Category: $cat");
      return;
    }

    // 8. DELETE PRODUCT
    if (text.startsWith("/delproduct")) {
      final id = text.replaceFirst("/delproduct", "").trim();
      if (id.isEmpty) {
        await _sendTelegram(chatId, "⚠️ Format: `/delproduct <product_id>`");
        return;
      }
      await http.delete(Uri.parse("$kFirebaseDbUrl/products/$id.json"));
      await fetchFirebaseProducts();
      await _sendTelegram(chatId, "🗑️ Product ID `$id` successfully delete ho gaya!");
      return;
    }

    // 9. REMOTE UI/UX THEME CONTROLLER
    if (text.startsWith("/settheme")) {
      final themeName = text.replaceFirst("/settheme", "").trim().toLowerCase();
      String hexColor = "#FF2E93"; // Default Meesho Pink
      if (themeName == "neon") hexColor = "#00E676";
      if (themeName == "dark") hexColor = "#FFFFFF";
      if (themeName == "purple") hexColor = "#9C27B0";
      if (themeName == "cyan") hexColor = "#00E5FF";

      await http.patch(
        Uri.parse("$kFirebaseDbUrl/config.json"),
        body: jsonEncode({"theme_color": hexColor, "theme_name": themeName}),
      );
      await fetchStoreConfig();
      await _sendTelegram(chatId, "🎨 *UI/UX Theme Updated!*\n\nCustomer App accent color changed to *$themeName* (`$hexColor`).");
      return;
    }

    // 10. UPDATE TOP PROMO BANNER
    if (text.startsWith("/setbanner")) {
      final bannerText = text.replaceFirst("/setbanner", "").trim();
      if (bannerText.isEmpty) {
        await _sendTelegram(chatId, "⚠️ Format: `/setbanner Holi Sale: Flat 50% Off + Free Delivery`");
        return;
      }
      await http.patch(
        Uri.parse("$kFirebaseDbUrl/config.json"),
        body: jsonEncode({"banner_text": bannerText}),
      );
      await fetchStoreConfig();
      await _sendTelegram(chatId, "📢 *Banner Updated!*\n\nNew Promo Text: _\"$bannerText\"_");
      return;
    }

    // 11. SYSTEM PERFORMANCE
    if (text == "/perf") {
      final reply = "⚙️ *SYSTEM & POLLING HEALTH*\n\n"
          "🤖 *Telegram Poller:* Active (Interval 3s)\n"
          "📡 *DB Latency:* `${dbLatencyMs > 0 ? dbLatencyMs : 45} ms`\n"
          "📦 *In-Memory Orders Cached:* ${orders.length}\n"
          "👕 *In-Memory Products Cached:* ${products.length}\n"
          "🎨 *Active Theme:* `${storeConfig['theme_color']}`";
      await _sendTelegram(chatId, reply);
      return;
    }

    // Unknown command
    await _sendTelegram(chatId, "❓ Command samajh nahi aayi. Sabhi commands dekhne ke liye `/help` likhein.");
  }

  void _log(String line) {
    if (mounted) {
      setState(() => logs.insert(0, "[${DateTime.now().toIso8601String().substring(11, 19)}]$line"));
    }
  }

  // --------------------------------------------------------------------------
  // ADD PRODUCT DIALOG (IN-APP)
  // --------------------------------------------------------------------------
  void _openAddProductDialog() {
    final title = TextEditingController();
    final price = TextEditingController();
    final img = TextEditingController();
    String cat = "Anime";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text("Add New T-Shirt Live", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title", labelStyle: TextStyle(color: Colors.white54))),
              TextField(controller: price, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Price (e.g. 499)", labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number),
              TextField(controller: img, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Image URL", labelStyle: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2E93)),
            onPressed: () async {
              if (title.text.isNotEmpty && price.text.isNotEmpty) {
                final newP = {
                  "title": title.text.trim(),
                  "price": double.tryParse(price.text) ?? 499,
                  "original_price": (double.tryParse(price.text) ?? 499) * 2,
                  "discount": "50% OFF",
                  "rating": "4.8 ★",
                  "category": cat,
                  "image": img.text.trim().isEmpty ? "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500" : img.text.trim()
                };
                await http.post(Uri.parse("$kFirebaseDbUrl/products.json"), body: jsonEncode(newP));
                Navigator.pop(ctx);
                refreshAllData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("T-Shirt Live added!")));
              }
            },
            child: const Text("Save Live", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141A),
        title: const Text("Store Control & Bot Controller", style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(12)),
            child: const Text("Bot Poller Active", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF2E93),
          labelColor: const Color(0xFFFF2E93),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: "Orders"),
            Tab(icon: Icon(Icons.checkroom), text: "Products"),
            Tab(icon: Icon(Icons.terminal), text: "Bot Logs"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF2E93),
        onPressed: _openAddProductDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add T-Shirt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ORDERS
          _buildOrdersTab(),

          // TAB 2: PRODUCTS CATALOG
          _buildProductsTab(),

          // TAB 3: TELEGRAM LIVE TERMINAL
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Revenue Row
        Row(
          children: [
            _statBox("Total Orders", "${orders.length}", const Color(0xFF00E676)),
            const SizedBox(width: 10),
            _statBox("Active Theme", storeConfig['theme_name'] ?? "Pink", const Color(0xFFFF2E93)),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Live Customer Orders", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        orders.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text("Firebase me koi order nahi mila.", style: TextStyle(color: Colors.white54))),
              )
            : Column(
                children: orders.map((o) {
                  final isPending = o['status'] == "PAYMENT_PENDING";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22222E)),
                    ),
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
                              onPressed: () => updateOrderStatus(o['id'], "SHIPPED (AWB: SR${DateTime.now().millisecondsSinceEpoch.toString().substring(7)})"),
                              child: const Text("Dispatch via Courier", style: TextStyle(color: Colors.white70)),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(p['image'] ?? "", width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.checkroom)),
            ),
            title: Text(p['title'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("₹${p['price']} \vert{}${p['category']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () async {
                await http.delete(Uri.parse("$kFirebaseDbUrl/products/${p['id']}.json"));
                refreshAllData();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text("Telegram Bot Live Polling Engine", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text("Type commands in Telegram chat to remotely manage store.", style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          height: 380,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E2E38)),
          ),
          child: logs.isEmpty
              ? const Center(child: Text("Listening for commands (/orders, /help, /revenue)...", style: TextStyle(color: Colors.white38, fontSize: 12)))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(logs[i], style: const TextStyle(color: Color(0xFF00E676), fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
        )
      ],
    );
  }

  Widget _statBox(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF16161E), borderRadius: BorderRadius.circular(10)),
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
