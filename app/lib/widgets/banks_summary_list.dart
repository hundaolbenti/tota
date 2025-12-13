import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/summary_models.dart';
import 'package:totals/services/account_sync_status_service.dart';
import 'package:totals/utils/text_utils.dart';

class BanksSummaryList extends StatefulWidget {
  final List<BankSummary> banks;
  List<String> visibleTotalBalancesForSubCards;

  BanksSummaryList(
      {required this.banks, required this.visibleTotalBalancesForSubCards});

  @override
  State<BanksSummaryList> createState() => _BanksSummaryListState();
}

class _BanksSummaryListState extends State<BanksSummaryList> {
  int? isExpanded;

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountSyncStatusService>(
      builder: (context, syncStatusService, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.banks.length,
          itemBuilder: (context, index) {
            final bank = widget.banks[index];
            final isSyncing =
                syncStatusService.hasAnyAccountSyncing(bank.bankId);
            final syncStatus =
                syncStatusService.getSyncStatusForBank(bank.bankId);
            return Column(
              children: [
                GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded == null) {
                          isExpanded = bank.bankId;
                        } else if (isExpanded == bank.bankId) {
                          isExpanded = null;
                        } else {
                          isExpanded = bank.bankId;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  AppConstants.banks
                                      .firstWhere((element) =>
                                          element.id == bank.bankId)
                                      .image,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            AppConstants.banks
                                                .firstWhere((element) =>
                                                    element.id == bank.bankId)
                                                .name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Icon(
                                          isExpanded == bank.bankId
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                        )
                                      ]),
                                  Text(
                                    bank.accountCount.toString() + ' accounts',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (isSyncing && syncStatus != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(0xFF294EC3),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              syncStatus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF294EC3),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                            widget.visibleTotalBalancesForSubCards
                                                    .contains(
                                                        bank.bankId.toString())
                                                ? (formatNumberWithComma(
                                                        bank.totalBalance)) +
                                                    " ETB"
                                                : "*" * 5,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (widget
                                                  .visibleTotalBalancesForSubCards
                                                  .contains(
                                                      bank.bankId.toString())) {
                                                widget
                                                    .visibleTotalBalancesForSubCards
                                                    .remove(
                                                        bank.bankId.toString());
                                              } else {
                                                widget
                                                    .visibleTotalBalancesForSubCards
                                                    .add(
                                                        bank.bankId.toString());
                                              }
                                            });
                                          },
                                          child: Icon(
                                            widget.visibleTotalBalancesForSubCards
                                                    .contains(
                                                        bank.bankId.toString())
                                                ? Icons.visibility_off
                                                : Icons.remove_red_eye_outlined,
                                            color: Color(0xFFBDC0CA),
                                          ))
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        isExpanded == bank.bankId
                            ? Column(
                                children: [
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Credit",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                          "${formatNumberWithComma(bank.totalCredit).toString()} ETB",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Debit",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                          "${formatNumberWithComma(bank.totalDebit).toString()} ETB",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          )),
                                    ],
                                  ),
                                ],
                              )
                            : Container()
                      ]),
                    )),
                const SizedBox(
                  height: 13,
                )
              ],
            );
          },
        );
      },
    );
  }
}
