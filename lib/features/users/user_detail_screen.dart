import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/chant_stats.dart';
import 'models/chanting_session.dart';
import 'user_detail_service.dart';
import 'user_model.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _service = UserDetailService();
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');
  ChantStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await _service.getChantStats(widget.user.uid);
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  String _parseLastActive(dynamic value) {
    if (value == null) return 'N/A';

    try {
      DateTime? dateTime;

      if (value is Timestamp) {
        dateTime = value.toDate();
      } else if (value is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        dateTime = DateTime.tryParse(value);
      }

      return dateTime != null ? _dateFormat.format(dateTime) : 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('User Details'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Basic Info Section
            _buildBasicInfoCard(cs, textTheme),
            const SizedBox(height: 16),

            // Chant Summary Section
            _buildChantSummaryCard(cs, textTheme),
            const SizedBox(height: 16),

            // Recent Activity Section
            _buildRecentActivityCard(cs, textTheme),
            const SizedBox(height: 16),

            // Admin Actions Section
            _buildAdminActionsCard(cs, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(ColorScheme cs, TextTheme textTheme) {
    final user = widget.user;
    final metadata = user.metadata ?? {};

    String initial = '?';
    final name = user.displayName?.trim() ?? '';
    final email = user.email.trim();

    if (name.isNotEmpty) {
      initial = name.substring(0, 1).toUpperCase();
    } else if (email.isNotEmpty) {
      initial = email.substring(0, 1).toUpperCase();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage:
                      user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Unknown User',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('UID', user.uid, cs),
            const SizedBox(height: 12),
            _buildInfoRow('Name', name.isNotEmpty ? name : 'N/A', cs),
            const SizedBox(height: 12),
            _buildInfoRow('Email', email, cs),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Platform',
              metadata['platform']?.toString() ?? 'N/A',
              cs,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'App Version',
              metadata['appVersion']?.toString() ?? 'N/A',
              cs,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Account Created',
              user.createdAt != null
                  ? _dateFormat.format(user.createdAt!)
                  : 'N/A',
              cs,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Last Active',
              _parseLastActive(metadata['lastActiveAt']),
              cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChantSummaryCard(ColorScheme cs, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chant Summary',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_stats != null)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Chants',
                      _stats!.totalChantCount.toString(),
                      Icons.auto_awesome,
                      cs.primaryContainer,
                      cs.onPrimaryContainer,
                      cs,
                      textTheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Today's Chants",
                      _stats!.todayChantCount.toString(),
                      Icons.today,
                      cs.secondaryContainer,
                      cs.onSecondaryContainer,
                      cs,
                      textTheme,
                    ),
                  ),
                ],
              ),
            if (!_isLoadingStats && _stats != null) const SizedBox(height: 12),
            if (!_isLoadingStats && _stats != null)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Current Streak',
                      '${_stats!.currentStreak} days',
                      Icons.local_fire_department,
                      cs.tertiaryContainer,
                      cs.onTertiaryContainer,
                      cs,
                      textTheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Longest Streak',
                      '${_stats!.longestStreak} days',
                      Icons.emoji_events,
                      cs.errorContainer,
                      cs.onErrorContainer,
                      cs,
                      textTheme,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(ColorScheme cs, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ChantingSession>>(
              stream: _service.getRecentSessions(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No recent activity',
                        style: textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        child: Icon(
                          Icons.self_improvement,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        session.mantra,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _dateFormat.format(session.startTime),
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Count: ${session.completedCount} • Duration: ${session.formattedDuration}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: session.status.toLowerCase() == 'completed'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: session.status.toLowerCase() == 'completed'
                                ? Colors.green.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          session.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: session.status.toLowerCase() == 'completed'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionsCard(ColorScheme cs, TextTheme textTheme) {
    final metadata = widget.user.metadata ?? {};
    final accountStatus = metadata['accountStatus']?.toString() ?? 'active';
    final isBlocked = accountStatus.toLowerCase() == 'blocked';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => _handleBlockUnblock(isBlocked),
                  icon: Icon(isBlocked ? Icons.check_circle : Icons.block),
                  label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isBlocked ? Colors.green : Colors.red,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _handleResetStreak,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Streak'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _handleViewFullHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('View Full History'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color fgColor,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: fgColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBlockUnblock(bool isCurrentlyBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          isCurrentlyBlocked
              ? 'Are you sure you want to unblock this user?'
              : 'Are you sure you want to block this user? They will not be able to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isCurrentlyBlocked ? Colors.green : Colors.red,
            ),
            child: Text(isCurrentlyBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.updateAccountStatus(
          widget.user.uid,
          isCurrentlyBlocked ? 'active' : 'blocked',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isCurrentlyBlocked
                    ? 'User unblocked successfully'
                    : 'User blocked successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleResetStreak() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Streak'),
        content: const Text(
          'Are you sure you want to reset this user\'s current streak to 0? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.resetStreak(widget.user.uid);
        await _loadStats(); // Reload stats to show updated value
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Streak reset successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleViewFullHistory() {
    // TODO: Navigate to full session history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full history view - Coming soon')),
    );
  }
}
