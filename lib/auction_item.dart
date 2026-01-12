// lib/models/auction_item.dart

class AuctionItem {
  final String id;
  final String propertyId;
  final String title;
  final String owner;
  final String location;
  final double marketPrice;
  final double reservePrice;
  final double startingPrice;
  final String auctionDate;
  final String status;
  final String imagePath;
  final String contactNumber;
  final String description;
  final String category;

  AuctionItem({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.owner,
    required this.location,
    required this.marketPrice,
    required this.reservePrice,
    required this.startingPrice,
    required this.auctionDate,
    required this.status,
    required this.imagePath,
    required this.contactNumber,
    required this.description,
    required this.category,
  });

  factory AuctionItem.fromJson(Map<String, dynamic> json) {
    String img = (json['image'] ?? '').toString().trim();
    String imageUrl = img.isNotEmpty
        ? "https://neoerainfotech.com/Covai/" + img.replaceAll('\\', '/')
        : "https://neoerainfotech.com/Covai/uploads/placeholder.jpeg";

    return AuctionItem(
      id: json['id']?.toString() ?? '0',
      propertyId: json['property_id']?.toString().trim() ?? '',
      title: json['property_name']?.toString().trim() ?? 'Property',
      owner: json['owner']?.toString().trim() ?? 'Freehold',
      location: json['location']?.toString().trim() ?? 'Location not available',
      marketPrice: (json['market_price'] as num?)?.toDouble() ?? 0.0,
      reservePrice: (json['reserve_price'] as num?)?.toDouble() ?? 0.0,
      startingPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      auctionDate: json['auction_date']?.toString() ?? 'N/A',
      status: json['status']?.toString().trim() ?? 'Upcoming',
      imagePath: imageUrl,
      contactNumber: json['contact1_number']?.toString().trim() ?? 'N/A',
      description: json['description']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? 'N/A',
    );
  }
}