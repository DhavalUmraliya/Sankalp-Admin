import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'user_model.dart';
import 'users_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _service = UsersService();
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Users Management',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Implement invite/add user
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: StreamBuilder<List<AppUser>>(
              stream: _service.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final users = snapshot.data!;
                if (users.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No users found.'),
                    ),
                  );
                }

                return PaginatedDataTable(
                  header: const Text('Registered Users'),
                  columns: const [
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Joined')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: _UsersDataSource(users, context, _dateFormat),
                  rowsPerPage: 10,
                  showCheckboxColumn: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersDataSource extends DataTableSource {
  final List<AppUser> _users;
  final BuildContext _context;
  final DateFormat _dateFormat;

  _UsersDataSource(this._users, this._context, this._dateFormat);

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    final cs = Theme.of(_context).colorScheme;

    String initial = '?';
    final name = user.displayName?.trim() ?? '';
    final email = user.email.trim();

    if (name.isNotEmpty) {
      initial = name.substring(0, 1).toUpperCase();
    } else if (email.isNotEmpty) {
      initial = email.substring(0, 1).toUpperCase();
    }

    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
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
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  name.isNotEmpty
                      ? name
                      : (email.isNotEmpty ? email : 'Unknown'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.role == 'admin'
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: user.role == 'admin'
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.green.withOpacity(0.5),
              ),
            ),
            child: Text(
              (user.role ?? 'User').toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: user.role == 'admin' ? Colors.blue : Colors.green,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            user.createdAt != null ? _dateFormat.format(user.createdAt!) : '-',
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: context menu
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;
}
