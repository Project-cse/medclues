import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/saved_profile.dart';
import '../../providers/saved_profiles_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_snackbar.dart';

class SavedProfilesScreen extends ConsumerWidget {
  const SavedProfilesScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    SavedProfile? existing,
  ]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SavedProfileDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    try {
      final service = ref.read(savedProfileServiceProvider);
      if (existing == null) {
        await service.create(result);
      } else {
        await service.update(existing.id, result);
      }
      ref.invalidate(savedProfilesProvider);
      if (context.mounted) {
        AppSnackbar.show(context, 'Profile saved', success: true);
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.show(
            context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SavedProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved profile?'),
        content: Text('Remove ${profile.name} from your saved profiles?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(savedProfileServiceProvider).delete(profile.id);
      ref.invalidate(savedProfilesProvider);
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.show(
            context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(savedProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved patient profiles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add profile'),
      ),
      body: profiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(savedProfilesProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No saved profiles yet'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(savedProfilesProvider);
                  await ref.read(savedProfilesProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profile = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.person_outline)),
                        title: Text(profile.name),
                        subtitle: Text(
                          '${profile.relationship} • Age ${profile.age}'
                          '${profile.phone.isEmpty ? '' : '\n${profile.phone}'}',
                        ),
                        isThreeLine: profile.phone.isNotEmpty,
                        onTap: () => _edit(context, ref, profile),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, ref, profile),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _SavedProfileDialog extends StatefulWidget {
  const _SavedProfileDialog({this.existing});

  final SavedProfile? existing;

  @override
  State<_SavedProfileDialog> createState() => _SavedProfileDialogState();
}

class _SavedProfileDialogState extends State<_SavedProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _phone;
  late String _gender;
  late String _relationship;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _relationships = [
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Spouse',
    'Son',
    'Daughter',
    'Guardian',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name);
    _age = TextEditingController(text: p?.age);
    _phone = TextEditingController(text: p?.phone);
    _gender = _genders.contains(p?.gender) ? p!.gender : _genders.first;
    _relationship = _relationships.contains(p?.relationship)
        ? p!.relationship
        : _relationships.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'age': _age.text.trim(),
      'phone': _phone.text.trim(),
      'gender': _gender,
      'relationship': _relationship,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Add patient profile'
          : 'Edit patient profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Enter a valid name' : null,
              ),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (v) {
                  final age = int.tryParse((v ?? '').trim());
                  return age == null || age < 0 || age > 120
                      ? 'Enter a valid age'
                      : null;
                },
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) =>
                    RegExp(r'^[6-9]\d{9}$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Enter a valid 10-digit phone',
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genders
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? _gender),
              ),
              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                items: _relationships
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _relationship = v ?? _relationship),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
