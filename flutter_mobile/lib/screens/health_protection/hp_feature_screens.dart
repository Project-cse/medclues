import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../utils/location_utils.dart';
import '../../widgets/common/app_snackbar.dart';

/// Compare, Eligibility, Analyze, Claims, Cashless, Family, Expenses, Risk, Chat, Analytics
class HpCompareScreen extends ConsumerStatefulWidget {
  const HpCompareScreen({super.key});
  @override
  ConsumerState<HpCompareScreen> createState() => _HpCompareScreenState();
}

class _HpCompareScreenState extends ConsumerState<HpCompareScreen> {
  List<Map<String, dynamic>> _plans = [];
  final _selected = <int>{};
  Map<String, dynamic>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await ref.read(healthProtectionServiceProvider).plans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _compare() async {
    if (_selected.length < 2) {
      AppSnackbar.show(context, AppLocalizations.of(context)!.hpCompareNeedTwo);
      return;
    }
    try {
      final data = await ref
          .read(healthProtectionServiceProvider)
          .compare(_selected.toList());
      setState(() => _result = data);
    } catch (e) {
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.hpCompareTitle),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._plans.map((p) {
                  final id = int.tryParse('${p['id']}') ?? 0;
                  return CheckboxListTile(
                    value: _selected.contains(id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          if (_selected.length < 4) _selected.add(id);
                        } else {
                          _selected.remove(id);
                        }
                      });
                    },
                    title: Text('${p['name']}'),
                    subtitle: Text(
                        '${p['companyName']} · ₹${p['monthlyPremium']}/mo'),
                  );
                }),
                FilledButton(onPressed: _compare, child: Text(l10n.hpCompareAction)),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'AI pick: ${_result!['aiRecommendation']?['planName']} — ${_result!['aiRecommendation']?['reason']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Field')),
                        ...(((_result!['plans'] as List?) ?? []).map(
                          (p) => DataColumn(
                              label: Text('${(p as Map)['name']}',
                                  style: const TextStyle(fontSize: 11))),
                        )),
                      ],
                      rows: [
                        for (final col in (_result!['columns'] as List? ?? []))
                          DataRow(cells: [
                            DataCell(Text('$col')),
                            ...(((_result!['plans'] as List?) ?? []).map((p) {
                              final m = p as Map;
                              return DataCell(Text('${m[col]}'));
                            })),
                          ]),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class HpEligibilityScreen extends ConsumerStatefulWidget {
  const HpEligibilityScreen({super.key});
  @override
  ConsumerState<HpEligibilityScreen> createState() =>
      _HpEligibilityScreenState();
}

class _HpEligibilityScreenState extends ConsumerState<HpEligibilityScreen> {
  final _age = TextEditingController(text: '28');
  final _income = TextEditingController(text: '20000');
  final _state = TextEditingController(text: 'Telangana');
  bool _student = false;
  bool _corporate = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _age.dispose();
    _income.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final r = await ref.read(healthProtectionServiceProvider).eligibility({
        'age': int.tryParse(_age.text) ?? 0,
        'monthlyIncome': double.tryParse(_income.text) ?? 0,
        'state': _state.text.trim(),
        'student': _student,
        'corporate': _corporate,
      });
      setState(() => _results = r);
    } catch (e) {
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpEligibilityTitle),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _age,
              decoration: InputDecoration(labelText: l10n.hpAge),
              keyboardType: TextInputType.number),
          TextField(
              controller: _income,
              decoration: InputDecoration(labelText: l10n.hpMonthlyIncome),
              keyboardType: TextInputType.number),
          TextField(
              controller: _state,
              decoration: InputDecoration(labelText: l10n.hpStateCity)),
          SwitchListTile(
              title: Text(l10n.hpStudent),
              value: _student,
              onChanged: (v) => setState(() => _student = v)),
          SwitchListTile(
              title: Text(l10n.hpCorporateCover),
              value: _corporate,
              onChanged: (v) => setState(() => _corporate = v)),
          FilledButton(onPressed: _check, child: Text(l10n.hpCheckEligibility)),
          const SizedBox(height: 12),
          ..._results.map((r) => Card(
                child: ListTile(
                  leading: Icon(
                    r['eligible'] == true
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    color: r['eligible'] == true ? Colors.green : Colors.grey,
                  ),
                  title: Text('${r['scheme']}'),
                  subtitle: Text('${r['reason']}'),
                ),
              )),
        ],
      ),
    );
  }
}

