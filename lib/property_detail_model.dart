// lib/property_detail_model.dart

class PropertyDetail {
  final String id;
  final String propertyId;  // NEW: Added propertyId
  final String title;
  final String location;
  final double marketPrice;
  final double reservePrice;
  final double startingPrice;
  final String auctionDate;
  final String mainImageUrl;
  final String contactNumber;
  final String owner;
  final String status;
  final String description;
  final String category;

  const PropertyDetail({
    required this.id,
    required this.propertyId,  // NEW
    required this.title,
    required this.location,
    required this.marketPrice,
    required this.reservePrice,
    required this.startingPrice,
    required this.auctionDate,
    required this.mainImageUrl,
    required this.contactNumber,
    required this.owner,
    required this.status,
    required this.description,
    required this.category,
  });

  factory PropertyDetail.fromJson(Map<String, dynamic> json, String imageRootUrl) {
    String jsonImagePath = (json['image'] ?? '').toString().trim();
    String imageUrl = jsonImagePath.isNotEmpty
        ? imageRootUrl + jsonImagePath.replaceAll('\\', '/')
        : '${imageRootUrl}uploads/placeholder.jpeg';

    return PropertyDetail(
      id: json['id']?.toString() ?? '0',
      propertyId: json['property_id']?.toString().trim() ?? '0',  // NEW: Fetch property_id
      title: json['property_name']?.toString().trim() ?? 'Untitled Property',
      location: json['location']?.toString().trim() ?? 'N/A',
      marketPrice: (json['market_price'] as num?)?.toDouble() ?? 0.0,
      reservePrice: (json['reserve_price'] as num?)?.toDouble() ?? 0.0,
      startingPrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      auctionDate: json['auction_date']?.toString() ?? 'N/A',
      mainImageUrl: imageUrl,
      contactNumber: json['contact_number']?.toString().trim() ?? 'N/A',
      owner: json['owner']?.toString().trim() ?? 'Not Specified',
      status: json['status']?.toString().trim() ?? 'Upcoming',
      description: json['description']?.toString().trim() ?? 'No description available.',
      category: json['category']?.toString().trim() ?? 'N/A',
    );
  }
}