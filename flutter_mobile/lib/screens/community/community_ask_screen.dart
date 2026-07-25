import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';

class CommunityAskScreen extends ConsumerStatefulWidget {
  const CommunityAskScreen({super.key});

  @override
  ConsumerState<CommunityAskScreen> createState() => _CommunityAskScreenState();
}

class _CommunityAskScreenState extends ConsumerState<CommunityAskScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _similar = [];
  String _specialty = 'general';
  bool _loading = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final cats = await ref.read(communityServiceProvider).categories();
        if (mounted) setState(() => _categories = cats);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _previewSimilar() async {
    final t = _title.text.trim();
    if (t.length < 8) return;
    setState(() => _checking = true);
    try {
      final res = await ref.read(communityServiceProvider).search(t);
      final list = (res['data'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      if (mounted) setState(() => _similar = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit({bool force = false}) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(communityServiceProvider).ask(
            title: _title.text.trim(),
            body: _body.text.trim(),
            specialty: _specialty,
            force: force,
          );
      if (res['success'] == true) {
        if (!mounted) return;
        final id = res['data']?['id'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question published')),
        );
        if (id != null) {
          context.go('/community/$id');
        } else {
          context.go(RouteNames.community);
        }
        return;
      }
      if (res['code'] == 'SIMILAR_FOUND') {
        final list = (res['similar'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        setState(() => _similar = list);
        if (!mounted) return;
        final still = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Similar questions found'),
            content: const Text(
              'Review similar discussions first. Still want to ask your own question?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('View existing')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Still ask')),
            ],
          ),
        );
        if (still == true) {
          await _submit(force: true);
        }
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Could not post')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ask a Question', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Search existing answers first. Limit: 1 new question per day.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Question title',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _previewSimilar(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Describe symptoms / question',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _specialty,
            decoration: const InputDecoration(
              labelText: 'Specialty (optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in _categories)
                DropdownMenuItem(
                  value: c['id']?.toString() ?? 'general',
                  child: Text(c['label']?.toString() ?? c['id']?.toString() ?? ''),
                ),
              if (_categories.isEmpty)
                const DropdownMenuItem(value: 'general', child: Text('General')),
            ],
            onChanged: (v) => setState(() => _specialty = v ?? 'general'),
          ),
          if (_checking) const LinearProgressIndicator(),
          if (_similar.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Similar questions', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._similar.take(5).map(
              (q) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(q['title']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text('${q['answerCount'] ?? 0} answers'),
                onTap: () => context.push('/community/${q['id']}'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : () => _submit(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Question'),
          ),
        ],
      ),
    );
  }
}
