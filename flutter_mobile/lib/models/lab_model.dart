class LabModel {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final double? rating;
  final bool isOpen;
  final List<String> availableTests;

  const LabModel({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.rating,
    this.isOpen = true,
    this.availableTests = const [],
  });

  factory LabModel.fromJson(Map<String, dynamic> json) {
    List<String> tests = [];
    final services = json['services'] ?? json['available_tests'];
    if (services is List) {
      tests = services.map((e) => '$e').toList();
    } else if (services is String && services.isNotEmpty) {
      tests = [services];
    }
    return LabModel(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'Lab'}',
      address: '${json['location'] ?? json['city'] ?? json['address'] ?? ''}',
      imageUrl: json['image']?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : double.tryParse('${json['rating']}'),
      isOpen: json['openNow'] != false && json['open_now'] != false,
      availableTests: tests,
    );
  }
}
