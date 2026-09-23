import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://YOUR_SUPABASE_URL.supabase.co',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  } catch (_) {}
  runApp(const MaterialApp(
    home: CustomerCatalogScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class CustomerCatalogScreen extends StatelessWidget {
  const CustomerCatalogScreen({super.key});

  final List<Map<String, dynamic>> items = const [
    {
      "id": "t1",
      "title": "Anime Oversized Graphic T-Shirt",
      "price": 599,
      "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500"
    },
    {
      "id": "t2",
      "title": "Urban Streetwear Black Tee",
      "price": 499,
      "image": "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=500"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("T-Shirt Store"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(item['image'], height: 220, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("₹${item['price']}", style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CheckoutScreen(product: item)),
                        ),
                        child: const Text("Buy Now", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _utr = TextEditingController();
  File? _screenshot;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final res = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (res != null) setState(() => _screenshot = File(res.path));
  }

  Future<void> _submitOrder() async {
    if (_name.text.isEmpty || _phone.text.isEmpty || _address.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sabhi details fill karein!")));
      return;
    }
    setState(() => _submitting = true);

    try {
      final orderId = "ORD_${DateTime.now().millisecondsSinceEpoch}";
      await Supabase.instance.client.from('orders').insert({
        'id': orderId,
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        'shipping_address': _address.text.trim(),
        'total_amount': widget.product['price'],
        'payment_method': 'UPI_MANUAL',
        'payment_status': 'PENDING_VERIFICATION',
        'utr_number': _utr.text.trim(),
        'status': 'PLACED',
        'items': [widget.product]
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Order Placed! 📦"),
            content: const Text("Aapka order receive ho gaya hai. Payment verification ke baad dispatch kiya jayega."),
            actions: [TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout & UPI Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _address, decoration: const InputDecoration(labelText: "Full Delivery Address", border: OutlineInputBorder()), maxLines: 2),
            const Divider(height: 30),
            Text("Pay ₹${widget.product['price']} via QR", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Image.network("https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=upi://pay?pa=store@upi%26pn=TShirtStore%26am=${widget.product['price']}"),
            const SizedBox(height: 12),
            TextField(controller: _utr, decoration: const InputDecoration(labelText: "12-Digit UTR / Transaction ID", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(_screenshot == null ? "Upload Payment Screenshot" : "Screenshot Attached ✅"),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: _submitting ? null : _submitOrder,
                child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm & Place Order", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
