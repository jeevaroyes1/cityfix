import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_found_item_page.dart';

class LostAndFoundPage extends StatefulWidget {
  const LostAndFoundPage({super.key});

  @override
  State<LostAndFoundPage> createState() => _LostAndFoundPageState();
}

class _LostAndFoundPageState extends State<LostAndFoundPage> {
  String _selectedFilterOption = 'All dates';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showMyPostsOnly = false;
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Community Lost & Found",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: _userFuture,
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                }

                if (userSnapshot.hasError) {
                   return Center(child: Text("Error loading user: ${userSnapshot.error}"));
                }

                if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                  return const Center(child: Text("User data not found"));
                }

                final userPanchayat =
                    (userSnapshot.data!.data() as Map<String, dynamic>)['panchayat'];

                Query query = FirebaseFirestore.instance
                    .collection('lost_and_found_items')
                    .where('panchayat', isEqualTo: userPanchayat)
                    .orderBy('createdAt', descending: true);
                
                if (_showMyPostsOnly) {
                   query = query.where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid);
                }

                // Apply date filters only if we are not strictly just showing my posts (or combine them)
                if (_startDate != null) {
                   query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
                }
                if (_endDate != null) {
                   // Add one day to end date to include the entire day
                   final endOfDay = _endDate!.add(const Duration(days: 1));
                   query = query.where('createdAt', isLessThan: Timestamp.fromDate(endOfDay));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SelectableText(
                            "Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        return _buildItemCard(doc, context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportFoundItemPage()),
          );
        },
        backgroundColor: const Color(0xFF5A6F4A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Report Found Item",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Filters Row
              Row(
                children: [
                  _buildMyPostsButton(),
                  const SizedBox(width: 8),
                  _buildFilterButton(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Help reconnect lost items with their owners. Browse recent findings below or report a new one.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMyPostsButton() {
     return InkWell(
        onTap: () {
          setState(() {
            _showMyPostsOnly = !_showMyPostsOnly;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _showMyPostsOnly ? const Color(0xFF5A6F4A) : Colors.transparent, 
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF5A6F4A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showMyPostsOnly) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                "My Posts",
                style: TextStyle(
                  color: _showMyPostsOnly ? Colors.white : const Color(0xFF5A6F4A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
  }
  
  Widget _buildFilterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterBottomSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A6F4A), // Olive green
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedFilterOption,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF5A6F4A), // Olive green
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Filter options",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterOption("All dates"),
                  _buildFilterOption("Past week"),
                  _buildFilterOption("Past month"),
                  _buildFilterOption("Past year"),
                  _buildFilterOption("Date range", isCustom: true),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildFilterOption(String title, {bool isCustom = false}) {
    final isSelected = _selectedFilterOption == title;
    
    return InkWell(
      onTap: () {
        if (isCustom) {
          Navigator.pop(context);
          _selectDateRange();
        } else {
          _applyFilter(title);
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            if (isCustom)
               const Icon(Icons.chevron_right, color: Colors.white70)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white60,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith( // Use light theme for date picker but with our colors
             colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A6F4A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilterOption = 'Date range';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyFilter(String title) {
    setState(() {
      _selectedFilterOption = title;
      final now = DateTime.now();
      
      switch (title) {
        case 'All dates':
          _startDate = null;
          _endDate = null;
          break;
        case 'My posts':
           // Specific logic handled in build method via _selectedFilterOption check
           _startDate = null;
           _endDate = null;
           break;
        case 'Past week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Past month':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
         case 'Past year':
          _startDate = now.subtract(const Duration(days: 365));
          _endDate = now;
          break;
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No lost items reported yet",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Great news! It seems everyone has their belongings.",
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildItemCard(QueryDocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final description = data['description'] ?? 'No description';
    final imageUrl = data['imageUrl'] ?? '';
    final dateTimestamp = data['dateFound'] as Timestamp?;
    final dateFound = dateTimestamp != null
        ? DateFormat('MMMM d, yyyy').format(dateTimestamp.toDate())
        : 'Unknown Date';
    final contactEmail = data['contactEmail'] ?? 'No contact info';
    final reportUserId = data['userId'];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && reportUserId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A6F4A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "FOUND",
                            style: TextStyle(
                                color: const Color(0xFF5A6F4A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(dateFound,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Contact: $contactEmail",
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isOwner)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, doc.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text(
            "Are you sure you want to delete this report? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('lost_and_found_items')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting report: $e')),
          );
        }
      }
    }
  }
}
