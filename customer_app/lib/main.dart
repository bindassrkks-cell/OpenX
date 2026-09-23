import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<Map<String, dynamic>> products = const [
    {
      "id": "TSH01",
      "title": "Tokyo Anime Oversized Streetwear Graphic Tee",
      "price": 499,
      "original_price": 999,
      "discount": "50% OFF",
      "rating": "4.3 ★",
      "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500"
    },
    {
      "id": "TSH02",
      "title": "Vintage Acid Wash 240 GSM Pure Cotton Tee",
      "price": 399,
      "original_price": 899,
      "discount": "55% OFF",
      "rating": "4.5 ★",
      "image": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=500"
    },
    {
      "id": "TSH03",
      "title": "Minimalist Japanese Aesthetic Black Tee",
      "price": 449,
      "original_price": 899,
      "discount": "50% OFF",
      "rating": "4.2 ★",
      "image": "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=500"
    },
    {
      "id": "TSH04",
      "title": "Drop Shoulder Retro Street Typography Tee",
      "price": 549,
      "original_price": 1099,
      "discount": "50% OFF",
      "rating": "4.4 ★",
      "image": "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=500"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text("Search T-Shirts, Anime, Sizes...", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFFFBE7F5),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Color(0xFF9F2089), size: 18),
                SizedBox(width: 8),
                Text("Free Delivery + Cash On Delivery Available", style: TextStyle(color: Color(0xFF9F2089), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
              return GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            Text(p['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text("₹${p['price']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Text("₹${p['original_price']}", style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                const SizedBox(width: 4),
                                Text(p['discount'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(10)),
                              child: Text(p['rating'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 2),
                            const Text("Free Delivery", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9F2089),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
        ],
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
          Image.network(p['image'], height: 350, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₹${p['price']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                const Divider(height: 30),
                const Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: ["S", "M", "L", "XL", "XXL"].map((s) {
                    final isSel = selectedSize == s;
                    return GestureDetector(
                      onTap: () => setState(() => selectedSize = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF9F2089) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? const Color(0xFF9F2089) : Colors.grey.shade400),
                        ),
                        child: Center(child: Text(s, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9F2089),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(product: p, size: selectedSize))),
          child: const Text("BUY NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String size;
  const CheckoutScreen({super.key, required this.product, required this.size});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _utr = TextEditingController();
  File? _proof;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Total: ₹${widget.product['price']} (Size: ${widget.size})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          TextField(controller: _address, decoration: const InputDecoration(labelText: "Delivery Address", border: OutlineInputBorder())),
          const Divider(height: 30),
          Center(child: Image.network("https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=upi://pay?pa=store@upi%26pn=Store%26am=${widget.product['price']}&cu=INR")),
          const SizedBox(height: 10),
          TextField(controller: _utr, decoration: const InputDecoration(labelText: "12-Digit UTR Number", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9F2089), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Order Placed! 🎉"),
                  content: const Text("Aapka order successfully place ho gaya hai!"),
                  actions: [TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text("OK"))],
                ),
              );
            },
            child: const Text("CONFIRM ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
