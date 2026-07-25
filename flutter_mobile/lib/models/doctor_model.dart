class DoctorModel {
  final String id;
  final String name;
  final String specialization;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final String? experienceLabel;
  final int experienceYears;
  final double consultationFee;
  final double videoConsultationFee;
  final bool available;
  final String? status;
  final String? hospitalName;
  final String? address;
  final String? addressLine1;
  final String? addressLine2;
  final String? about;
  final String? degree;
  final String? phone;
  final Map<String, List<String>> slotsBooked;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.experienceLabel,
    this.experienceYears = 0,
    this.consultationFee = 500,
    this.videoConsultationFee = 450,
    this.available = true,
    this.status,
    this.hospitalName,
    this.address,
    this.addressLine1,
    this.addressLine2,
    this.about,
    this.degree,
    this.phone,
    this.slotsBooked = const {},
  });

  DoctorModel copyWith({String? hospitalName, String? status, bool? available}) {
    return DoctorModel(
      id: id,
      name: name,
      specialization: specialization,
      imageUrl: imageUrl,
      rating: rating,
      reviewCount: reviewCount,
      experienceLabel: experienceLabel,
      experienceYears: experienceYears,
      consultationFee: consultationFee,
      videoConsultationFee: videoConsultationFee,
      available: available ?? this.available,
      status: status ?? this.status,
      hospitalName: hospitalName ?? this.hospitalName,
      address: address,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      about: about,
      degree: degree,
      phone: phone,
      slotsBooked: slotsBooked,
    );
  }

  String? get displayRatingText =>
      hasRating ? rating!.toStringAsFixed(1) : null;

  bool get hasRating => rating != null && rating! > 0;

  String get _statusKey => (status ?? '').toLowerCase().trim();

  bool get isInactive => _statusKey == 'inactive';

  /// Matches Dean portal: available, busy, emergency, unavailable (+ inactive).
  bool get isOnline {
    if (isInactive || !available) return false;
    if (_statusKey == 'unavailable' || _statusKey == 'offline' || _statusKey == 'emergency') {
      return false;
    }
    if (_statusKey == 'busy') return true;
    if (_statusKey == 'online' || _statusKey == 'in-clinic' || _statusKey == 'available') {
      return true;
    }
    return available;
  }

  bool get isBookable {
    if (isInactive || !available) return false;
    return _statusKey == 'available' ||
        _statusKey == 'busy' ||
        _statusKey == 'online' ||
        _statusKey == 'in-clinic' ||
        _statusKey.isEmpty;
  }

  String get onlineStatusLabel {
    switch (_statusKey) {
      case 'inactive':
        return 'Inactive';
      case 'emergency':
        return 'Emergency';
      case 'busy':
        return 'Busy';
      case 'unavailable':
      case 'offline':
        return 'Unavailable';
      case 'in-clinic':
      case 'in_clinic':
        return 'In clinic';
      case 'online':
        return 'Online';
      case 'available':
        return 'Available';
      default:
        return available ? 'Available' : 'Unavailable';
    }
  }

  static ({String? line1, String? line2, String? full}) _parseAddressFields(dynamic addr) {
    if (addr == null) return (line1: null, line2: null, full: null);
    if (addr is String) {
      final s = addr.trim();
      return (line1: s.isEmpty ? null : s, line2: null, full: s.isEmpty ? null : s);
    }
    if (addr is Map) {
      final line1 = (addr['line1']?.toString() ?? '').trim();
      final line2 = (addr['line2']?.toString() ?? '').trim();
      final joined = [line1, line2].where((e) => e.isNotEmpty).join(', ');
      return (
        line1: line1.isEmpty ? null : line1,
        line2: line2.isEmpty ? null : line2,
        full: joined.isEmpty ? null : joined,
      );
    }
    return (line1: null, line2: null, full: null);
  }

  static double? _parseRating(Map<String, dynamic> json) {
    final v = json['rating'] ?? json['avg_rating'] ?? json['average_rating'];
    if (v == null) return null;
    if (v is num) return v > 0 ? v.toDouble() : null;
    final p = double.tryParse('$v');
    return (p != null && p > 0) ? p : null;
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final expRaw = json['experience'] ?? json['experience_years'];
    String? expLabel;
    var expYears = 0;
    if (expRaw is num) {
      expYears = expRaw.toInt();
      expLabel = '$expYears Years';
    } else if (expRaw != null) {
      expLabel = expRaw.toString();
      final m = RegExp(r'(\d+)').firstMatch(expLabel);
      if (m != null) expYears = int.tryParse(m.group(1)!) ?? 0;
    }

    final fees = json['fees'] ?? json['consultationFee'] ?? json['consultation_fee'] ?? 600;
    final videoFees = json['videoConsultationFee'] ??
        json['video_consultation_fee'] ??
        450;
    Map<String, List<String>> booked = {};
    final sb = json['slots_booked'] ?? json['slotsBooked'];
    if (sb is Map) {
      sb.forEach((k, v) {
        if (v is List) booked['$k'] = v.map((e) => '$e').toList();
      });
    }

    final reviews = json['reviews'] ?? json['review_count'] ?? json['reviewCount'];

    final addressFields = _parseAddressFields(json['address']);

    return DoctorModel(
      id: '${json['id'] ?? json['_id'] ?? json['docId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      specialization: '${json['specialization'] ?? json['speciality'] ?? json['degree'] ?? 'General'}',
      imageUrl: (json['image'] ?? json['profile_pic_url'] ?? json['profilePicUrl'])?.toString(),
      rating: _parseRating(json),
      reviewCount: reviews is num ? reviews.toInt() : int.tryParse('$reviews'),
      experienceLabel: expLabel,
      experienceYears: expYears,
      consultationFee: fees is num ? fees.toDouble() : double.tryParse('$fees') ?? 600,
      videoConsultationFee:
          videoFees is num ? videoFees.toDouble() : double.tryParse('$videoFees') ?? 450,
      available: json['available'] != false && json['status'] != 'unavailable',
      status: (json['status'] ?? json['doctorStatus'])?.toString(),
      hospitalName: json['hospitalName']?.toString() ?? json['hospital_name']?.toString(),
      address: addressFields.full,
      addressLine1: addressFields.line1,
      addressLine2: addressFields.line2,
      about: json['about']?.toString(),
      degree: (json['degree'] ?? json['qualification'])?.toString(),
      phone: (json['phone'] ?? json['hospital_contact'] ?? json['hospitalContact'])?.toString(),
      slotsBooked: booked,
    );
  }
}
