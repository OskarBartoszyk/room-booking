import 'package:flutter/material.dart';
import 'package:zpo/admin/admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń użytkownika'),
        content: Text('Czy na pewno chcesz usunąć użytkownika ${user['firstName']} ${user['lastName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(user['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Użytkownik został usunięty'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(Map<String, dynamic> user) async {
    final isAdmin = user['isAdmin'] ?? false;
    final newStatus = !isAdmin;

    try {
      await _adminService.toggleAdminStatus(user['id'], newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Nadano uprawnienia administratora' : 'Odebrano uprawnienia administratora'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(
        user: user,
        onSave: (updatedData) async {
          try {
            await _adminService.updateUser(user['id'], updatedData);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Użytkownik został zaktualizowany'),
                backgroundColor: Colors.green,
              ),
            );
            _loadUsers();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Błąd: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie użytkownikami'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Brak użytkowników',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isAdmin = user['isAdmin'] ?? false;
                        final createdAt = user['createdAt']?.toDate();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: isAdmin ? Colors.red : Colors.blue,
                                      child: Text(
                                        user['firstName']?.isNotEmpty == true
                                            ? user['firstName'][0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isAdmin) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'ADMIN',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            user['email'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (createdAt != null)
                                            Text(
                                              'Utworzono: ${_formatDate(createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _editUser(user),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edytuj'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _toggleAdminStatus(user),
                                      icon: Icon(
                                        isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                        size: 18,
                                      ),
                                      label: Text(isAdmin ? 'Usuń admin' : 'Nadaj admin'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: isAdmin ? Colors.orange : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _deleteUser(user),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Usuń'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onSave;

  const _EditUserDialog({
    required this.user,
    required this.onSave,
  });

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user['firstName'] ?? '';
    _lastNameController.text = widget.user['lastName'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj użytkownika'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Imię',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nazwisko',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedData = {
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'email': _emailController.text.trim(),
            };
            widget.onSave(updatedData);
            Navigator.pop(context);
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}