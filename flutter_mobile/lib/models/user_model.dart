class UserModel {
  final String id;
  final String? publicId;
  final String name;
  final String email;
  final String? phone;
  final String? imageUrl;
  final String role;

  const UserModel({
    required this.id,
    this.publicId,
    required this.name,
    required this.email,
    this.phone,
    this.imageUrl,
    this.role = 'patient',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      publicId: json['publicId']?.toString() ?? json['public_id']?.toString(),
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: json['phone']?.toString(),
      imageUrl: json['image']?.toString() ?? json['profile_pic_url']?.toString(),
      role: '${json['role'] ?? 'patient'}',
    );
  }
}
