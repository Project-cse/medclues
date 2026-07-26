import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appointment_model.dart';
import '../models/slot_model.dart';

enum AppointmentDisplayStatus {
  booked,
  pending,
  confirmed,
  checkedIn,
  readyForDoctor,
  nextToConsult,
  inConsultation,
  completed,
  cancelled,
  noShow,
  missed,
  refundPending,
  refunded,
  followupAvailable,
  followupUsed,
  followupExpired,
  rescheduledOnce,
  expired,
  upcoming,
  doctorOnBreak,
}

class AppointmentStatusInfo {
  const AppointmentStatusInfo({
    required this.status,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final AppointmentDisplayStatus status;
  final String label;
  final Color backgroundColor;
  final Color textColor;
}

AppointmentStatusInfo resolveAppointmentStatus(
  AppointmentModel appointment, {
  String? doctorStatusOverride,
  required String Function(String key) labelFor,
  bool isNextUp = false,
  String? lifecycleStatusOverride,
}) {
  if (appointment.cancelled || appointment.status == 'cancelled') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.cancelled,
      label: labelFor('cancelled'),
      backgroundColor: AppColors.error.withValues(alpha: 0.12),
      textColor: AppColors.error,
    );
  }

  final doctorStatus = (doctorStatusOverride ?? '').toLowerCase();
  if (doctorStatus == 'on-break' || doctorStatus == 'on_break') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.doctorOnBreak,
      label: labelFor('doctorOnBreak'),
      backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
      textColor: const Color(0xFFEA580C),
    );
  }

  final lifecycle =
      (lifecycleStatusOverride ?? appointment.lifecycleStatus ?? '')
          .toUpperCase();
  final status = appointment.status.toLowerCase();

  // Lifecycle-first so FOLLOWUP_* is not masked by isCompleted.
  if (lifecycle == 'CANCELLED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.cancelled,
      label: labelFor('cancelled'),
      backgroundColor: AppColors.error.withValues(alpha: 0.12),
      textColor: AppColors.error,
    );
  }
  if (lifecycle == 'FOLLOWUP_AVAILABLE') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.followupAvailable,
      label: labelFor('followupAvailable'),
      backgroundColor: AppColors.logoTeal.withValues(alpha: 0.12),
      textColor: AppColors.logoTeal,
    );
  }
  if (lifecycle == 'FOLLOWUP_USED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.followupUsed,
      label: labelFor('followupUsed'),
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      textColor: AppColors.primaryBlue,
    );
  }
  if (lifecycle == 'FOLLOWUP_EXPIRED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.followupExpired,
      label: labelFor('followupExpired'),
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }
  if (lifecycle == 'RESCHEDULED_ONCE') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.rescheduledOnce,
      label: labelFor('rescheduledOnce'),
      backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
      textColor: const Color(0xFFEA580C),
    );
  }
  if (lifecycle == 'EXPIRED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.expired,
      label: labelFor('expired'),
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }
  if (lifecycle == 'CLOSED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.completed,
      label: 'Closed',
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }
  if (lifecycle == 'COMPLETED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.completed,
      label: labelFor('completed'),
      backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
      textColor: const Color(0xFF16A34A),
    );
  }
  if (lifecycle == 'NO_SHOW') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.noShow,
      label: labelFor('noShow'),
      backgroundColor: AppColors.error.withValues(alpha: 0.12),
      textColor: AppColors.error,
    );
  }
  if (lifecycle == 'MISSED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.missed,
      label: labelFor('missed'),
      backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
      textColor: const Color(0xFFEA580C),
    );
  }
  if (lifecycle == 'REFUNDED') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.refunded,
      label: labelFor('refunded'),
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }
  if (lifecycle == 'REFUND_PENDING' || lifecycle.startsWith('REFUND_')) {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.refundPending,
      label: labelFor('refundPending'),
      backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.15),
      textColor: const Color(0xFFEA580C),
    );
  }

  if (appointment.isCompleted || appointment.status == 'completed') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.completed,
      label: labelFor('completed'),
      backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
      textColor: const Color(0xFF16A34A),
    );
  }

  if (lifecycle == 'IN_CONSULTATION' ||
      lifecycle == 'IN_PROGRESS' ||
      status == 'in-consult') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.inConsultation,
      label: labelFor('inProgress'),
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      textColor: AppColors.primaryBlue,
    );
  }
  if (lifecycle == 'READY_FOR_DOCTOR') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.readyForDoctor,
      label: labelFor('readyForDoctor'),
      backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
      textColor: const Color(0xFF16A34A),
    );
  }
  if (isNextUp) {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.nextToConsult,
      label: labelFor('nextToConsult'),
      backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
      textColor: const Color(0xFF16A34A),
    );
  }
  // CHECKED_IN is canonical; IN_QUEUE / in-queue are reception desk aliases.
  if (lifecycle == 'CHECKED_IN' ||
      lifecycle == 'IN_QUEUE' ||
      status == 'in-queue') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.checkedIn,
      label: labelFor('checkedIn'),
      backgroundColor: AppColors.logoTeal.withValues(alpha: 0.12),
      textColor: AppColors.logoTeal,
    );
  }
  if (lifecycle == 'CONFIRMED' || status == 'confirmed') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.confirmed,
      label: labelFor('confirmed'),
      backgroundColor: AppColors.logoTeal.withValues(alpha: 0.12),
      textColor: AppColors.logoTeal,
    );
  }
  if (status == 'pending') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.pending,
      label: labelFor('pending'),
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }
  if (lifecycle == 'BOOKED' || status == 'booked') {
    return AppointmentStatusInfo(
      status: AppointmentDisplayStatus.booked,
      label: labelFor('booked'),
      backgroundColor: Colors.grey.withValues(alpha: 0.15),
      textColor: Colors.grey.shade700,
    );
  }

  return AppointmentStatusInfo(
    status: AppointmentDisplayStatus.upcoming,
    label: labelFor('upcoming'),
    backgroundColor: AppColors.warning.withValues(alpha: 0.15),
    textColor: AppColors.warning,
  );
}

bool appointmentShowsLiveQueue(AppointmentModel appointment) {
  if (appointment.cancelled || appointment.isCompleted) return false;
  final lifecycle = (appointment.lifecycleStatus ?? '').toUpperCase();
  final status = appointment.status.toLowerCase();
  return lifecycle == 'IN_CONSULTATION' ||
      lifecycle == 'IN_PROGRESS' ||
      lifecycle == 'CHECKED_IN' ||
      lifecycle == 'READY_FOR_DOCTOR' ||
      lifecycle == 'CONFIRMED' ||
      lifecycle == 'RESCHEDULED_ONCE' ||
      status == 'in-queue' ||
      status == 'in-consult' ||
      status == 'confirmed';
}

bool isAppointmentToday(String slotDate) {
  final parsed = parseSlotDateKey(slotDate);
  if (parsed == null) return false;
  final now = DateTime.now();
  return parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day;
}
