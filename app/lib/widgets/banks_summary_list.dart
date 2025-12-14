import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/summary_models.dart';
import 'package:totals/services/account_sync_status_service.dart';
import 'package:totals/utils/text_utils.dart';
import 'package:totals/utils/gradients.dart';

class BanksSummaryList extends StatefulWidget {
  final List<BankSummary> banks;
  List<String> visibleTotalBalancesForSubCards;

  BanksSummaryList(
      {required this.banks, required this.visibleTotalBalancesForSubCards});

  @override
  State<BanksSummaryList> createState() => _BanksSummaryListState();
}

class _BanksSummaryListState extends State<BanksSummaryList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AccountSyncStatusService>(
      builder: (context, syncStatusService, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: widget.banks.length,
          itemBuilder: (context, index) {
            final bank = widget.banks[index];
            final isSyncing =
                syncStatusService.hasAnyAccountSyncing(bank.bankId);
            final syncStatus =
                syncStatusService.getSyncStatusForBank(bank.bankId);
            final bankInfo = AppConstants.banks
                .firstWhere((element) => element.id == bank.bankId);
            final gradient = GradientUtils.getGradient(bank.bankId);
            
            return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Glossy overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bank logo and name
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      bankInfo.image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bankInfo.shortName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      )
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            
                            // Balance and details
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bank.accountCount.toString() + ' accounts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.visibleTotalBalancesForSubCards
                                                .contains(bank.bankId.toString())
                                            ? formatNumberWithComma(bank.totalBalance) + " ETB"
                                            : "*" * 5,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 1),
                                              blurRadius: 2,
                                            )
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (widget.visibleTotalBalancesForSubCards
                                              .contains(bank.bankId.toString())) {
                                            widget.visibleTotalBalancesForSubCards
                                                .remove(bank.bankId.toString());
                                          } else {
                                            widget.visibleTotalBalancesForSubCards
                                                .add(bank.bankId.toString());
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          widget.visibleTotalBalancesForSubCards
                                                  .contains(bank.bankId.toString())
                                              ? Icons.visibility_off
                                              : Icons.remove_red_eye_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSyncing && syncStatus != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            syncStatus,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            );
          },
        );
      },
    );
  }
}
