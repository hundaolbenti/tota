import 'dart:convert';
import 'package:another_telephony/telephony.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/services/sms_config_service.dart';
import 'package:totals/utils/pattern_parser.dart';
import 'package:totals/repositories/transaction_repository.dart';
import 'package:totals/repositories/account_repository.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/models/account.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function for background execution
@pragma('vm:entry-point')
onBackgroundMessage(SmsMessage message) async {
  try {
    print("BG: Handler started.");

    final String? address = message.address;
    print("BG: Address: '$address'");

    final String? body = message.body;
    if (body == null) {
      print("BG: Body is null. Exiting.");
      return;
    }

    print("BG: Checking if relevant...");
    if (SmsService.isRelevantMessage(address)) {
      print("BG: Message IS relevant. Processing...");
      await SmsService.processMessage(body, address!);
      print("BG: Processing finished.");
    } else {
      print("BG: Message NOT relevant.");
    }
  } catch (e, stack) {
    print("BG: CRITICAL ERROR: $e");
    print(stack);
  }
}

class SmsService {
  final Telephony _telephony = Telephony.instance;
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();

  // Callback to notify UI to refresh
  Function()? onMessageReceived;

  Future<void> init() async {
    final bool? result = await _telephony.requestSmsPermissions;
    if (result != null && result) {
      _telephony.listenIncomingSms(
        onNewMessage: _handleForegroundMessage,
        onBackgroundMessage: onBackgroundMessage,
      );
    } else {
      print("SMS Permission denied");
    }
  }

  void _handleForegroundMessage(SmsMessage message) async {
    print("Foreground message from ${message.address}: ${message.body}");
    if (message.body == null) return;

    try {
      if (SmsService.isRelevantMessage(message.address)) {
        await SmsService.processMessage(message.body!, message.address!);
        if (onMessageReceived != null) {
          onMessageReceived!();
        }
      }
    } catch (e) {
      print("Error processing foreground message: $e");
    }
  }

  /// Checks if the message address matches any of our known bank codes.
  static bool isRelevantMessage(String? address) {
    if (address == null) return false;
    return getRelevantBank(address) != null;
  }

  /// Identifies the bank associated with the sender address.
  static Bank? getRelevantBank(String? address) {
    if (address == null) return null;
    for (var bank in AppConstants.banks) {
      for (var code in bank.codes) {
        if (address.contains(code)) {
          return bank;
        }
      }
    }
    return null;
  }

  // Static processing logic so it can be used by background handler too.
  static Future<void> processMessage(
      String messageBody, String senderAddress) async {
    print("Processing message: $messageBody");

    Bank? bank = getRelevantBank(senderAddress);
    if (bank == null) {
      print("No bank found for address $senderAddress - skipping processing.");
      return;
    }

    // 1. Load Patterns
    final SmsConfigService configService = SmsConfigService();
    final patterns = await configService.getPatterns();
    final relevantPatterns =
        patterns.where((p) => p.bankId == bank.id).toList();

    // 2. Parse
    var details = PatternParser.extractTransactionDetails(
        messageBody, senderAddress, relevantPatterns);

    if (details == null) {
      print("No matching pattern found for message from $senderAddress");
      // Fallback to legacy or exit?
      // For now, let's try legacy if dynamic fails, just in case, or just return.
      // Given we want to replace it, let's stick to dynamic.
      return;
    }

    print("Extracted details: $details");

    // 3. Check duplicate transaction
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    TransactionRepository txRepo = TransactionRepository();
    List<Transaction> existingTx = await txRepo.getTransactions();

    String? newRef = details['reference'];
    if (newRef != null && existingTx.any((t) => t.reference == newRef)) {
      print("Duplicate transaction skipped");
      return;
    }

    // 4. Update Account Balance
    // We need to match the Bank ID from the pattern, not just assume 1 (CBE)
    int bankId = details['bankId'] ?? bank.id;

    if (details['accountNumber'] != null) {
      AccountRepository accRepo = AccountRepository();
      List<Account> accounts = await accRepo.getAccounts();

      String extractedAccount = details['accountNumber'];
      // Fuzzy match logic:
      // If extracted is full account, match exact.
      // If extracted is masked (1*****5345), match endsWith.

      int index = accounts.indexWhere((a) {
        if (a.bank != bankId) return false;

        // Simple endsWith check is usually robust enough for masked accounts
        // e.g. "5345" match "1000...5345"
        // But the extracted might be "1*****5345".
        // We should extract the last visible digits or just use endsWith if it's plain numbers.

        // Let's strip non-digits to be safe for comparison if we had partials,
        // but for now let's assume valid regex returns the relevant part.
        // If regex returns "1*****5345", we can't match exact against "10001235345".
        // Use last 4 digits comparison.

        if (extractedAccount.length < 4) return false;
        String last4 = extractedAccount.substring(extractedAccount.length - 4);
        return a.accountNumber.endsWith(last4);
      });

      if (index != -1) {
        Account old = accounts[index];

        // Parse balance from string to double if needed, depending on how PatternParser returns it
        // PatternParser returns string for consistency with previous map, but let's check.
        // Account model expects double for balance? No, local Account model has double balance.
        // Details map has 'currentBalance' as String usually.

        double newBalance =
            double.tryParse(old.balance.replaceAll(',', '')) ?? 0.0;
        if (details['currentBalance'] != null) {
          newBalance = double.tryParse(
                  details['currentBalance'].toString().replaceAll(',', '')) ??
              newBalance;
        }

        // Update balance
        Account updated = Account(
            accountNumber: old.accountNumber,
            bank: old.bank,
            balance: newBalance.toString(),
            accountHolderName: old.accountHolderName,
            settledBalance: old.settledBalance,
            pendingCredit: old.pendingCredit);
        await accRepo.saveAccount(updated);
        print("Account balance updated for ${old.accountHolderName}");
      } else {
        print(
            "No matching account found for bank $bankId and account $extractedAccount");
      }
    }

    // 5. Save Transaction
    // Need to ensure details has all fields or handle parsing
    // Transaction.fromJson expects Strings mostly?
    Transaction newTx = Transaction.fromJson(details);
    await txRepo.saveTransaction(newTx);
    print("New transaction saved: ${newTx.reference}");
  }
}