class HpAnalyzeScreen extends ConsumerStatefulWidget {
  const HpAnalyzeScreen({super.key});
  @override
  ConsumerState<HpAnalyzeScreen> createState() => _HpAnalyzeScreenState();
}

class _HpAnalyzeScreenState extends ConsumerState<HpAnalyzeScreen> {
  bool _busy = false;
  Map<String, dynamic>? _result;

  Future<void> _pick() async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty || pick.files.first.bytes == null) {
      return;
    }
    final f = pick.files.first;
    setState(() => _busy = true);
    try {
      final data = await ref.read(healthProtectionServiceProvider).analyzePolicy(
            bytes: f.bytes!,
            filename: f.name,
          );
      if (!mounted) return;
      setState(() {
        _result = data;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _result?['summary'];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpPolicyAnalyzer),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.upload_file),
            label: Text(_busy ? 'Analyzing…' : 'Upload PDF / image / card'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text('${_result!['plainExplanation']}',
                style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            if (summary is Map)
              ...summary.entries.map((e) => ListTile(
                    dense: true,
                    title: Text('${e.key}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${e.value}'),
                  )),
          ],
        ],
      ),
    );
  }
}

class HpClaimsScreen extends ConsumerStatefulWidget {
  const HpClaimsScreen({super.key});
  @override
  ConsumerState<HpClaimsScreen> createState() => _HpClaimsScreenState();
}

class _HpClaimsScreenState extends ConsumerState<HpClaimsScreen> {
  List<Map<String, dynamic>> _claims = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(healthProtectionServiceProvider).claims();
      if (!mounted) return;
      setState(() {
        _claims = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _newClaim() async {
    try {
      final c = await ref.read(healthProtectionServiceProvider).createClaim({
        'title': 'Hospital claim',
        'amountClaimed': 25000,
      });
      final id = c['id'];
      if (id != null && mounted) {
        context.push(RouteNames.hpClaimDetail.replaceFirst(':id', '$id'));
      }
      _load();
    } catch (e) {
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpClaims),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newClaim,
        label: Text(l10n.hpNewClaim),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
              ? const Center(child: Text('No claims yet'))
              : ListView.builder(
                  itemCount: _claims.length,
                  itemBuilder: (_, i) {
                    final c = _claims[i];
                    return ListTile(
                      title: Text('${c['title']}'),
                      subtitle: Text(
                          '${c['status']} · ₹${c['amountClaimed']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        RouteNames.hpClaimDetail
                            .replaceFirst(':id', '${c['id']}'),
                      ),
                    );
                  },
                ),
    );
  }
}

class HpClaimDetailScreen extends ConsumerStatefulWidget {
  const HpClaimDetailScreen({super.key, required this.claimId});
  final int claimId;
  @override
  ConsumerState<HpClaimDetailScreen> createState() =>
      _HpClaimDetailScreenState();
}

class _HpClaimDetailScreenState extends ConsumerState<HpClaimDetailScreen> {
  Map<String, dynamic>? _claim;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ref
          .read(healthProtectionServiceProvider)
          .getClaim(widget.claimId);
      if (!mounted) return;
      setState(() {
        _claim = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _upload(String type) async {
    final pick = await FilePicker.platform.pickFiles(withData: true);
    if (pick == null || pick.files.first.bytes == null) return;
    final f = pick.files.first;
    try {
      await ref.read(healthProtectionServiceProvider).uploadClaimDoc(
            claimId: widget.claimId,
            docType: type,
            bytes: f.bytes!,
            filename: f.name,
          );
      await _load();
      if (mounted) AppSnackbar.show(context, 'Uploaded $type', success: true);
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(healthProtectionServiceProvider)
          .submitClaim(widget.claimId);
      await _load();
    } catch (e) {
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeline = (_claim?['timeline'] as List?) ?? [];
    final docs = (_claim?['documents'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpClaimNumber('${widget.claimId}')),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.hpClaimStatus('${_claim?['status']}'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                if (_claim?['expectedSettlement'] != null)
                  Text(l10n.hpExpectedSettlement('${_claim!['expectedSettlement']}')),
                const SizedBox(height: 12),
                Text(l10n.hpUploadDocuments,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in [
                      'bill',
                      'prescription',
                      'discharge',
                      'report'
                    ])
                      ActionChip(
                          label: Text(t), onPressed: () => _upload(t)),
                  ],
                ),
                ...docs.map((d) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.attach_file),
                      title: Text('${(d as Map)['docType']}'),
                    )),
                const SizedBox(height: 8),
                FilledButton(
                    onPressed: _submit, child: Text(l10n.hpSubmitClaim)),
                const SizedBox(height: 16),
                Text(l10n.hpTimeline,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                ...timeline.map((t) {
                  final m = t as Map;
                  return ListTile(
                    leading: const Icon(Icons.timeline),
                    title: Text('${m['status']}'),
                    subtitle: Text('${m['note']}\n${m['at']}'),
                  );
                }),
              ],
            ),
    );
  }
}

