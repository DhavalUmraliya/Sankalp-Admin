import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/admin_shell_page.dart';
import 'admin_auth_service.dart';
import 'admin_login_page.dart';

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  final _service = AdminAuthService();

  String? _checkedUid;
  Future<bool>? _isAdminFuture;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(label: 'Checking session…');
        }

        final user = snap.data;
        if (user == null) {
          _checkedUid = null;
          _isAdminFuture = null;
          return const AdminLoginPage();
        }

        if (_checkedUid != user.uid || _isAdminFuture == null) {
          _checkedUid = user.uid;
          _isAdminFuture = _service.isUidAdmin(user.uid);
        }

        return FutureBuilder<bool>(
          future: _isAdminFuture,
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScaffold(label: 'Verifying admin access…');
            }

            if (roleSnap.hasError) {
              return _BlockedScaffold(
                title: 'Unable to verify admin access',
                message: 'Please try again.',
                actionLabel: 'Sign out',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            final isAdmin = roleSnap.data == true;
            if (!isAdmin) {
              // Ensure non-admins can’t stay signed in.
              FirebaseAuth.instance.signOut();
              return const _BlockedScaffold(
                title: 'Access denied',
                message: 'Your account is not an admin.',
                actionLabel: 'Back to login',
              );
            }

            return const AdminShellPage();
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _BlockedScaffold extends StatelessWidget {
  const _BlockedScaffold({
    required this.title,
    required this.message,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onAction ?? () => FirebaseAuth.instance.signOut(),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

