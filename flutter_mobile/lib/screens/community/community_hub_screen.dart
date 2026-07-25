import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/service_providers.dart';
import '../../routes/route_names.dart';
import '../../services/community_service.dart';

class CommunityHubScreen extends ConsumerStatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  ConsumerState<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends ConsumerState<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _feed = [];
  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _saved = [];
  List<Map<String, dynamic>> _similar = [];
  List<Map<String, dynamic>> _archive = [];
  Map<String, dynamic>? _plus;
  bool _loading = true;
  String _sort = 'recent';

  CommunityService get _svc => ref.read(communityServiceProvider);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _loadTab(_tabs.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlus();
      _loadTab(0);
    });
  }

  Future<void> _loadPlus() async {
    try {
      final p = await _svc.plusStatus();
      if (mounted) setState(() => _plus = p);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    setState(() => _loading = true);
    try {
      if (index == 0) {
        _feed = await _svc.feed(sort: _sort);
      } else if (index == 1) {
        // search on demand
      } else if (index == 2) {
        _mine = await _svc.myQuestions();
      } else if (index == 3) {
        _saved = await _svc.bookmarks();
      } else {
        final res = await _svc.archive();
        _archive = (res['data'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    try {
      final res = await _svc.search(q);
      _similar = unwrapMaps(res['data'] ?? res['similar']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> unwrapMaps(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Community', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'Search'),
            Tab(text: 'My Questions'),
            Tab(text: 'Saved'),
            Tab(text: 'Knowledge'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.communityAsk),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Ask Question'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational discussions with verified doctors — not a substitute for consultation.',
                  style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (_plus != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _plus!['isPlus'] == true
                              ? 'Community Plus · ${_plus!['remainingToday']}/${_plus!['dailyLimit']} questions left today'
                              : 'Free · ${_plus!['remainingToday']}/${_plus!['dailyLimit']} question left today',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_plus!['isPlus'] != true)
                        TextButton(
                          onPressed: () async {
                            try {
                              await _svc.activatePlus();
                              await _loadPlus();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Community Plus activated')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          },
                          child: const Text('Get Plus'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildList(_feed, empty: 'No questions yet'),
                _buildSearch(cs),
                _buildList(_mine, empty: 'You have not asked anything yet'),
                _buildList(_saved, empty: 'No saved questions'),
                _buildList(_archive, empty: 'No resolved knowledge yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search symptoms, diseases, topics…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _runSearch,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList(_similar, empty: 'Search the knowledge base first')),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required String empty}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(empty, style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadTab(_tabs.index),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: items.length + (_tabs.index == 0 ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (_tabs.index == 0 && i == 0) {
            return Row(
              children: [
                ChoiceChip(
                  label: const Text('Recent'),
                  selected: _sort == 'recent',
                  onSelected: (_) {
                    setState(() => _sort = 'recent');
                    _loadTab(0);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Popular'),
                  selected: _sort == 'popular',
                  onSelected: (_) {
                    setState(() => _sort = 'popular');
                    _loadTab(0);
                  },
                ),
              ],
            );
          }
          final q = items[_tabs.index == 0 ? i - 1 : i];
          return _QuestionCard(
            question: q,
            onTap: () => context.push('/community/${q['id']}'),
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onTap});
  final Map<String, dynamic> question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${question['specialty'] ?? 'general'}'.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${question['status'] ?? ''}'.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                question['title']?.toString() ?? '',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                question['body']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                '${question['answerCount'] ?? 0} answers · ${question['viewCount'] ?? 0} views',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
