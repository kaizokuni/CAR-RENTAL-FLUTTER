import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/staff_provider.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(staffProvider.notifier).fetchStaff();
      ref.read(staffProvider.notifier).fetchRoles();
    });
  }

  List<StaffMember> get filteredStaff {
    final staff = ref.watch(staffProvider).staff;
    if (_searchQuery.isEmpty) return staff;
    return staff.where((s) =>
      s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staffState.staff.length} team members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddStaffDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Staff'),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search staff by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 24),

          // Staff List
          Expanded(
            child: staffState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : staffState.error != null
                    ? Center(child: Text('Error: ${staffState.error}'))
                    : filteredStaff.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No staff members found',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredStaff.length,
                            itemBuilder: (context, index) {
                              final staff = filteredStaff[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                                    child: Text(
                                      staff.firstName.isNotEmpty 
                                          ? staff.firstName[0].toUpperCase() 
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    staff.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(staff.email),
                                      if (staff.roleName != null)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withAlpha(26),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            staff.roleName!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditStaffDialog(context, staff);
                                      } else if (value == 'delete') {
                                        _confirmDelete(context, staff);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                                            const SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    _showStaffFormDialog(context, null);
  }

  void _showEditStaffDialog(BuildContext context, StaffMember staff) {
    _showStaffFormDialog(context, staff);
  }

  void _showStaffFormDialog(BuildContext context, StaffMember? staff) {
    final isEditing = staff != null;
    final firstNameController = TextEditingController(text: staff?.firstName ?? '');
    final lastNameController = TextEditingController(text: staff?.lastName ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    final passwordController = TextEditingController();
    String? selectedRoleId = staff?.roleId;
    final roles = ref.read(staffProvider).roles;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Staff' : 'Add Staff Member'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name *'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isEditing ? 'New Password (optional)' : 'Password *',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (roles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedRoleId,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: roles.map((role) => DropdownMenuItem(
                        value: role.id,
                        child: Text(role.name),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedRoleId = value);
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{
                  'first_name': firstNameController.text,
                  'last_name': lastNameController.text,
                  'email': emailController.text,
                };
                
                if (passwordController.text.isNotEmpty) {
                  data['password'] = passwordController.text;
                }
                
                if (selectedRoleId != null) {
                  data['role_id'] = selectedRoleId;
                }

                try {
                  if (isEditing) {
                    await ref.read(staffProvider.notifier).updateStaff(staff.id, data);
                  } else {
                    await ref.read(staffProvider.notifier).createStaff(data);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, StaffMember staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Are you sure you want to delete ${staff.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await ref.read(staffProvider.notifier).deleteStaff(staff.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
