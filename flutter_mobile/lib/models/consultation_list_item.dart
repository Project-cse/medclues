class ConsultationListItem {
  const ConsultationListItem({
    required this.id,
    required this.appointmentId,
    required this.doctorName,
    required this.speciality,
    required this.date,
    this.status = '',
    this.hasPrescription = false,
  });

  final String id;
  final String appointmentId;
  final String doctorName;
  final String speciality;
  final String date;
  final String status;
  final bool hasPrescription;

  factory ConsultationListItem.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctorId'];
    String doctorName = 'Doctor';
    String speciality = '';
    if (doctor is Map) {
      doctorName = '${doctor['name'] ?? 'Doctor'}';
      speciality = '${doctor['speciality'] ?? doctor['specialization'] ?? ''}';
    }

    final apptRaw = json['appointment_id'] ?? json['appointmentId'];
    final apptId = (apptRaw == null || '$apptRaw' == 'null') ? '' : '$apptRaw'.trim();
    final created = json['created_at'] ?? json['createdAt'] ?? json['scheduled_at'] ?? '';
    final prescription = json['prescription']?.toString() ?? '';

    return ConsultationListItem(
      id: '${json['id'] ?? ''}',
      appointmentId: apptId,
      doctorName: doctorName,
      speciality: speciality,
      date: '$created',
      status: '${json['status'] ?? ''}',
      hasPrescription: prescription.trim().isNotEmpty,
    );
  }
}
