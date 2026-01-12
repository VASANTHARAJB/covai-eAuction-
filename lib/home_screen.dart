// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'property_detail_screen.dart';
import 'auctions_screen.dart';
import 'notification_screen.dart';
import 'enquiry_form_screen.dart';

// --- CONFIGURATION ---
const String _BASE_URL = "https://neoerainfotech.com/Covai/api/";
const String _IMAGE_ROOT_URL = "https://neoerainfotech.com/Covai/";

const Color royalBlue = Color(0xFF002366);

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class AuctionItem {
  final String id;
  final String title;
  final String imagePath;
  final String auctionDate;
  final double currentBid;
  final double startingPrice;
  final String location;
  final String status;
  final String owner;
  final double marketPrice;
  final double reservePrice;
  final String contactNumber;

  const AuctionItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.auctionDate,
    required this.currentBid,
    required this.startingPrice,
    required this.location,
    required this.status,
    required this.owner,
    required this.marketPrice,
    required this.reservePrice,
    required this.contactNumber,
  });

  factory AuctionItem.fromJson(Map<String, dynamic> json) {
    String forceString(dynamic value, [String defaultValue = 'N/A']) {
      if (value == null || value.toString().trim().isEmpty) return defaultValue;
      return value.toString().trim();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
    }

    String rawTitle = forceString(json['property_name'], 'Property');
    String img = forceString(json['image'], '');
    String imageUrl = img.isNotEmpty
        ? _IMAGE_ROOT_URL + img.replaceAll('\\', '/')
        : '${_IMAGE_ROOT_URL}uploads/placeholder.jpeg';

    String dateStr = forceString(json['auction_date']);
    String formattedDate = dateStr.contains(' ')
        ? dateStr.split(' ')[0]
        : dateStr;

    return AuctionItem(
      id: forceString(json['id']),
      title: rawTitle,
      imagePath: imageUrl,
      auctionDate: formattedDate,
      currentBid: parseDouble(json['current_bid']),
      startingPrice: parseDouble(json['price']),
      location: forceString(json['location'], 'Unknown Location'),
      status: forceString(json['status'], 'Upcoming'),
      owner: forceString(json['owner'], 'Not Specified'),
      marketPrice: parseDouble(json['market_price']),
      reservePrice: parseDouble(json['reserve_price']),
      contactNumber: forceString(json['contact1_number'], 'N/A'),
    );
  }
}

// Main Navigation Shell - Only ONE copy!
class MainScreenShell extends StatefulWidget {
  final String userId;
  const MainScreenShell({super.key, required this.userId});

  @override
  State<MainScreenShell> createState() => _MainScreenShellState();
}

class _MainScreenShellState extends State<MainScreenShell> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreenContent(),
      const AuctionsScreenContent(),
      const NotificationScreen(),
      EditableProfileScreen(customerId: widget.userId, currentUser: 'User'),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  void _goToProfile() => setState(() => _selectedIndex = 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: royalBlue,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'asset/images/logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Covai', style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Covai E-Auction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Welcome back', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _goToProfile,
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: royalBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Auctions'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  Future<List<AuctionItem>>? _auctionsFuture;
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  String _sortBy = 'Latest';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _fetchAuctions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAuctions() {
    setState(() {
      final query = _searchController.text.trim();
      _auctionsFuture = _loadData(query);
    });
  }

  Future<List<AuctionItem>> _loadData(String query) async {
    try {
      final Map<String, String> params = {};
      if (query.isNotEmpty) params['search'] = query;
      if (_sortBy == 'Oldest') params['sort'] = 'oldest';
      if (_fromDate != null) params['from_date'] = DateFormat('yyyy-MM-dd').format(_fromDate!);
      if (_toDate != null) params['to_date'] = DateFormat('yyyy-MM-dd').format(_toDate!);

      final uri = Uri.parse('${_BASE_URL}get_auctions.php')
          .replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => AuctionItem.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error loading auctions: $e');
      return [];
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: royalBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _fetchAuctions();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar + Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _fetchAuctions(),
                          decoration: InputDecoration(
                            hintText: "Search location or property...",
                            prefixIcon: const Icon(Icons.search, color: royalBlue),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_off, color: royalBlue),
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                      ),
                      IconButton(
                        icon: const CircleAvatar(
                          radius: 15,
                          backgroundColor: royalBlue,
                          child: Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                        ),
                        onPressed: _fetchAuctions,
                      ),
                    ],
                  ),
                ),

                // Filter Panel
                if (_showFilters)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Latest'),
                                value: 'Latest',
                                groupValue: _sortBy,
                                dense: true,
                                onChanged: (val) {
                                  setState(() {
                                    _sortBy = val!;
                                    _fetchAuctions();
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Oldest'),
                                value: 'Oldest',
                                groupValue: _sortBy,
                                dense: true,
                                onChanged: (val) {
                                  setState(() {
                                    _sortBy = val!;
                                    _fetchAuctions();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Posted Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _selectDate(context, true),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(_fromDate == null
                                    ? 'From Date'
                                    : DateFormat('dd MMM yyyy').format(_fromDate!)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _selectDate(context, false),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(_toDate == null
                                    ? 'To Date'
                                    : DateFormat('dd MMM yyyy').format(_toDate!)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_fromDate != null || _toDate != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _fromDate = null;
                                  _toDate = null;
                                  _fetchAuctions();
                                });
                              },
                              child: const Text('Clear Date Filter'),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Auction List
          Expanded(
            child: FutureBuilder<List<AuctionItem>>(
              future: _auctionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: royalBlue));
                }

                final items = snapshot.data ?? [];
                final isSearching = _searchController.text.trim().isNotEmpty;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          isSearching ? 'No auctions found' : 'No live or upcoming auctions',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSearching ? 'Try different keywords' : 'New auctions will appear here soon',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSearching ? 'Search Results' : 'Live & Upcoming Auctions',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () => context.findAncestorStateOfType<_MainScreenShellState>()?._onItemTapped(1),
                              child: const Text('View All', style: TextStyle(color: royalBlue)),
                            ),
                          ],
                        ),
                      );
                    }
                    return _buildAuctionCard(items[index - 1]);
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
            MaterialPageRoute(builder: (context) => const EnquiryFormScreen()),
          );
        },
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.contact_phone_outlined, size: 26),
        label: const Text(
          "Need Help Finding Property?",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAuctionCard(AuctionItem item) {
    final hasBids = item.currentBid > 0;
    final mainAmount = hasBids ? item.currentBid : item.startingPrice;
    final mainLabel = hasBids ? 'Current Bid' : 'Starting Price';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: royalBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imagePath,
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  ),
                  if (item.status == 'Live Now')
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'LIVE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.red),
                        ),
                      ),
                    ),
                  if (item.status == 'Upcoming')
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'UPCOMING',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.orange),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("Auction: ${item.auctionDate}", style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  Text(
                    '$mainLabel: ${_currencyFormatter.format(mainAmount)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: royalBlue),
                  ),
                  if (hasBids)
                    Text(
                      'Starting: ${_currencyFormatter.format(item.startingPrice)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(auctionSummary: item),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royalBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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
}