class HpCashlessScreen extends ConsumerStatefulWidget {
  const HpCashlessScreen({super.key});
  @override
  ConsumerState<HpCashlessScreen> createState() => _HpCashlessScreenState();
}

class _HpCashlessScreenState extends ConsumerState<HpCashlessScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    double? lat;
    double? lng;
    try {
      final pos = await getUserLocation();
      lat = pos.lat;
      lng = pos.lon;
    } catch (_) {}
    try {
      final list = await ref
          .read(healthProtectionServiceProvider)
          .cashless(lat: lat, lng: lng);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _directions(Map h) async {
    final lat = h['lat'];
    final lng = h['lng'];
    if (lat == null || lng == null) return;
    await launchUrl(
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpCashlessHospitals),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final h = _items[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${h['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            '${h['address']} · ★ ${h['rating']}'
                            '${h['distanceKm'] != null ? ' · ${h['distanceKm']} km' : ''}'),
                        Text(
                            '${h['openNow'] == true ? 'Open now' : 'Closed'}'
                            '${h['emergency'] == true ? ' · Emergency' : ''}'),
                        Text(
                            'Accepted: ${((h['insurersAccepted'] as List?) ?? []).join(', ')}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                                onPressed: () => _call(h['phone']?.toString()),
                                child: Text(l10n.hpCall)),
                            OutlinedButton(
                                onPressed: () => _directions(h),
                                child: Text(l10n.hpDirections)),
                            FilledButton(
                              onPressed: () =>
                                  context.push(RouteNames.hospitals),
                              child: Text(l10n.hpBook),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class HpFamilyScreen extends ConsumerStatefulWidget {
  const HpFamilyScreen({super.key});
  @override
  ConsumerState<HpFamilyScreen> createState() => _HpFamilyScreenState();
}

class _HpFamilyScreenState extends ConsumerState<HpFamilyScreen> {
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref.read(healthProtectionServiceProvider).family();
    if (!mounted) return;
    setState(() => _members = list);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    String relation = 'Spouse';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        title: Text(l10n.hpAddFamilyMember),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            DropdownButtonFormField(
              value: relation,
              items: ['Father', 'Mother', 'Spouse', 'Child', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => relation = v ?? 'Other',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.hpAdd)),
        ],
      );
      },
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(healthProtectionServiceProvider).addFamily({
      'name': name.text.trim(),
      'relation': relation,
      'coverageAmount': 500000,
      'status': 'covered',
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpFamilyDashboard),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _members.isEmpty
          ? const Center(child: Text('No family members yet'))
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (_, i) {
                final m = _members[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${m['name']} (${m['relation']})'),
                  subtitle: Text(
                      '₹${m['coverageAmount']} · ${m['status']}'
                      '${m['renewalDate'] != null ? ' · Renew ${m['renewalDate']}' : ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(healthProtectionServiceProvider)
                          .deleteFamily(int.parse('${m['id']}'));
                      await _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class HpExpensesScreen extends ConsumerStatefulWidget {
  const HpExpensesScreen({super.key});
  @override
  ConsumerState<HpExpensesScreen> createState() => _HpExpensesScreenState();
}

class _HpExpensesScreenState extends ConsumerState<HpExpensesScreen> {
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _charts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(healthProtectionServiceProvider);
    final items = await svc.expenses();
    final charts = await svc.expenseCharts();
    if (!mounted) return;
    setState(() {
      _items = items;
      _charts = charts;
    });
  }

  Future<void> _add() async {
    final amount = TextEditingController();
    String category = 'doctor';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
        title: Text(l10n.hpAddExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: category,
              items: ['doctor', 'medicines', 'lab', 'hospital', 'claim', 'other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => category = v ?? 'other',
            ),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonSave)),
        ],
      );
      },
    );
    if (ok != true) return;
    await ref.read(healthProtectionServiceProvider).addExpense({
      'category': category,
      'amount': double.tryParse(amount.text) ?? 0,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pie = (_charts?['pie'] as List?) ?? [];
    final bar = (_charts?['bar'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpExpenseTracker),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'This month: ₹${_charts?['monthlyTotal'] ?? 0} · Year: ₹${_charts?['yearlyTotal'] ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(l10n.hpByCategory, style: TextStyle(fontWeight: FontWeight.w700)),
          ...pie.map((p) {
            final m = p as Map;
            return ListTile(
              dense: true,
              title: Text('${m['category']}'),
              trailing: Text('₹${m['amount']}'),
            );
          }),
          Text(l10n.hpMonthly, style: TextStyle(fontWeight: FontWeight.w700)),
          ...bar.map((b) {
            final m = b as Map;
            final amt = (m['amount'] as num?)?.toDouble() ?? 0;
            final max = bar
                .map((e) => ((e as Map)['amount'] as num?)?.toDouble() ?? 0)
                .fold<double>(1, (a, b) => a > b ? a : b);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m['month']} — ₹$amt'),
                  LinearProgressIndicator(value: (amt / max).clamp(0, 1)),
                ],
              ),
            );
          }),
          const Divider(),
          ..._items.map((e) => ListTile(
                title: Text('${e['category']} · ₹${e['amount']}'),
                subtitle: Text('${e['spentAt']}'),
              )),
        ],
      ),
    );
  }
}

