import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/financials_provider.dart';

class FinancialsScreen extends ConsumerStatefulWidget {
  const FinancialsScreen({super.key});

  @override
  ConsumerState<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends ConsumerState<FinancialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(financialsProvider.notifier).fetchStats();
      ref.read(financialsProvider.notifier).fetchExpenses();
      ref.read(financialsProvider.notifier).fetchInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financials',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your revenue, expenses, and invoices',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Cards
          if (state.stats != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Total Revenue',
                      value: '${state.stats!.totalRevenue.toStringAsFixed(0)} MAD',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Total Expenses',
                      value: '${state.stats!.totalExpenses.toStringAsFixed(0)} MAD',
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Net Profit',
                      value: '${state.stats!.netProfit.toStringAsFixed(0)} MAD',
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Expenses'),
                      Tab(text: 'Invoices'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Expenses Tab
                _buildExpensesList(context, state),
                // Invoices Tab
                _buildInvoicesList(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context, FinancialsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses recorded',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.expenses.length,
      itemBuilder: (context, index) {
        final expense = state.expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withAlpha(26),
              child: const Icon(Icons.receipt, color: Colors.red, size: 20),
            ),
            title: Text(expense.category),
            subtitle: Text(
              expense.description ?? DateFormat('MMM d, y').format(expense.date),
            ),
            trailing: Text(
              '-${expense.amount.toStringAsFixed(0)} MAD',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoicesList(BuildContext context, FinancialsState state) {
    if (state.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.invoices.length,
      itemBuilder: (context, index) {
        final invoice = state.invoices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withAlpha(26),
              child: const Icon(Icons.description, color: Colors.green, size: 20),
            ),
            title: Text('Invoice #${invoice.id.substring(0, 8)}'),
            subtitle: Text(DateFormat('MMM d, y').format(invoice.createdAt)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${invoice.amount.toStringAsFixed(0)} MAD',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(context, invoice.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  suffixText: 'MAD',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final data = {
                'amount': double.tryParse(amountController.text) ?? 0,
                'category': categoryController.text,
                'description': descriptionController.text,
                // Use RFC3339 format that Go expects: YYYY-MM-DDTHH:MM:SSZ
                'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00Z',
              };

              try {
                await ref.read(financialsProvider.notifier).createExpense(data);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
