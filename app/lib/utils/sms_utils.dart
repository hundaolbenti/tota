import 'package:totals/data/consts.dart';

class SmsUtils {
  static Map<String, dynamic> extractCBETransactionDetails(String message) {
    String type =
        message.toLowerCase().contains("credited") ? "CREDIT" : "DEBIT";
    if (type == "CREDIT") {
      String amountKeyword = "Credited with ETB ";
      int amountStart = message.indexOf(amountKeyword) + amountKeyword.length;
      int amountEnd = message.indexOf(".", amountStart) + 3;
      String creditedAmount = message.substring(amountStart, amountEnd);
      String? last4Digits;

      String transactionKeyword = "?id=";
      String accountKeyword = "your Account ";
      int transactionStart =
          message.indexOf(transactionKeyword) + transactionKeyword.length;
      String transactionId = message.substring(transactionStart).split(" ")[0];

      int accountStart = message.indexOf(accountKeyword);
      if (accountStart != -1) {
        accountStart += accountKeyword.length;
        List<String> parts = message.substring(accountStart).split(" ");
        if (parts.isNotEmpty) {
          String maskedAccount = parts[0]; // e.g., "1*****6068"
          if (maskedAccount.length >= 4) {
            last4Digits = maskedAccount.substring(maskedAccount.length - 4);
          }
        }
      }
      return {
        "amount": creditedAmount,
        "transactionId": transactionId,
        "bankId": 1,
        "type": "CREDIT",
        "transactionLink": "https://apps.cbe.come.et:100/?id=${transactionId}",
        "time": DateTime.now().toString(),
        "accountLastDigits": last4Digits
      };
    }

    String amountKeyword = "total of ETB";
    String transactionKeyword = "?id=";
    String accountKeyword = "your Account ";

    double? totalDebited;
    String? transactionId;
    String? last4Digits;

    int amountStart = message.indexOf(amountKeyword);
    if (amountStart != -1) {
      amountStart += amountKeyword.length;
      int amountEnd = message.indexOf(" ", amountStart);
      if (amountEnd == -1) amountEnd = message.length;
      totalDebited = double.tryParse(
          message.substring(amountStart, amountEnd).replaceAll(',', ''));
    }
    int transactionStart = message.indexOf(transactionKeyword);
    if (transactionStart != -1) {
      transactionStart += transactionKeyword.length;
      transactionId = message.substring(transactionStart).split(" ")[0];
    }

    int accountStart = message.indexOf(accountKeyword);
    if (accountStart != -1) {
      accountStart += accountKeyword.length;
      List<String> parts = message.substring(accountStart).split(" ");
      if (parts.isNotEmpty) {
        String maskedAccount = parts[0];
        if (maskedAccount.length >= 4) {
          last4Digits = maskedAccount.substring(maskedAccount.length - 4);
        }
      }
    }

    return {
      "amount": totalDebited,
      "transactionId": transactionId,
      "bankId": 1,
      "type": "DEBIT",
      "transactionLink": "https://apps.cbe.come.et:100/?id=${transactionId}",
      "time": DateTime.now().toString(),
      "accountLastDigits": last4Digits
    };
  }
}
