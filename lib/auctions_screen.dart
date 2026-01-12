// lib/auctions_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'property_detail_screen.dart';
import 'home_screen.dart'; // Imports the correct AuctionItem

const Color royalBlue = Color(0xFF002366);

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

// Temporary model for inactive auctions
class InactiveAuction {
  final String id;
  final String propertyId;
  final String propertyName;
  final String owner;
  final String location;
  final double price;
  final String auctionDate;
  final String status;
  final String image;
  final String contactNumber;

  InactiveAuction({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.owner,
    required this.location,
    required this.price,
    required this.auctionDate,
    required this.status,
    required this.image,
    required this.contactNumber,
  });

  factory InactiveAuction.fromJson(Map<String, dynamic> json) {
    String img = (json['image'] ?? '').toString().trim();
    String imageUrl = img.isNotEmpty
        ? "https://neoerainfotech.com/Covai/${img.replaceAll('\\', '/')}"
        : "https://neoerainfotech.com/Covai/uploads/placeholder.jpeg";

    return InactiveAuction(
      id: json['id']?.toString() ?? '0',
      propertyId: json['property_id']?.toString().trim() ?? '',
      propertyName: json['property_name']?.toString().trim() ?? 'Property',
      owner: json['owner']?.toString().trim() ?? 'Freehold',
      location: json['location']?.toString().trim() ?? 'N/A',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      auctionDate: json['auction_date']?.toString() ?? 'N/A',
      status: json['status']?.toString().trim() ?? 'Closed',
      image: imageUrl,
      contactNumber: json['contact1_number']?.toString().trim() ?? 'N/A',
    );
  }

  // Convert to original AuctionItem for PropertyDetailScreen
  AuctionItem toAuctionItem() {
    return AuctionItem(
      id: id,
      title: propertyName,
      imagePath: image,
      auctionDate: auctionDate.split(' ')[0],
      currentBid: 0.0,
      startingPrice: price,
      location: location,
      status: status,
      owner: owner,
      marketPrice: 0.0,
      reservePrice: 0.0,
      contactNumber: contactNumber,
    );
  }
}

class AuctionsScreenContent extends StatefulWidget {
  const AuctionsScreenContent({super.key});

  @override
  State<AuctionsScreenContent> createState() => _AuctionsScreenContentState();
}

class _AuctionsScreenContentState extends State<AuctionsScreenContent> {
  Future<List<InactiveAuction>>? _auctionsFuture;
  final TextEditingController _searchController = TextEditingController();

  static const String _baseUrl = "https://neoerainfotech.com/Covai/api/";

  @override
  void initState() {
    super.initState();
    _fetchAuctions();
  }

  void _fetchAuctions() {
    setState(() {
      _auctionsFuture = _loadAuctions(_searchController.text.trim());
    });
  }

  Future<List<InactiveAuction>> _loadAuctions(String query) async {
    try {
      final uri = Uri.parse('${_baseUrl}inactive_auctions.php')
          .replace(queryParameters: query.isEmpty ? null : {'search': query});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => InactiveAuction.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  Widget _buildCard(InactiveAuction item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Status Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.status == 'Closed' ? Colors.grey.shade700 : Colors.blueGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.propertyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: royalBlue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Auction Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(item.auctionDate))}",
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Starting Price',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const Spacer(),
                          Text(
                            _currencyFormatter.format(item.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: royalBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final auctionItem = item.toAuctionItem();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(auctionSummary: auctionItem),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('All Auctions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchAuctions(),
                decoration: InputDecoration(
                  hintText: "Search location or property...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: royalBlue, size: 22),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _fetchAuctions();
                          },
                        ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: royalBlue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          onPressed: _fetchAuctions,
                        ),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Auctions List
          Expanded(
            child: FutureBuilder<List<InactiveAuction>>(
              future: _auctionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: royalBlue));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        const Text(
                          'No closed or on-hold auctions',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildCard(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}