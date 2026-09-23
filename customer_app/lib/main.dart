import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeeshoCustomerApp());
}

class MeeshoCustomerApp extends StatelessWidget {
  const MeeshoCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-Shirt Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF9F2089),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9F2089)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const MeeshoHomeScreen(),
    const Center(child: Text("Categories Page")),
    const Center(child: Text("My Orders")),
    const Center(child: Text("User Profile & Support")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9F2089),
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}

class MeeshoHomeScreen extends StatelessWidget {
  const MeeshoHomeScreen({super.key});

  final List<Map<String, dynamic>> products = const [
    {
      "id": "TSH01",
      "title": "Tokyo Revengers Oversized Anime Tee",
      "price": 499,
      "original_price": 999,
      "discount": "50% OFF",
      "rating": "4.3 ★",
      "reviews": "1.4k",
      "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500"
    },
    {
      "id": "TSH02",
      "title": "Minimalist Streetwear Heavy Cotton Black",
      "price": 399,
      "original_price": 899,
      "discount": "55% OFF",
      "rating": "4.5 ★",
      "reviews": "3.8k",
      "image": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=500"
    },
    {
      "id": "TSH03",
      "title": "Vintage Acid Wash Oversized Tee",
      "price": 549,
      "original_price": 1199,
      "discount": "54% OFF",
      "rating": "4.2 ★",
      "reviews": "920",
      "image": "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=500"
    },
    {
      "id": "TSH04",
      "title": "Japanese Samurai Graphic Print Tee",
      "price": 449,
      "original_price": 899,
      "discount": "50% OFF",
      "rating": "4.4 ★",
      "reviews": "2.1k",
      "image": "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=500"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              SizedBox(width: 10),
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Text("Search T-Shirts, Anime, Sizes...", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          // Offer Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFBE7F5),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Color(0xFF9F2089), size: 20),
                SizedBox(width: 8),
                Text("Free Delivery + Cash On Delivery Available", style: TextStyle(color: Color(0xFF9F2089), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // Categories Horizontal Bar
          Container(
            height: 48,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                _chip("All T-Shirts", true),
                _chip("Oversized", false),
                _chip("Anime Prints", false),
                _chip("Plain Solids", false),
                _chip("Acid Wash", false),
                _chip("Hoodies", false),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product Grid (Meesho 2-Column Style)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return _buildProductCard(context, p);
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF9F2089) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF9F2089) : Colors.grey.shade300),
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(p['image'], width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("₹${p['price']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(width: 6),
                      Text("₹${p['original_price']}", style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(p['discount'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
                    child: Text(p['rating'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Text("Free Delivery", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = "M";

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(p['title'], style: const TextStyle(fontSize: 15))),
      body: ListView(
        children: [
          Image.network(p['image'], height: 380, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text("₹${p['price']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(width: 10),
                    Text("₹${p['original_price']}", style: const TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(p['discount'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const Divider(height: 30),
                const Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: ["S", "M", "L", "XL", "XXL"].map((size) {
                    final isSel = selectedSize == size;
                    return GestureDetector(
                      onTap: () => setState(() => selectedSize = size),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? const Color(0xFF9F2089) : Colors.white,
                          border: Border.all(color: isSel ? const Color(0xFF9F2089) : Colors.grey.shade400),
                        ),
                        child: Center(
                          child: Text(size, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 30),
                const Text("Product Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text("• Fabric: 100% Pure Combed Cotton (240 GSM)\n• Print: High Definition DTF Long Lasting\n• Fit: Oversized Drop Shoulder Streetwear\n• Wash Care: Cold machine wash"),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9F2089),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MeeshoCheckoutScreen(product: p, size: selectedSize)),
          ),
          child: const Text("BUY NOW", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class MeeshoCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String size;
  const MeeshoCheckoutScreen({super.key, required this.product, required this.size});

  @override
  State<MeeshoCheckoutScreen> createState() => _MeeshoCheckoutScreenState();
}

class _MeeshoCheckoutScreenState extends State<MeeshoCheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  final _utr = TextEditingController();
  File? _proofImage;
  bool _loading = false;

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  void _completeOrder() {
    if (_name.text.isEmpty || _phone.text.isEmpty || _address.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kripya sabhi details bharein!")));
      return;
    }
    setState(() => _loading = true);

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _loading = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Order Placed Successfully! 🎉"),
          content: const Text("Aapka T-shirt order record ho gaya hai. Payment verification ke baad tracking number SMS & WhatsApp par mil jayega."),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Home"),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Summary & Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Image.network(widget.product['image'], width: 70, height: 70, fit: BoxFit.cover),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Size: ${widget.size} | Qty: 1", style: const TextStyle(color: Colors.grey)),
                          Text("₹${widget.product['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9F2089))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Customer Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _address, decoration: const InputDecoration(labelText: "House No, Street, Area", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _pincode, decoration: const InputDecoration(labelText: "6-Digit Pincode", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const Divider(height: 35),
            const Text("Pay via UPI (QR Code)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Image.network("https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=upi://pay?pa=store@upi%26pn=TShirtStore%26am=${widget.product['price']}"),
                  const SizedBox(height: 8),
                  const Text("Scan QR with GPay / PhonePe / Paytm", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextField(controller: _utr, decoration: const InputDecoration(labelText: "12-Digit UTR / Transaction ID", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(_proofImage == null ? "Upload Payment Screenshot" : "Screenshot Selected ✅"),
              onPressed: _pickProof,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9F2089)),
                onPressed: _loading ? null : _completeOrder,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM ORDER", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
