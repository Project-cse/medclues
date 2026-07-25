import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import 'medicine_widgets.dart';

class MedicineSearchScreen extends ConsumerStatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  ConsumerState<MedicineSearchScreen> createState() =>
      _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends ConsumerState<MedicineSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<MedicineCard> _results = [];
  List<String> _suggestions = [];
  List<String> _recent = [];
  List<String> _popular = [];
  List<String> _trending = [];

  bool _loadingMeta = true;
  bool _searching = false;
  bool _offline = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _offline = false;
    });
    try {
      final svc = ref.read(medicineServiceProvider);
      final results = await Future.wait([
        svc.recentSearches(),
        svc.popular(),
        svc.trending(),
      ]);
      if (!mounted) return;
      setState(() {
        _recent = results[0];
        _popular = results[1];
        _trending = results[2];
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      setState(() {
        _loadingMeta = false;
        _offline = msg.contains('socket') ||
            msg.contains('network') ||
            msg.contains('connection') ||
            msg.contains('failed host');
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    if (_query.length < 2) {
      setState(() {
        _suggestions = [];
        _results = [];
        _error = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final suggestions =
            await ref.read(medicineServiceProvider).autocomplete(_query);
        if (!mounted || _controller.text.trim() != _query) return;
        setState(() => _suggestions = suggestions);
      } catch (_) {
        // Suggestions are best-effort; full search still works.
      }
    });
  }

  Future<void> _runSearch([String? override]) async {
    final q = (override ?? _controller.text).trim();
    if (q.isEmpty) {
      setState(() => _error = 'Enter a medicine name to search');
      return;
    }
    if (q.length < 2) {
      setState(() => _error = 'Type at least 2 characters');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _controller.text = q;
      _query = q;
      _searching = true;
      _error = null;
      _offline = false;
      _suggestions = [];
    });
    try {
      final results = await ref.read(medicineServiceProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) {
          _error = 'No medicines found for "$q"';
        }
      });
      _loadMeta();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      setState(() {
        _searching = false;
        _results = [];
        _offline = lower.contains('socket') ||
            lower.contains('network') ||
            lower.contains('connection');
        _error = msg;
      });
    }
  }

  void _openDetails(MedicineCard card) {
    final name = card.brandName ?? card.genericName ?? card.medicineName;
    context.push(
      RouteNames.medicineDetail.replaceFirst(':name', Uri.encodeComponent(name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showIdle =
        _query.length < 2 && _results.isEmpty && !_searching && _error == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medicine Info'),
        backgroundColor: AppColors.medcluesNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _SearchHeader(
            controller: _controller,
            focusNode: _focus,
            onChanged: _onQueryChanged,
            onSubmit: () => _runSearch(),
            onVoiceTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice search is not available yet'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (_suggestions.isNotEmpty && _results.isEmpty && !_searching)
            _SuggestionStrip(
              suggestions: _suggestions,
              onTap: _runSearch,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_query.length >= 2) {
                  await _runSearch(_query);
                } else {
                  await _loadMeta();
                }
              },
              child: _buildBody(showIdle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool showIdle) {
    if (_searching) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(6, (_) => const _ShimmerCard()),
      );
    }
    if (_offline) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'You appear to be offline',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _error ?? 'Check your connection and try again',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () =>
                  _query.length >= 2 ? _runSearch(_query) : _loadMeta(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_results.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => MedicineResultCard(
          medicine: _results[i],
          onTap: () => _openDetails(_results[i]),
        ),
      );
    }
    if (_error != null && _query.length >= 2) {
      return ListView(
        children: [
          const SizedBox(height: 72),
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      );
    }
    if (showIdle) {
      if (_loadingMeta) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => const _ShimmerCard()),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_recent.isNotEmpty) ...[
            const _SectionTitle('Recent searches'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recent
                  .map(
                    (q) => ActionChip(
                      label: Text(q),
                      onPressed: () => _runSearch(q),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (_trending.isNotEmpty) ...[
            const _SectionTitle('Trending'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trending
                  .map(
                    (q) => ActionChip(
                      avatar: const Icon(Icons.trending_up, size: 16),
                      label: Text(q),
                      onPressed: () => _runSearch(q),
                      backgroundColor: const Color(0xFFFFF7ED),
                      side: const BorderSide(color: Color(0xFFFED7AA)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          const _SectionTitle('Popular medicines'),
          const SizedBox(height: 8),
          ..._popular.map(
            (q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(Icons.medication_outlined,
                    color: AppColors.medcluesTeal, size: 20),
              ),
              title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
              onTap: () => _runSearch(q),
            ),
          ),
          if (_popular.isEmpty && _recent.isEmpty) ...[
            const SizedBox(height: 48),
            Icon(Icons.biotech_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Search any medicine',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Warnings, ingredients, and label information\nfrom openFDA — for reference only.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onVoiceTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.medcluesNavy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: 'Search medicine name…',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.medcluesTeal),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.medcluesTeal,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onVoiceTap,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.mic_none_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ActionChip(
            label: Text(suggestions[i]),
            onPressed: () => onTap(suggestions[i]),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