class HpRiskScreen extends ConsumerStatefulWidget {
  const HpRiskScreen({super.key});
  @override
  ConsumerState<HpRiskScreen> createState() => _HpRiskScreenState();
}

class _HpRiskScreenState extends ConsumerState<HpRiskScreen> {
  final _age = TextEditingController(text: '35');
  final _bmi = TextEditingController(text: '24');
  final _sleep = TextEditingController(text: '7');
  bool _smoking = false;
  bool _familyHx = false;
  String _bp = 'normal';
  String _sugar = 'normal';
  String _exercise = 'moderate';
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _age.dispose();
    _bmi.dispose();
    _sleep.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final data = await ref.read(healthProtectionServiceProvider).computeRisk({
      'age': int.tryParse(_age.text) ?? 30,
      'bmi': double.tryParse(_bmi.text) ?? 22,
      'bloodPressure': _bp,
      'sugar': _sugar,
      'familyHistory': _familyHx,
      'smoking': _smoking,
      'exercise': _exercise,
      'sleepHours': double.tryParse(_sleep.text) ?? 7,
    });
    setState(() => _result = data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpMedicalRiskScore),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _age, decoration: InputDecoration(labelText: l10n.hpAge), keyboardType: TextInputType.number),
          TextField(controller: _bmi, decoration: const InputDecoration(labelText: 'BMI'), keyboardType: TextInputType.number),
          TextField(controller: _sleep, decoration: const InputDecoration(labelText: 'Sleep hours'), keyboardType: TextInputType.number),
          DropdownButtonFormField(value: _bp, decoration: const InputDecoration(labelText: 'Blood pressure'), items: ['normal', 'elevated', 'high'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _bp = v ?? 'normal')),
          DropdownButtonFormField(value: _sugar, decoration: const InputDecoration(labelText: 'Sugar'), items: ['normal', 'prediabetic', 'diabetic'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _sugar = v ?? 'normal')),
          DropdownButtonFormField(value: _exercise, decoration: const InputDecoration(labelText: 'Exercise'), items: ['none', 'low', 'moderate', 'high'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _exercise = v ?? 'moderate')),
          SwitchListTile(title: Text(l10n.hpSmoking), value: _smoking, onChanged: (v) => setState(() => _smoking = v)),
          SwitchListTile(title: Text(l10n.hpFamilyHistory), value: _familyHx, onChanged: (v) => setState(() => _familyHx = v)),
          FilledButton(onPressed: _run, child: Text(l10n.hpCalculateRisk)),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text(l10n.hpRiskLevel('${_result!['level']}', '${_result!['score']}'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ...(((_result!['recommendations'] as List?) ?? []).map((r) => Text('• $r'))),
          ],
        ],
      ),
    );
  }
}

