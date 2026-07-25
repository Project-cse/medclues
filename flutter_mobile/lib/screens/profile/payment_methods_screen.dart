import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

/// Matches mobile/app/(patient)/payment-methods.tsx
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              'Online consultations use Razorpay at booking time. In-clinic visits can be paid at hospital reception, or paid online via Razorpay when that option is offered at booking.',
              style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
