import 'package:flutter/material.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:totals/widgets/analytics/transactions_list.dart';
import 'package:totals/widgets/categorize_transaction_sheet.dart';
import 'package:totals/widgets/category_filter_button.dart';
import 'package:totals/widgets/category_filter_sheet.dart';

class TransactionsForPeriodPage extends StatefulWidget {
  final List<Transaction> transactions;
  final TransactionProvider provider;
  final String title;
  final String? subtitle;

  const TransactionsForPeriodPage({
    super.key,
    required this.transactions,
    required this.provider,
    required this.title,
    this.subtitle,
  });

  @override
  State<TransactionsForPeriodPage> createState() =>
      _TransactionsForPeriodPageState();
}

class _TransactionsForPeriodPageState extends State<TransactionsForPeriodPage> {
  String _sortBy = 'Date';
  Set<int?> _selectedCategoryIds = {};

  Transaction? _findUpdatedTransaction(
    Transaction original,
    List<Transaction> updatedTransactions,
  ) {
    for (final transaction in updatedTransactions) {
      if (transaction.reference != original.reference) continue;
      if (transaction.time != original.time) continue;
      if (transaction.amount != original.amount) continue;
      if (transaction.bankId != original.bankId) continue;
      if (transaction.accountNumber != original.accountNumber) continue;
      return transaction;
    }
    return null;
  }

  List<Transaction> _refreshTransactions(TransactionProvider provider) {
    final updated = provider.allTransactions;
    return widget.transactions
        .map((transaction) =>
            _findUpdatedTransaction(transaction, updated) ?? transaction)
        .toList();
  }

  bool _matchesCategoryFilter(Transaction transaction) {
    if (_selectedCategoryIds.isEmpty) return true;
    final categoryId = transaction.categoryId;
    if (categoryId == null) return _selectedCategoryIds.contains(null);
    return _selectedCategoryIds.contains(categoryId);
  }

  List<Transaction> _filterByCategory(List<Transaction> transactions) {
    return transactions.where(_matchesCategoryFilter).toList(growable: false);
  }

  Future<void> _openCategoryFilterSheet() async {
    final result = await showCategoryFilterSheet(
      context: context,
      provider: widget.provider,
      selectedCategoryIds: _selectedCategoryIds,
    );
    if (result == null) return;
    setState(() {
      _selectedCategoryIds = result.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.provider,
          builder: (context, _) {
            final refreshedTransactions = _refreshTransactions(widget.provider);
            final filteredTransactions =
                _filterByCategory(refreshedTransactions);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: CategoryFilterButton(
                        label: 'Categories',
                        selectedCount: _selectedCategoryIds.length,
                        onTap: _openCategoryFilterSheet,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TransactionsList(
                      transactions: filteredTransactions,
                      sortBy: _sortBy,
                      provider: widget.provider,
                      includeBottomPadding: false,
                      onTransactionTap: (transaction) async {
                        await showCategorizeTransactionSheet(
                          context: context,
                          provider: widget.provider,
                          transaction: transaction,
                        );
                      },
                      onSortChanged: (sort) {
                        setState(() {
                          _sortBy = sort;
                        });
                      },
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
}