class HpChatScreen extends ConsumerStatefulWidget {
  const HpChatScreen({super.key});
  @override
  ConsumerState<HpChatScreen> createState() => _HpChatScreenState();
}

class _HpChatScreenState extends ConsumerState<HpChatScreen> {
  final _ctrl = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final hist = await ref.read(healthProtectionServiceProvider).chatHistory();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(hist.map((m) => {
                'role': '${m['role']}',
                'content': '${m['content']}',
              }));
      });
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add({'role': 'user', 'content': text});
      _ctrl.clear();
    });
    try {
      final reply = await ref.read(healthProtectionServiceProvider).chat(text);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpInsuranceAiChat),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final mine = m['role'] == 'user';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: mine
                          ? AppColors.medcluesTeal
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: TextStyle(color: mine ? Colors.white : null),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Ask about coverage, claims…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HpAnalyticsScreen extends ConsumerStatefulWidget {
  const HpAnalyticsScreen({super.key});
  @override
  ConsumerState<HpAnalyticsScreen> createState() => _HpAnalyticsScreenState();
}

class _HpAnalyticsScreenState extends ConsumerState<HpAnalyticsScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ref.read(healthProtectionServiceProvider).analytics();
    if (!mounted) return;
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spend = _data?['healthSpending'] as Map?;
    final trend = (_data?['protectionScoreTrend'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hpProtectionAnalytics),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
      ),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _metric('Monthly spend', '₹${spend?['monthly'] ?? 0}'),
                _metric('Yearly spend', '₹${spend?['yearly'] ?? 0}'),
                _metric('Claim success rate', '${_data!['claimSuccessRate']}%'),
                _metric('Coverage utilization',
                    '${_data!['coverageUtilization']}%'),
                const SizedBox(height: 12),
                Text(l10n.hpScoreTrend,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                ...trend.map((t) {
                  final m = t as Map;
                  return ListTile(
                    dense: true,
                    title: Text(l10n.hpScorePoint('${m['score']}')),
                    subtitle: Text('${m['computedAt']}'),
                  );
                }),
              ],
            ),
    );
  }

  Widget _metric(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
