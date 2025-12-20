import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:totals/services/bank_config_service.dart';
import '../chart_data_point.dart';

class PnLCalendarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final double maxValue;
  final DateTime baseDate;
  final String selectedPeriod;
  final String? selectedCard;
  final int? selectedBankFilter;
  final String? selectedAccountFilter;

  const PnLCalendarChart({
    super.key,
    required this.data,
    required this.maxValue,
    required this.baseDate,
    required this.selectedPeriod,
    required this.selectedCard,
    required this.selectedBankFilter,
    required this.selectedAccountFilter,
  });

  @override
  Widget build(BuildContext context) {
    final allTransactions =
        Provider.of<TransactionProvider>(context, listen: false)
            .allTransactions;
    final accounts = Provider.of<TransactionProvider>(context, listen: false)
        .accountSummaries;
    final now = baseDate;

    final BankConfigService bankConfigService = BankConfigService();
    final banksFuture = bankConfigService.getBanks();

    return FutureBuilder(
      future: banksFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final banks = snapshot.data!;

        // Filter by bank, account, and income/expense card
        var filtered = allTransactions;

        // Filter by selected card (Income/Expense)
        if (selectedCard == 'Income') {
          filtered = filtered.where((t) => t.type == 'CREDIT').toList();
        } else if (selectedCard == 'Expense') {
          filtered = filtered.where((t) => t.type == 'DEBIT').toList();
        }

        // Filter by bank
        if (selectedBankFilter != null) {
          filtered =
              filtered.where((t) => t.bankId == selectedBankFilter).toList();
        }

        // Filter by account if selected
        if (selectedAccountFilter != null && selectedBankFilter != null) {
          final account = accounts.firstWhere(
            (a) =>
                a.accountNumber == selectedAccountFilter &&
                a.bankId == selectedBankFilter,
            orElse: () => accounts
                .firstWhere((a) => a.bankId == selectedBankFilter, orElse: () {
              if (accounts.isEmpty) {
                throw StateError('No accounts available');
              }
              return accounts.first;
            }),
          );
          final bank = banks.firstWhere((b) => b.id == account.bankId);

          filtered = filtered.where((t) {
            if (bank.uniformMasking == true &&
                bank.maskPattern != null &&
                t.accountNumber != null &&
                account.accountNumber.length >= bank.maskPattern! &&
                t.accountNumber!.length >= bank.maskPattern!) {
              return t.accountNumber!
                      .substring(t.accountNumber!.length - bank.maskPattern!) ==
                  account.accountNumber.substring(
                      account.accountNumber.length - bank.maskPattern!);
            } else {
              return t.bankId == account.bankId;
            }
          }).toList();
        }

        // Determine date range based on selected period
        DateTime startDate;
        DateTime endDate;
        String periodLabel;
        List<DateTime> dates = [];

        if (selectedPeriod == 'Week') {
          int daysSinceMonday = (now.weekday - 1) % 7;
          startDate = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysSinceMonday));
          endDate = startDate.add(const Duration(days: 6));
          periodLabel = 'Week of ${DateFormat('MMM dd').format(startDate)}';
          for (int i = 0; i < 7; i++) {
            dates.add(startDate.add(Duration(days: i)));
          }
        } else if (selectedPeriod == 'Month') {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          periodLabel = DateFormat('MMMM yyyy').format(startDate);
          final daysInMonth = endDate.day;
          for (int day = 1; day <= daysInMonth; day++) {
            dates.add(DateTime(now.year, now.month, day));
          }
        } else {
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          periodLabel = '${now.year}';
          for (int month = 1; month <= 12; month++) {
            dates.add(DateTime(now.year, month, 1));
          }
        }

        final firstWeekday = (dates.first.weekday - 1) % 7;

        final dailyPnL = <DateTime, double>{};
        for (final date in dates) {
          final dayTransactions = filtered.where((t) {
            if (t.time == null) return false;
            try {
              final transactionDate = DateTime.parse(t.time!);
              if (selectedPeriod == 'Week') {
                return transactionDate.year == date.year &&
                    transactionDate.month == date.month &&
                    transactionDate.day == date.day;
              } else if (selectedPeriod == 'Month') {
                return transactionDate.year == date.year &&
                    transactionDate.month == date.month &&
                    transactionDate.day == date.day;
              } else {
                return transactionDate.year == date.year &&
                    transactionDate.month == date.month;
              }
            } catch (e) {
              return false;
            }
          }).toList();

          double pnl = 0.0;
          if (selectedCard == 'Income') {
            pnl = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
          } else if (selectedCard == 'Expense') {
            pnl = -dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
          } else {
            final income = dayTransactions
                .where((t) => t.type == 'CREDIT')
                .fold(0.0, (sum, t) => sum + t.amount);
            final expenses = dayTransactions
                .where((t) => t.type == 'DEBIT')
                .fold(0.0, (sum, t) => sum + t.amount);
            pnl = income - expenses;
          }

          dailyPnL[date] = pnl;
        }

        final maxPnL = dailyPnL.values.isEmpty
            ? 100.0
            : dailyPnL.values
                .map((v) => v.abs())
                .reduce((a, b) => a > b ? a : b);

        int weeks;
        int itemsPerRow;
        if (selectedPeriod == 'Week') {
          weeks = 1;
          itemsPerRow = 7;
        } else if (selectedPeriod == 'Month') {
          final daysInMonth = dates.length;
          final totalCells = firstWeekday + daysInMonth;
          weeks = (totalCells / 7).ceil();
          itemsPerRow = 7;
        } else {
          weeks = 3;
          itemsPerRow = 4;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    periodLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      _buildLegendItem(context, 'Profit', Colors.green),
                      const SizedBox(width: 12),
                      _buildLegendItem(
                          context, 'Loss', Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  if (selectedPeriod == 'Year')
                    Row(
                      children: ['Q1', 'Q2', 'Q3', 'Q4'].map((quarter) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              quarter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Row(
                      children: [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ].map((day) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  ...List.generate(weeks, (weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: List.generate(itemsPerRow, (dayIndex) {
                          final cellIndex = selectedPeriod == 'Year'
                              ? dayIndex * weeks + weekIndex
                              : weekIndex * itemsPerRow + dayIndex;

                          if (selectedPeriod == 'Year') {
                            if (cellIndex >= dates.length) {
                              return Expanded(child: Container());
                            }
                            final date = dates[cellIndex];
                            final monthName = DateFormat('MMM').format(date);
                            final pnl = dailyPnL[date] ?? 0.0;
                            final isCurrentMonth =
                                baseDate.year == DateTime.now().year &&
                                    baseDate.month == DateTime.now().month &&
                                    date.year == DateTime.now().year &&
                                    date.month == DateTime.now().month;
                            final intensity = maxPnL > 0
                                ? (pnl.abs() / maxPnL).clamp(0.0, 1.0)
                                : 0.0;
                            final isPositive = pnl >= 0;
                            final hasTransactions = pnl != 0.0;
                            final bgOpacity =
                                hasTransactions ? (0.2 + intensity * 0.6) : 0.1;
                            final useWhiteText = bgOpacity > 0.5;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: !hasTransactions
                                        ? Colors.grey.withOpacity(0.2)
                                        : (isPositive
                                            ? Colors.green
                                                .withOpacity(bgOpacity)
                                            : Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withOpacity(bgOpacity)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isCurrentMonth
                                        ? Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        monthName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isCurrentMonth
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: useWhiteText
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                        ),
                                      ),
                                      if (pnl != 0)
                                        Text(
                                          '${pnl > 0 ? '+' : ''}${(pnl / 1000).toStringAsFixed(1)}k',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: useWhiteText
                                                ? Colors.white
                                                : (isPositive
                                                    ? Colors.green.shade700
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final cellIndexWithOffset =
                                weekIndex * itemsPerRow + dayIndex;
                            final dayNumber =
                                cellIndexWithOffset - firstWeekday + 1;

                            if (selectedPeriod == 'Week') {
                              if (cellIndexWithOffset >= dates.length) {
                                return Expanded(child: Container());
                              }
                              final date = dates[cellIndexWithOffset];
                              final dayNumber = date.day;
                              final pnl = dailyPnL[date] ?? 0.0;
                              final isToday =
                                  baseDate.year == DateTime.now().year &&
                                      baseDate.month == DateTime.now().month &&
                                      baseDate.day == DateTime.now().day &&
                                      date.year == DateTime.now().year &&
                                      date.month == DateTime.now().month &&
                                      date.day == DateTime.now().day;
                              final intensity = maxPnL > 0
                                  ? (pnl.abs() / maxPnL).clamp(0.0, 1.0)
                                  : 0.0;
                              final isPositive = pnl >= 0;
                              final hasTransactions = pnl != 0.0;
                              final bgOpacity = hasTransactions
                                  ? (0.2 + intensity * 0.6)
                                  : 0.1;
                              final useWhiteText = bgOpacity > 0.5;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: !hasTransactions
                                          ? Colors.grey.withOpacity(0.2)
                                          : (isPositive
                                              ? Colors.green
                                                  .withOpacity(bgOpacity)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .error
                                                  .withOpacity(bgOpacity)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: isToday
                                          ? Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dayNumber',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: useWhiteText
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                        if (pnl != 0)
                                          Text(
                                            '${pnl > 0 ? '+' : ''}${(pnl / 1000).toStringAsFixed(1)}k',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: useWhiteText
                                                  ? Colors.white
                                                  : (isPositive
                                                      ? Colors.green.shade700
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              if (dayNumber < 1 || dayNumber > dates.length) {
                                return Expanded(child: Container());
                              }

                              final date = dates[dayNumber - 1];
                              final pnl = dailyPnL[date] ?? 0.0;
                              final isToday =
                                  baseDate.year == DateTime.now().year &&
                                      baseDate.month == DateTime.now().month &&
                                      baseDate.day == DateTime.now().day &&
                                      date.year == DateTime.now().year &&
                                      date.month == DateTime.now().month &&
                                      date.day == DateTime.now().day;
                              final intensity = maxPnL > 0
                                  ? (pnl.abs() / maxPnL).clamp(0.0, 1.0)
                                  : 0.0;
                              final isPositive = pnl >= 0;
                              final hasTransactions = pnl != 0.0;
                              final bgOpacity = hasTransactions
                                  ? (0.2 + intensity * 0.6)
                                  : 0.1;
                              final useWhiteText = bgOpacity > 0.5;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: !hasTransactions
                                          ? Colors.grey.withOpacity(0.2)
                                          : (isPositive
                                              ? Colors.green
                                                  .withOpacity(bgOpacity)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .error
                                                  .withOpacity(bgOpacity)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: isToday
                                          ? Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$dayNumber',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: useWhiteText
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                        if (pnl != 0)
                                          Text(
                                            '${pnl > 0 ? '+' : ''}${(pnl / 1000).toStringAsFixed(1)}k',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: useWhiteText
                                                  ? Colors.white
                                                  : (isPositive
                                                      ? Colors.green.shade700
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .error),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
