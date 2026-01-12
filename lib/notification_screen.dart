// lib/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

const Color royalBlue = Color(0xFF002366);

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Future<List<dynamic>>? _notificationsFuture;

  static const String _BASE_URL = "https://neoerainfotech.com/Covai/api/";

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<dynamic>> _fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse('${_BASE_URL}notifications_auctions.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Notification fetch error: $e');
      return [];
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> _getStatusDetails(String status) {
    switch (status) {
      case 'Live Now':
        return {'color': Colors.blue, 'icon': Icons.sensors};
      case 'Upcoming':
        return {'color': Colors.purple, 'icon': Icons.schedule};
      case 'Closed':
        return {'color': Colors.green, 'icon': Icons.check_circle};
      case 'On Hold':
        return {'color': Colors.orange, 'icon': Icons.pause_circle_filled};
      default:
        return {'color': royalBlue, 'icon': Icons.notifications};
    }
  }

  void _showNotificationPopup(BuildContext context, dynamic item) {
    final details = _getStatusDetails(item['status']);
    final price = _parsePrice(item['marketPrice'] ?? item['startingPrice']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          item['title'] ?? 'Property',
          style: const TextStyle(color: royalBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(details['icon'], color: details['color'], size: 20),
                const SizedBox(width: 8),
                Text(
                  item['status'],
                  style: TextStyle(color: details['color'], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 25),
            Text(
              'Price: ${_currencyFormatter.format(price)}',
              style: TextStyle(fontSize: 16, color: details['color'], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: royalBlue)),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(dynamic item) {
    final details = _getStatusDetails(item['status']);
    final price = _parsePrice(item['marketPrice'] ?? item['startingPrice']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: details['color'].withOpacity(0.1),
          child: Icon(details['icon'], color: details['color'], size: 28),
        ),
        title: Text(
          item['title'] ?? 'Property',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: royalBlue,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Status: ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                TextSpan(
                  text: '${item['status']} ',
                  style: TextStyle(
                    color: details['color'],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const TextSpan(
                  text: '| Price: ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                TextSpan(
                  text: _currencyFormatter.format(price),
                  style: TextStyle(
                    color: details['color'],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: const Icon(Icons.info_outline, size: 24, color: royalBlue),
        onTap: () => _showNotificationPopup(context, item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Activity Feed',
          style: TextStyle(color: royalBlue, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: royalBlue));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No recent auction activity.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: items.length,
            itemBuilder: (context, index) => _notificationTile(items[index]),
          );
        },
      ),
    );
  }
}