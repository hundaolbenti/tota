import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totals/models/sms_pattern.dart';

class SmsConfigService {
  static const String _storageKey = "sms_patterns_config";
  static final List<SmsPattern> _defaultPatterns = [
    // --- CBE Patterns ---
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      // "credited with ETB 17000.00"
      regex:
          r"credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)",
      type: "CREDIT",
      description: "CBE Credit Basic",
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      // "debited with ETB3,000.00"
      regex:
          r"debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "CBE Debit Basic",
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      // "transfered ETB 10,000.00 to ..." (Note spelling 'transfered')
      regex:
          r"transfered\s+ETB\s?(?<amount>[\d,.]+)\s+to.*Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "CBE Transfer Debit",
    ),
    // Try to capture account number if possible (1*****5345)
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"Account\s+(?<account>\d+\*{3,}\d+).*?credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)",
      type: "CREDIT",
      description: "CBE Credit with Account",
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"Account\s+(?<account>\d+\*{3,}\d+).*?debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "CBE Debit with Account",
    ),

    // --- Telebirr Patterns ---
    SmsPattern(
      bankId: 6,
      senderId: "telebirr",
      // "transferred ETB 300.00 to..."
      regex:
          r"transferred\s+ETB\s+(?<amount>[\d,.]+)\s+to.*?transaction\s+number\s+is\s+(?<reference>\w+).*?balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "Telebirr Transfer Sent",
    ),
    SmsPattern(
      bankId: 6,
      senderId: "telebirr",
      // "transferred ETB 110.00 successfully... to Commercial Bank..."
      regex:
          r"transferred\s+ETB\s+(?<amount>[\d,.]+)\s+successfully.*?transaction\s+number\s+is\s+(?<reference>\w+).*?balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "Telebirr Bank Transfer",
    ),
    SmsPattern(
      bankId: 6,
      senderId: "telebirr",
      // "paid ETB 514.99 for goods..."
      regex:
          r"paid\s+ETB\s+(?<amount>[\d,.]+)\s+for\s+goods.*?transaction\s+number\s+is\s+(?<reference>\w+).*?balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "Telebirr Payment",
    ),
    SmsPattern(
      bankId: 6,
      senderId: "telebirr",
      // "received ETB 3,000.00 from..."
      regex:
          r"received\s+ETB\s+(?<amount>[\d,.]+)\s+from.*?transaction\s+number\s+is\s+(?<reference>\w+).*?balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "CREDIT",
      description: "Telebirr Received",
    ),
  ];

  Future<List<SmsPattern>> getPatterns() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? cachedFn = prefs.getStringList(_storageKey);
    if (cachedFn != null && cachedFn.isNotEmpty) {
      try {
        return cachedFn.map((s) => SmsPattern.fromJson(jsonDecode(s))).toList();
      } catch (e) {
        print("Error parsing cached patterns: $e");
      }
    }

    // Save defaults to cache so we have a baseline
    await savePatterns(_defaultPatterns);
    return _defaultPatterns;
  }

  Future<void> savePatterns(List<SmsPattern> patterns) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encoded = patterns.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  // Method to force fetch remote config (placeholder)
  Future<void> syncRemoteConfig() async {
    // await http.get(...)
    // await savePatterns(...)
  }
}
