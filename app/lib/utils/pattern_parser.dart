import 'package:totals/models/sms_pattern.dart';

class PatternParser {
  /// Iterates through [patterns] that match the [senderAddress].
  /// Returns a map of extracted data if a match is found, or null otherwise.
  static Map<String, dynamic>? extractTransactionDetails(
      String messageBody, String senderAddress, List<SmsPattern> patterns) {
    // Normalize body to single line for easier regex in some cases,
    // or keep as is. Usually multiline regex is fine.
    // For safety against slight formatting variations, we'll trim.
    String cleanBody = messageBody.trim();

    for (var pattern in patterns) {
      // 2. Try to match regex
      try {
        RegExp regExp = RegExp(pattern.regex,
            caseSensitive: false, multiLine: true, dotAll: true);
        RegExpMatch? match = regExp.firstMatch(cleanBody);

        if (match != null) {
          print("Pattern Matched: ${pattern.description}");

          final Map<String, dynamic> extracted = {};

          // Extract known named groups
          // We support: amount, balance, account, reference, creditor, time

          extracted['type'] = pattern.type;
          extracted['bankId'] = pattern.bankId; // Default bank ID from pattern

          if (match.groupNames.contains('amount')) {
            extracted['amount'] = _cleanNumber(match.namedGroup('amount'));
          }
          if (match.groupNames.contains('balance')) {
            extracted['currentBalance'] =
                _cleanNumber(match.namedGroup('balance'));
          }
          if (match.groupNames.contains('account')) {
            extracted['accountNumber'] = match.namedGroup('account');
          }
          if (match.groupNames.contains('reference')) {
            extracted['reference'] = match.namedGroup('reference');
          }
          if (match.groupNames.contains('creditor')) {
            extracted['creditor'] = match.namedGroup('creditor');
          }
          if (match.groupNames.contains('time')) {
            // Date parsing is complex, for now store raw string or try basic parse
            // Ideally the regex extracts ISO-like or we have a date parser helper
            extracted['raw_time'] = match.namedGroup('time');
            extracted['time'] = DateTime.now()
                .toIso8601String(); // Default to now if parse fails
          } else {
            extracted['time'] = DateTime.now().toIso8601String();
          }

          // Validate required fields
          if (extracted['amount'] == null ||
              extracted['currentBalance'] == null ||
              extracted['reference'] == null) {
            print(
                "Pattern '${pattern.description}' matched but missing required fields (amount, balance, or reference). Skipping.");
            continue;
          }

          return extracted;
        }
      } catch (e) {
        print("Error checking pattern '${pattern.description}': $e");
        // Continue to next pattern
      }
    }

    return null; // No match found
  }

  static String? _cleanNumber(String? input) {
    if (input == null) return null;
    return input.replaceAll(',', '').trim();
  }
}
