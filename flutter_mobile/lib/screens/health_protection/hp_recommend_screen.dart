import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';

class HpRecommendScreen extends ConsumerStatefulWidget {
  const HpRecommendScreen({super.key});

  @override
  ConsumerState<HpRecommendScreen> createState() => _HpRecommendScreenState();
}

class _HpRecommendScreenState extends ConsumerState<HpRecommendScreen> {
  final _age = TextEditingController(text: '32');
  final _income = TextEditingController(text: '60000');
  final _city = TextEditingController(text: 'Hyderabad');
  final _budget = TextEditingController(text: '1200');
  final _conditions = TextEditingController();
  final _occupation = TextEditingController(text: 'Professional');
  String _gender = 'Male';
  bool _smoking = false;
  bool _alcohol = false;
  int _family = 2;
  bool _loading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _age.dispose();
    _income.dispose();
    _city.dispose();
    _budget.dispose();
    _conditions.dispose();
    _occupation.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(healthProtectionServiceProvider).recommend({
        'age': int.tryParse(_age.text) ?? 30,
        'gender': _gender,
        'occupation': _occupation.text.trim(),
        'monthlyIncome': double.tryParse(_income.text) ?? 0,
        'city': _city.text.trim(),
        'medicalConditions': _conditions.text.trim().isEmpty
            ? 'none'
            : _conditions.text.trim(),
        'smoking': _smoking,
        'alcohol': _alcohol,
        'familyMembers': _family,
        'budget': double.tryParse(_budget.text) ?? 1000,
        'maternity': _family > 2,
      });
      if (!mounted) return;
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recs = (_result?['recommendations'] as List?) ?? [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.hpRecommendTitle),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _tf(_age, 'Age', TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                ),
                _tf(_occupation, l10n.hpOccupation),
                _tf(_income, l10n.hpMonthlyIncome, TextInputType.number),
                _tf(_city, l10n.hpCity),
                _tf(_conditions, l10n.hpMedicalConditions),
                _tf(_budget, l10n.hpMonthlyBudget, TextInputType.number),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.hpSmoking),
                  value: _smoking,
                  onChanged: (v) => setState(() => _smoking = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.hpAlcohol),
                  value: _alcohol,
                  onChanged: (v) => setState(() => _alcohol = v),
                ),
                Row(
                  children: [
                    Text(l10n.hpFamilyMembers),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _family = (_family - 1).clamp(1, 8)),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_family',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () =>
                          setState(() => _family = (_family + 1).clamp(1, 8)),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _run,
            child: Text(_loading ? l10n.hpAnalyzing : l10n.hpGetTopPlans),
          ),
          if (_result?['overview'] != null) ...[
            const SizedBox(height: 16),
            Text('${_result!['overview']}',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          ...recs.map((raw) {
            final p = Map<String, dynamic>.from(raw as Map);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            '${p['companyName'] ?? 'P'}'[0],
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p['name']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text('${p['companyName']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'AI ${p['aiRecommendationScore']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                        '₹${p['monthlyPremium']}/mo · Cover ₹${p['coverageAmount']}'),
                    Text(
                        'Cashless: ${p['cashlessHospitals']} · Wait: ${p['waitingPeriodDays']}d · Room: ${p['roomRent']}'),
                    Text(
                        'Maternity: ${p['maternity'] == true ? 'Yes' : 'No'} · CI: ${p['criticalIllness'] == true ? 'Yes' : 'No'} · PED: ${p['pedWaitingDays']}d'),
                    const SizedBox(height: 8),
                    Text(l10n.hpWhyRecommended,
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    ...((p['whyRecommended'] as List?) ?? [])
                        .map((w) => Text('• $w')),
                    Text(l10n.hpPros,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    ...((p['pros'] as List?) ?? []).map((w) => Text('+ $w')),
                    Text(l10n.hpCons,
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    ...((p['cons'] as List?) ?? []).map((w) => Text('- $w')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
