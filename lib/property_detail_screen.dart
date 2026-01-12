// lib/property_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'home_screen.dart';
import 'property_detail_model.dart';

const String _BASE_URL = "https://neoerainfotech.com/Covai/api/";
const String _IMAGE_ROOT_URL = "https://neoerainfotech.com/Covai/";

const Color royalBlue = Color(0xFF002366);

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class PropertyDetailScreen extends StatefulWidget {
  final AuctionItem auctionSummary;

  const PropertyDetailScreen({super.key, required this.auctionSummary});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Future<PropertyDetail>? _fullDetailsFuture;

  @override
  void initState() {
    super.initState();
    _fullDetailsFuture = _fetchFullAuctionDetails(widget.auctionSummary.id);
  }

  Future<PropertyDetail> _fetchFullAuctionDetails(String auctionId) async {
    try {
      final response = await http.get(Uri.parse('${_BASE_URL}get_auction_details.php?id=$auctionId'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] is Map) {
          return PropertyDetail.fromJson(responseData['data'], _IMAGE_ROOT_URL);
        } else {
          throw responseData['message'] ?? 'Invalid response';
        }
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      return PropertyDetail(
        id: widget.auctionSummary.id,
        propertyId: '0',  // Fallback
        title: widget.auctionSummary.title,
        location: widget.auctionSummary.location,
        marketPrice: 0.0,
        reservePrice: 0.0,
        startingPrice: widget.auctionSummary.startingPrice,
        auctionDate: widget.auctionSummary.auctionDate,
        mainImageUrl: widget.auctionSummary.imagePath,
        contactNumber: 'N/A',
        owner: 'Not Specified',
        status: widget.auctionSummary.status,
        description: 'No description available.',
        category: 'N/A',
      );
    }
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case 'Live Now':
        return {'color': Colors.red, 'text': 'Live Now'};
      case 'Upcoming':
        return {'color': Colors.orange, 'text': 'Upcoming'};
      case 'Closed':
        return {'color': Colors.grey, 'text': 'Closed'};
      case 'On Hold':
        return {'color': Colors.blueGrey, 'text': 'On Hold'};
      default:
        return {'color': royalBlue, 'text': status};
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
          const Divider(color: Color(0xFFE0E0E0), height: 20),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    const phoneUrl = 'tel:+918072756436';
    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
      await launchUrl(Uri.parse(phoneUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    const whatsappUrl = 'https://wa.me/918072756436?text=Hi';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  void _shareProperty() {
    final propertyId = widget.auctionSummary.id;
    final shareUrl = "https://covai.brigadedigitalsolutions.com/property?id=$propertyId";
    final shareText = "Check out this auction property on Covai E-Auction!\n\n${widget.auctionSummary.title}\n\nView Details: $shareUrl";

    Share.share(
      shareText,
      subject: 'Covai E-Auction Property - ${widget.auctionSummary.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Property Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<PropertyDetail>(
        future: _fullDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: royalBlue));
          }

          final detail = snapshot.data ??
              PropertyDetail(
                id: widget.auctionSummary.id,
                propertyId: '0',  // Fallback
                title: widget.auctionSummary.title,
                location: widget.auctionSummary.location,
                marketPrice: 0.0,
                reservePrice: 0.0,
                startingPrice: widget.auctionSummary.startingPrice,
                auctionDate: widget.auctionSummary.auctionDate,
                mainImageUrl: widget.auctionSummary.imagePath,
                contactNumber: 'N/A',
                owner: 'Not Specified',
                status: widget.auctionSummary.status,
                description: 'No description available.',
                category: 'N/A',
              );

          final statusStyle = _getStatusStyle(detail.status);
          final displayTitle = detail.title.trim().isNotEmpty ? detail.title.trim() : 'Property';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Image + Status Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        detail.mainImageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 240,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusStyle['color'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusStyle['text'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  displayTitle,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: royalBlue),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail.location.trim().isNotEmpty ? detail.location.trim() : 'Location not available',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text('Auction Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _buildDetailRow('Starting Price', _currencyFormatter.format(detail.startingPrice),
                    isBold: true, valueColor: royalBlue),
                if (detail.marketPrice > 0)
                  _buildDetailRow('Market Price', _currencyFormatter.format(detail.marketPrice)),
                if (detail.reservePrice > 0)
                  _buildDetailRow('Reserve Price', _currencyFormatter.format(detail.reservePrice)),

                _buildDetailRow(
                  detail.status == 'Live Now' ? 'Auction Ends On' : 'Auction Date & Time',
                  detail.auctionDate.contains(' ')
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(detail.auctionDate))
                      : detail.auctionDate,
                  isBold: true,
                ),

                const SizedBox(height: 20),

                if (detail.contactNumber.trim().isNotEmpty && detail.contactNumber != 'N/A') ...[
                  const Text('Contact Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Contact Number', detail.contactNumber, isBold: true),
                  const SizedBox(height: 10),
                ],

                const Text('Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDetailRow('Property Category', detail.category.trim().isNotEmpty ? detail.category.trim() : 'Not Specified'),

                const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                  detail.description.trim().isNotEmpty ? detail.description.trim() : 'No description available.',
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                ),

                const SizedBox(height: 30),

                const Text('Additional Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDetailRow('Property ID', '#${detail.propertyId}'),  // FIXED: Use propertyId
                _buildDetailRow('Ownership Type', detail.owner.trim().isNotEmpty ? detail.owner.trim() : 'Not Disclosed'),

                const SizedBox(height: 40),

                // OPTIMIZED: Call, WhatsApp, and Share (using Flutter built-in Icons.share)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Call Button
                      GestureDetector(
                        onTap: _makePhoneCall,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.phone, size: 32, color: royalBlue),
                            ),
                            const SizedBox(height: 6),
                            const Text('Call', style: TextStyle(fontSize: 12, color: royalBlue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                      // WhatsApp Button
                      GestureDetector(
                        onTap: _openWhatsApp,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.message, size: 32, color: Colors.green),
                            ),
                            const SizedBox(height: 6),
                            const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                      // Share Button - Using Flutter's built-in Icons.share
                      GestureDetector(
                        onTap: _shareProperty,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Icon(Icons.share, size: 32, color: royalBlue),
                            ),
                            const SizedBox(height: 6),
                            const Text('Share', style: TextStyle(fontSize: 12, color: royalBlue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}