import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/service_providers.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.questionId});
  final int questionId;

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  Map<String, dynamic>? _question;
  List<Map<String, dynamic>> _answers = [];
  bool _loading = true;
  bool _bookmarked = false;
  final _followUp = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _followUp.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(communityServiceProvider).detail(widget.questionId);
      final q = Map<String, dynamic>.from(data['question'] as Map? ?? {});
      final answers = (data['answers'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          _question = q;
          _answers = answers;
          _bookmarked = q['bookmarked'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final svc = ref.read(communityServiceProvider);
    try {
      if (_bookmarked) {
        await svc.unbookmark(widget.questionId);
      } else {
        await svc.bookmark(widget.questionId);
      }
      setState(() => _bookmarked = !_bookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _sendFollowUp() async {
    final text = _followUp.text.trim();
    if (text.length < 10) return;
    try {
      await ref.read(communityServiceProvider).followUp(widget.questionId, text);
      _followUp.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _question;
    if (q == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Question not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${q['specialty'] ?? 'general'} · ${q['status'] ?? ''}'.toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(q['title']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(q['body']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 14, height: 1.45)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              q['disclaimer']?.toString() ??
                  'This information is for general educational purposes and should not replace a professional medical consultation.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.amber.shade900),
            ),
          ),
          const SizedBox(height: 20),
          Text('Answers', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          if (_answers.isEmpty)
            Text('No answers yet. Verified doctors will respond.', style: GoogleFonts.poppins(color: Colors.grey)),
          ..._answers.map((a) => _AnswerTile(
                answer: a,
                onHelpful: () async {
                  try {
                    await ref.read(communityServiceProvider).voteHelpful(a['id'] as int);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked helpful')),
                      );
                      _load();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
              )),
          const SizedBox(height: 16),
          TextField(
            controller: _followUp,
            decoration: const InputDecoration(
              labelText: 'Ask a follow-up',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _sendFollowUp, child: const Text('Post follow-up')),
          ),
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.answer, required this.onHelpful});
  final Map<String, dynamic> answer;
  final VoidCallback onHelpful;

  @override
  Widget build(BuildContext context) {
    final doctor = answer['doctor'] is Map
        ? Map<String, dynamic>.from(answer['doctor'] as Map)
        : null;
    final isDoctor = answer['authorRole'] == 'doctor';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDoctor ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDoctor && doctor != null) ...[
            Text(
              doctor['name']?.toString() ?? 'Doctor',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            Text(
              [
                doctor['specialty'],
                doctor['hospitalName'],
                if (doctor['experience'] != null) '${doctor['experience']} yrs',
              ].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 6),
          ] else
            Text(
              answer['patientName']?.toString() ?? 'Patient follow-up',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          Text(answer['body']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, height: 1.4)),
          if (answer['recommendEmergency'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('⚠ Seek emergency care', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          if (isDoctor && doctor?['id'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => context.push('/doctors/${doctor!['id']}'),
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push('/booking/${doctor!['id']}'),
                  child: const Text('Book Appointment'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onHelpful,
              icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
              label: Text('Helpful (${answer['helpfulCount'] ?? 0})'),
            ),
          ],
        ],
      ),
    );
  }
}
