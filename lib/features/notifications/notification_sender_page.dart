import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class NotificationSenderPage extends StatefulWidget {
  const NotificationSenderPage({super.key});

  @override
  State<NotificationSenderPage> createState() => _NotificationSenderPageState();
}

class _NotificationSenderPageState extends State<NotificationSenderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _target = 'all';
  bool _sending = false;
  String? _statusMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _statusMessage = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendAdminNotification');

      final result = await callable.call(<String, dynamic>{
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'target': _target,
      });

      final data = result.data as Map<dynamic, dynamic>;
      final targetCount = data['targetCount'] ?? 0;
      final successCount = data['successCount'] ?? 0;
      final failureCount = data['failureCount'] ?? 0;

      setState(() {
        _statusMessage =
            'Sent to $targetCount devices. Success: $successCount, Failed: $failureCount.';
      });
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to send notification.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to send notification.')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send push notification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Title is required.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _target,
                      decoration: const InputDecoration(
                        labelText: 'Target',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All users'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactive users (7d)'),
                        ),
                      ],
                      onChanged: _sending
                          ? null
                          : (value) => setState(() => _target = value ?? 'all'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Body is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send notification'),
                    ),
                    const SizedBox(width: 12),
                    if (_statusMessage != null)
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

