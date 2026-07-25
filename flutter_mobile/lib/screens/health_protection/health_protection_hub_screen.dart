import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../utils/theme_context.dart';

/// Clean Health Protection / insurance hub — theme-aware light & dark.
class HealthProtectionHubScreen extends ConsumerStatefulWidget {
  const HealthProtectionHubScreen({super.key});

  @override
  ConsumerState<HealthProtectionHubScreen> createState() =>
      _HealthProtectionHubScreenState();
}

class _HealthProtectionHubScreenState
    extends ConsumerState<HealthProtectionHubScreen> {
  Map<String, dynamic>? _hub;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(healthProtectionServiceProvider).hub();
      if (!mounted) return;
      setState(() {
        _hub = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _recompute() async {
    try {
      await ref.read(healthProtectionServiceProvider).recomputeScore();
      await _load();
    } catch (_) {}
  }

  int get _score {
    final s = _hub?['score'];
    if (s is Map) return int.tryParse('${s['score']}') ?? 0;
    return 0;
  }

  List get _suggestions {
    final s = _hub?['score'];
    if (s is Map && s['suggestions'] is List) return s['suggestions'] as List;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.hpTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _recompute,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recompute score',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [_HubShimmer()])
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 40, color: context.secondaryText),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: context.primaryText),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _load,
                                  child: Text(l10n.hpRetry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _StatusCard(
                        score: _score,
                        risk: '${_hub?['riskIndicator'] ?? 'Medium'}',
                        insuranceActive: _hub?['insuranceActive'] == true,
                        familyCount: int.tryParse(
                              '${_hub?['familyMembersCovered'] ?? 0}',
                            ) ??
                            0,
                        expiry: _hub?['policyExpiry']?.toString(),
                        daysRemaining: _hub?['daysRemaining'],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push(RouteNames.hpEmergencyCard),
                        icon: const Icon(Icons.badge_outlined),
                        label: Text(l10n.hpEmergencyCardQuick),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      if ((_hub?['daysRemaining'] is int) &&
                          (_hub!['daysRemaining'] as int) <= 45) ...[
                        const SizedBox(height: 12),
                        _RenewalBanner(
                          days: _hub!['daysRemaining'] as int,
                          onRemind: () async {
                            try {
                              await ref
                                  .read(healthProtectionServiceProvider)
                                  .renewalRemind();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(l10n.hpRenewalReminderSent)),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceFirst('Exception: ', '')),
                                  ),
                                );
                              }
                            }
                          },
                          onRenew: () =>
                              context.push(RouteNames.hpRecommend),
                        ),
                      ],
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.hpImproveScore,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.primaryText,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ..._suggestions.take(3).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 18,
                                      color: context.cs.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$s',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: context.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Main actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.primaryText,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _ActionTile(
                        icon: Icons.auto_awesome_outlined,
                        label: l10n.hpRecommendTitle,
                        subtitle: 'Find or improve coverage',
                        onTap: () => context.push(RouteNames.hpRecommend),
                      ),
                      _ActionTile(
                        icon: Icons.receipt_long_outlined,
                        label: l10n.hpClaims,
                        subtitle: 'Track and submit claims',
                        onTap: () => context.push(RouteNames.hpClaims),
                      ),
                      _ActionTile(
                        icon: Icons.family_restroom_outlined,
                        label: l10n.hpFamilyDashboard,
                        subtitle: 'People covered under you',
                        onTap: () => context.push(RouteNames.hpFamily),
                      ),
                      _ActionTile(
                        icon: Icons.local_hospital_outlined,
                        label: l10n.hpCashlessHospitals,
                        subtitle: 'Hospitals that accept cashless',
                        onTap: () => context.push(RouteNames.hpCashless),
                      ),
                      const SizedBox(height: 8),
                      _MoreTools(l10n: l10n),
                    ],
                  ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.score,
    required this.risk,
    required this.insuranceActive,
    required this.familyCount,
    required this.expiry,
    required this.daysRemaining,
  });

  final int score;
  final String risk;
  final bool insuranceActive;
  final int familyCount;
  final String? expiry;
  final dynamic daysRemaining;

  Color _riskColor(BuildContext context) {
    final r = risk.toLowerCase();
    if (r == 'high') return context.cs.error;
    if (r == 'medium') return context.cs.tertiary;
    return context.cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final riskColor = _riskColor(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: context.cardDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hpScoreLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insuranceActive ? 'Insurance active' : 'No active policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: insuranceActive
                        ? context.cs.primary
                        : context.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.hpFamilyCovered(familyCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryText,
                  ),
                ),
                if (expiry != null && expiry!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Expiry: $expiry'
                    '${daysRemaining != null ? ' ($daysRemaining days)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  l10n.hpRiskLabel(risk),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: (score.clamp(0, 100)) / 100,
                    strokeWidth: 7,
                    backgroundColor: context.borderColor.withValues(alpha: 0.35),
                    color: context.cs.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: context.cs.primary,
                    ),
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: context.primaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalBanner extends StatelessWidget {
  const _RenewalBanner({
    required this.days,
    required this.onRemind,
    required this.onRenew,
  });

  final int days;
  final VoidCallback onRemind;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bg = context.isDark
        ? context.cs.errorContainer.withValues(alpha: 0.35)
        : context.cs.errorContainer.withValues(alpha: 0.45);
    final fg = context.cs.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cs.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              days < 0
                  ? 'Policy expired — renew now'
                  : '$days days until renewal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          TextButton(
            onPressed: onRemind,
            child: Text(l10n.hpRemind),
          ),
          FilledButton(
            onPressed: onRenew,
            child: Text(l10n.hpRenew),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: context.cs.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreTools extends StatelessWidget {
  const _MoreTools({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String route})>[
      (icon: Icons.compare_arrows, label: l10n.hpCompareAction, route: RouteNames.hpCompare),
      (icon: Icons.verified_outlined, label: l10n.hpEligibility, route: RouteNames.hpEligibility),
      (icon: Icons.document_scanner_outlined, label: l10n.hpPolicyAnalyzer, route: RouteNames.hpAnalyze),
      (icon: Icons.pie_chart_outline, label: l10n.hpExpenseTracker, route: RouteNames.hpExpenses),
      (icon: Icons.monitor_heart_outlined, label: l10n.hpMedicalRiskScore, route: RouteNames.hpRisk),
      (icon: Icons.chat_bubble_outline, label: l10n.hpInsuranceAiChat, route: RouteNames.hpChat),
      (icon: Icons.analytics_outlined, label: l10n.hpProtectionAnalytics, route: RouteNames.hpAnalytics),
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: context.cardDecoration(radius: 14),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Icon(Icons.more_horiz, color: context.cs.primary),
          title: Text(
            'More tools',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.primaryText,
            ),
          ),
          subtitle: Text(
            'Compare, analyze, expenses, and more',
            style: TextStyle(fontSize: 12, color: context.secondaryText),
          ),
          children: [
            for (final item in items)
              ListTile(
                dense: true,
                leading: Icon(item.icon, color: context.secondaryText),
                title: Text(
                  item.label,
                  style: TextStyle(color: context.primaryText),
                ),
                trailing: Icon(Icons.chevron_right, color: context.iconMuted),
                onTap: () => context.push(item.route),
              ),
          ],
        ),
      ),
    );
  }
}

class _HubShimmer extends StatelessWidget {
  const _HubShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: context.skeletonBase,
        highlightColor: context.skeletonHighlight,
        child: Column(
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: context.skeletonLine,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.skeletonLine,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (_) => Container(
                height: 64,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: context.skeletonLine,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
