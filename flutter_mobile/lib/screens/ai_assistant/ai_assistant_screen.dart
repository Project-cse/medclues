import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../constants/app_colors.dart';
import '../../config/api_config.dart';
import '../../providers/service_providers.dart';
import '../../utils/theme_context.dart';

String speechLocaleId(String language) {
  switch (language) {
    case 'hi':
      return 'hi_IN';
    case 'te':
      return 'te_IN';
    default:
      return 'en_IN';
  }
}

String ttsLocale(String language) {
  switch (language) {
    case 'hi':
      return 'hi-IN';
    case 'te':
      return 'te-IN';
    default:
      return 'en-IN';
  }
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_AssistantMessage>[];
  final _sessionId = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
  final FlutterTts _tts = FlutterTts();

  bool _checkingStatus = true;
  bool _enabled = false;
  bool _sending = false;
  bool _speakReplies = false;
  String _language = 'en';
  String? _disclaimer;
  Map<String, dynamic>? _pendingConfirmation;
  String? _lastIntent;
  String? _lastTool;

  static const _suggestions = <String>[
    'Find a dermatologist',
    'Show my appointments today',
    'Cancel my appointment',
    'Open Pharmacy',
    'I need a CBC test',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadStatus();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setLanguage(ttsLocale(_language));
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!_speakReplies || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(ttsLocale(_language));
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _loadStatus() async {
    try {
      final result = await ref.read(aiAssistantServiceProvider).status();
      if (!mounted) return;
      final enabled = result['enabled'] == true;
      setState(() {
        _enabled = enabled;
        _disclaimer = result['disclaimer']?.toString();
        _checkingStatus = false;
        _messages.add(
          _AssistantMessage(
            text: enabled
                ? 'Hello! I can help with doctors, appointments, pharmacy, '
                    'laboratory, payments, Medical Community, and support tickets.'
                : 'The MedClues AI Assistant is currently unavailable. '
                    'Please restart the backend after enabling it.',
            fromUser: false,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingStatus = false;
        _messages.add(_AssistantMessage(
          text: 'Could not connect to the AI Assistant. Check that the '
              'MEDCLUES backend is reachable at ${ApiConfig.baseUrl}.',
          fromUser: false,
          isError: true,
        ));
      });
    }
  }

  Future<void> _send([String? suggestedText]) async {
    final text = (suggestedText ?? _controller.text).trim();
    if (text.isEmpty || _sending || !_enabled) return;

    await _tts.stop();
    _controller.clear();
    setState(() {
      _sending = true;
      _pendingConfirmation = null;
      _messages.add(_AssistantMessage(text: text, fromUser: true));
    });
    _scrollToBottom();

    try {
      final result = await ref.read(aiAssistantServiceProvider).chat(
            message: text,
            sessionId: _sessionId,
          );
      if (!mounted) return;

      final toolResult = result['toolResult'];
      Map<String, dynamic>? pending;
      if (toolResult is Map && toolResult['needsConfirm'] == true) {
        pending = {
          'tool': result['tool']?.toString(),
          'args': Map<String, dynamic>.from(
            (toolResult['proposedArgs'] as Map?) ?? const {},
          ),
        };
      }
      final ui = result['ui'];
      if (pending == null &&
          ui is Map &&
          ui['type'] == 'confirmation' &&
          ui['tool'] != null) {
        pending = {
          'tool': ui['tool'].toString(),
          'args': Map<String, dynamic>.from(
            (ui['args'] as Map?) ?? const {},
          ),
        };
      }

      final replyText = result['reply']?.toString() ??
          result['message']?.toString() ??
          'I could not complete that request.';
      final lang = result['language']?.toString();
      setState(() {
        if (lang == 'hi' || lang == 'te' || lang == 'en') {
          _language = lang!;
        }
        _pendingConfirmation = pending;
        _lastIntent = result['intent']?.toString();
        _lastTool = result['tool']?.toString();
        _messages.add(_AssistantMessage(
          text: replyText,
          fromUser: false,
          isError: result['success'] == false,
          intent: result['intent']?.toString(),
          tool: result['tool']?.toString(),
          ui: result['ui'] is Map
              ? Map<String, dynamic>.from(result['ui'] as Map)
              : null,
        ));
      });
      await _speak(replyText);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _AssistantMessage(
          text:
              'The request failed. Check your connection and login, then try again.',
          fromUser: false,
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _confirmPending() async {
    final pending = _pendingConfirmation;
    final tool = pending?['tool']?.toString();
    if (pending == null || tool == null || tool.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _pendingConfirmation = null;
      _messages.add(const _AssistantMessage(
        text: 'Confirm action',
        fromUser: true,
      ));
    });

    try {
      final result = await ref.read(aiAssistantServiceProvider).confirm(
            tool: tool,
            toolArgs: Map<String, dynamic>.from(
              (pending['args'] as Map?) ?? const {},
            ),
            sessionId: _sessionId,
          );
      if (!mounted) return;
      final replyText = result['reply']?.toString() ??
          result['message']?.toString() ??
          'Action completed.';
      setState(() {
        _lastIntent = result['intent']?.toString();
        _lastTool = result['tool']?.toString();
        _messages.add(_AssistantMessage(
          text: replyText,
          fromUser: false,
          isError: result['success'] == false,
          intent: result['intent']?.toString(),
          tool: result['tool']?.toString(),
          ui: result['ui'] is Map
              ? Map<String, dynamic>.from(result['ui'] as Map)
              : null,
        ));
      });
      await _speak(replyText);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _AssistantMessage(
          text:
              'The action could not be completed. No changes were assumed.',
          fromUser: false,
          isError: true,
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendFeedback(int rating) async {
    try {
      await ref.read(aiAssistantServiceProvider).feedback(
            rating: rating,
            sessionId: _sessionId,
            intent: _lastIntent,
            tool: _lastTool,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rating > 0
                ? 'Thanks for the feedback.'
                : 'Thanks — we will improve this.',
          ),
        ),
      );
    } catch (_) {}
  }

  void _openRoute(String route) {
    if (route.isEmpty) return;
    context.push(route);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.medcluesTeal, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'MedClues Assistant',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _speakReplies ? 'Mute spoken replies' : 'Speak replies',
            onPressed: () {
              setState(() => _speakReplies = !_speakReplies);
              if (!_speakReplies) {
                _tts.stop();
              }
            },
            icon: Icon(
              _speakReplies
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'en':
                case 'hi':
                case 'te':
                  setState(() => _language = value);
                  _tts.setLanguage(ttsLocale(value));
                  break;
                case 'helpful':
                  _sendFeedback(1);
                  break;
                case 'not_helpful':
                  _sendFeedback(-1);
                  break;
                case 'safety':
                  _showSafety(context);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'en',
                child: Text(
                  _language == 'en' ? 'Language: English ✓' : 'Language: English',
                ),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text(
                  _language == 'hi' ? 'Language: Hindi ✓' : 'Language: Hindi',
                ),
              ),
              PopupMenuItem(
                value: 'te',
                child: Text(
                  _language == 'te' ? 'Language: Telugu ✓' : 'Language: Telugu',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'helpful',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.thumb_up_alt_outlined),
                  title: Text('Helpful'),
                ),
              ),
              const PopupMenuItem(
                value: 'not_helpful',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.thumb_down_alt_outlined),
                  title: Text('Not helpful'),
                ),
              ),
              const PopupMenuItem(
                value: 'safety',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Medical safety'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _SafetyBanner(disclaimer: _disclaimer),
          Expanded(
            child: _checkingStatus
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) => _MessageBubble(
                      message: _messages[index],
                      onSelect: _send,
                      onOpenRoute: _openRoute,
                    ),
                  ),
          ),
          if (!_checkingStatus && _messages.length <= 1 && _enabled)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ActionChip(
                  label: Text(_suggestions[index]),
                  onPressed: () => _send(_suggestions[index]),
                ),
              ),
            ),
          if (_pendingConfirmation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                onPressed: _sending ? null : _confirmPending,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm action'),
              ),
            ),
          _Composer(
            controller: _controller,
            enabled: _enabled && !_sending,
            sending: _sending,
            speechLocale: speechLocaleId(_language),
            onSend: () => _send(),
            onVoiceText: (text) => _send(text),
          ),
        ],
      ),
    );
  }

  void _showSafety(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Medical safety'),
        content: Text(
          _disclaimer ??
              'This assistant does not diagnose, prescribe medicines, or replace a doctor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({this.disclaimer});

  final String? disclaimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.highlightBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.medcluesTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              disclaimer ??
                  'Navigation and workflow assistance only — not medical diagnosis.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onVoiceText,
    required this.speechLocale,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;
  final ValueChanged<String> onVoiceText;
  final String speechLocale;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _available = false;
  bool _checked = false;

  Future<void> _ensureReady() async {
    if (_checked) return;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted && !mic.isLimited) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input.')),
        );
      }
      _checked = true;
      _available = false;
      return;
    }
    _available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    _checked = true;
  }

  Future<void> _toggleListen() async {
    if (!widget.enabled || widget.sending) return;
    await _ensureReady();
    if (!_available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available on this device.')),
        );
      }
      return;
    }
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final preferred = widget.speechLocale;
    final locales = await _speech.locales();
    final match = locales.where(
      (l) =>
          l.localeId == preferred ||
          l.localeId.replaceAll('-', '_') == preferred ||
          l.localeId.toLowerCase().startsWith(preferred.split('_').first.toLowerCase()),
    );
    final localeId = match.isNotEmpty ? match.first.localeId : preferred;
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        widget.controller.text = text;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        if (result.finalResult) {
          setState(() => _listening = false);
          widget.onVoiceText(text);
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: localeId,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: _listening ? 'Stop listening' : 'Voice input',
              onPressed: widget.enabled ? _toggleListen : null,
              icon: Icon(
                _listening ? Icons.mic : Icons.mic_none_outlined,
                color: _listening ? AppColors.medcluesTeal : null,
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.enabled ? (_) => widget.onSend() : null,
                decoration: InputDecoration(
                  hintText: _listening
                      ? 'Listening…'
                      : 'Ask MedClues or request an action…',
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: widget.enabled ? widget.onSend : null,
              icon: widget.sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onSelect,
    required this.onOpenRoute,
  });

  final _AssistantMessage message;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final user = message.fromUser;
    final color = user
        ? AppColors.medcluesTeal
        : message.isError
            ? Theme.of(context).colorScheme.errorContainer
            : context.cardColor;
    final textColor = user
        ? Colors.white
        : message.isError
            ? Theme.of(context).colorScheme.onErrorContainer
            : context.primaryText;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: user ? null : Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(color: textColor, height: 1.4),
            ),
            if (!user && message.ui != null) ...[
              const SizedBox(height: 10),
              _StructuredAssistantResult(
                data: message.ui!,
                onSelect: onSelect,
                onOpenRoute: onOpenRoute,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StructuredAssistantResult extends StatelessWidget {
  const _StructuredAssistantResult({
    required this.data,
    required this.onSelect,
    required this.onOpenRoute,
  });

  final Map<String, dynamic> data;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString();
    if (type == 'profile') {
      final profile = Map<String, dynamic>.from(
        (data['profile'] as Map?) ?? const {},
      );
      return _ResultCard(
        icon: Icons.person_outline,
        title: profile['name']?.toString() ?? 'Patient',
        subtitle: 'Your authenticated MEDCLUES profile',
      );
    }

    if (type == 'confirmation' || type == 'bookingReceipt') {
      final details = Map<String, dynamic>.from(
        (data['details'] as Map?) ?? const {},
      );
      return _ResultCard(
        icon: type == 'bookingReceipt'
            ? Icons.check_circle_outline
            : Icons.fact_check_outlined,
        title: data['title']?.toString() ??
            (type == 'bookingReceipt' ? 'Appointment booked' : 'Confirm action'),
        subtitle: [
          details['doctor'] ?? details['specialty'],
          details['date'] ?? details['requestedDate'] ?? details['slotDate'],
          details['time'] ?? details['slotTime'],
          if (details['bookingId'] != null) 'Booking ${details['bookingId']}',
          if (details['tokenNumber'] != null) 'Token ${details['tokenNumber']}',
        ].where((value) => value != null).join(' · '),
      );
    }

    if (type == 'education') {
      final bullets = ((data['bullets'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final actions = ((data['actions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultCard(
            icon: Icons.menu_book_outlined,
            title: data['title']?.toString() ?? 'Health information',
            subtitle: bullets.isEmpty
                ? (data['disclaimer']?.toString() ?? '')
                : bullets.take(2).join('\n\n'),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((item) {
                final label = item['label']?.toString() ?? 'Continue';
                final message = item['message']?.toString() ?? label;
                return ActionChip(
                  avatar: const Icon(Icons.event_available, size: 16),
                  label: Text(label),
                  onPressed: () => onSelect(message),
                );
              }).toList(),
            ),
          ],
        ],
      );
    }

    final items = ((data['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    if (type == 'actions') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final label = item['label']?.toString() ?? 'Open';
          final route = item['route']?.toString() ?? '';
          return ActionChip(
            avatar: const Icon(Icons.open_in_new, size: 16),
            label: Text(label),
            onPressed: route.isEmpty ? null : () => onOpenRoute(route),
          );
        }).toList(),
      );
    }

    if (type == 'appointments') {
      return Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final doctor = Map<String, dynamic>.from(
            (item['docData'] as Map?) ?? const {},
          );
          final status = item['lifecycleStatus'] ??
              item['status'] ??
              (item['cancelled'] == true ? 'Cancelled' : 'Booked');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect('${index + 1}'),
              child: _ResultCard(
                icon: Icons.calendar_today_outlined,
                title:
                    '${index + 1}. ${doctor['name'] ?? item['doctor'] ?? 'Doctor appointment'}',
                subtitle:
                    '${item['slotDate'] ?? ''} ${item['slotTime'] ?? 'Time unavailable'} · $status',
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        }),
      );
    }

    if (type == 'payments') {
      return Column(
        children: items.take(5).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultCard(
              icon: Icons.payments_outlined,
              title: item['doctor_name']?.toString() ??
                  item['order_id']?.toString() ??
                  'Payment',
              subtitle:
                  '₹${item['amount_inr'] ?? item['amount'] ?? 0} · ${item['status'] ?? ''}',
            ),
          );
        }).toList(),
      );
    }

    if (type == 'hospitals') {
      return Column(
        children: items.take(5).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultCard(
              icon: Icons.local_hospital_outlined,
              title: item['name']?.toString() ?? 'Hospital',
              subtitle: item['address']?.toString() ??
                  item['location']?.toString() ??
                  '',
            ),
          );
        }).toList(),
      );
    }

    if (type == 'doctors') {
      return Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(item['name']?.toString() ?? '${index + 1}'),
              child: _ResultCard(
                icon: Icons.medical_services_outlined,
                title: '${index + 1}. ${item['name'] ?? 'Doctor'}',
                subtitle: [
                  item['speciality'],
                  if (item['fees'] != null) '₹${item['fees']}',
                ].where((value) => value != null).join(' · '),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        }),
      );
    }

    if (type == 'slots') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final time = item['displayTime']?.toString() ??
              item['time']?.toString() ??
              '${index + 1}';
          return ActionChip(
            avatar: const Icon(Icons.schedule, size: 17),
            label: Text(time),
            onPressed: () => onSelect(time),
          );
        }),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.highlightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.medcluesTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _AssistantMessage {
  const _AssistantMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
    this.ui,
    this.intent,
    this.tool,
  });

  final String text;
  final bool fromUser;
  final bool isError;
  final Map<String, dynamic>? ui;
  final String? intent;
  final String? tool;
}
