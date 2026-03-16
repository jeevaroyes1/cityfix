import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  final List<Map<String, dynamic>> welfareCenters = const [
    {
      "name": "Hastha Old Age Home",
      "short_desc": "Care and shelter for the elderly.",
      "description": "Hastha Old Age Home has been a sanctuary for the elderly since 1998. We provide medical care, recreational activities, and a loving community for seniors who have no one else to turn to.",
      "founded": "1998",
      "members": "120+ Residents",
      "location": "North Avenue, City",
      "image": "assets/images/placeholder_old_age.png",
      "id": "hastha"
    },
    {
      "name": "City Orphanage",
      "short_desc": "A loving home for children.",
      "description": "City Orphanage is dedicated to providing a nurturing environment for orphaned and vulnerable children. We ensure education, healthcare, and emotional support to help them build a bright future.",
      "founded": "2005",
      "members": "200+ Children",
      "location": "Green Valley, City",
      "image": "assets/images/placeholder_orphanage.png",
      "id": "orphanage"
    },
    {
      "name": "Green Earth Initiative",
      "short_desc": "Planting trees for a greener city.",
      "description": "The Green Earth Initiative works tirelessly to expand the city's green cover. We organize community tree planting drives, maintain public parks, and educate citizens about environmental conservation.",
      "founded": "2010",
      "members": "5000+ Volunteers",
      "location": "Eco Park, City",
      "image": "assets/images/placeholder_green.png",
      "id": "green"
    },
    {
      "name": "Paws & Care Shelter",
      "short_desc": "Rescue and rehab for animals.",
      "description": "Paws & Care Shelter is a safe haven for injured and abandoned animals. Our team rescues strays, provides veterinary treatment, and facilitates adoption to loving forever homes.",
      "founded": "2015",
      "members": "350+ Animals",
      "location": "West End, City",
      "image": "assets/images/placeholder_paws.png",
      "id": "paws"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Donate to Welfare", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: welfareCenters.length,
        itemBuilder: (context, index) {
          final center = welfareCenters[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationDetailsPage(center: center),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A6F4A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            center['name']![0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A6F4A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              center['name']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              center['short_desc']!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DonationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> center;

  const DonationDetailsPage({super.key, required this.center});

  @override
  State<DonationDetailsPage> createState() => _DonationDetailsPageState();
}

class _DonationDetailsPageState extends State<DonationDetailsPage> {
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    _amountController.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Thank You!"),
          ],
        ),
        content: Text(
          "Payment Successful!\n\nID: ${response.paymentId}\n\nYour donation to '${widget.center['name']}' will make a difference.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close page
            },
            child: const Text("Close", style: TextStyle(color: Color(0xFF5A6F4A))),
          ),
        ],
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment Failed: ${response.message}"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  void _processPayment() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount")),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    var options = {
      'key': 'rzp_test_RP6aD2gNdAuoRE',
      'amount': (amount * 100).toInt(),
      'name': 'City Welfare Donation',
      'description': 'Donation to ${widget.center['name']}',
      'prefill': {
        'contact': '9876543210',
        'email': 'donor@cityfix.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.center['name'], style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              color: const Color(0xFF5A6F4A).withOpacity(0.1),
              child: Center(
                child: Hero(
                  tag: widget.center['name'],
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF5A6F4A),
                    child: Text(
                      widget.center['name'][0],
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoBadge(Icons.calendar_today, "Est. ${widget.center['founded']}"),
                      _buildInfoBadge(Icons.people, widget.center['members']),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "About Us",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.center['description'],
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.center['location'],
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    "Make a Donation",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Amount (₹)",
                      hintText: "Enter amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_rupee),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A6F4A),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text("Proceed to Pay", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF5A6F4A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5A6F4A)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF5A6F4A), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
