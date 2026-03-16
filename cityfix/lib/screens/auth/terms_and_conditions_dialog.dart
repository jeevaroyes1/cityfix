import 'package:flutter/material.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  final Function(bool) onAgree;

  const TermsAndConditionsDialog({
    super.key,
    required this.onAgree,
  });

  @override
  State<TermsAndConditionsDialog> createState() => _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  bool _isAgreed = false;
  bool _isScrollable = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScroll();
    });
  }

  void _checkScroll() {
    if (_scrollController.hasClients) {
      final isScrollable = _scrollController.position.maxScrollExtent > 0;
      if (isScrollable != _isScrollable) {
        setState(() {
          _isScrollable = isScrollable;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing without agreement
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A6F4A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Terms and Conditions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Please read and accept the following terms and conditions to continue using CityFix:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSection(
                        "1. User Responsibilities",
                        "You are responsible for providing accurate and truthful information when submitting reports. False or misleading reports may result in account suspension.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "2. Report Content",
                        "All reports must be genuine and related to actual issues in your area. You must not submit reports that are fraudulent, defamatory, or violate any laws.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "3. Privacy and Data",
                        "By using this app, you agree to the collection and use of your location data, images, and personal information as necessary to process your reports and improve our services.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "4. Image Guidelines",
                        "Images submitted must be relevant to the reported issue. Do not upload inappropriate, offensive, or copyrighted content without permission.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "5. Service Availability",
                        "We strive to provide reliable service but do not guarantee that all reported issues will be resolved within a specific timeframe. Response times may vary.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "6. Account Security",
                        "You are responsible for maintaining the confidentiality of your account credentials. Notify us immediately of any unauthorized access.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "7. Prohibited Activities",
                        "You may not use this service to harass others, submit spam, or engage in any activity that disrupts the platform's operation.",
                      ),
                      const SizedBox(height: 16),

                      _buildSection(
                        "8. Changes to Terms",
                        "We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.",
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "By checking the box below, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.",
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Checkbox and Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          onChanged: (value) {
                            setState(() {
                              _isAgreed = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF5A6F4A),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAgreed = !_isAgreed;
                              });
                            },
                            child: const Text(
                              "I have read and agree to the Terms and Conditions",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A6F4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isAgreed
                            ? () {
                                widget.onAgree(true);
                                Navigator.of(context).pop();
                              }
                            : null,
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A6F4A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
