import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/sms_pattern.dart';

class SmsConfigService {
  static final List<SmsPattern> _defaultPatterns = [
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"Account\s+(?<account>\d\*+\d+)\s+has been credited.*?ETB\s+(?<amount>[\d,.]+).*?Balance is ETB\s+(?<balance>[\d,.]+).*?/(?:BranchReceipt|Receipt)/(?<reference>[A-Z0-9]+)",
      type: "CREDIT",
      description: "CBE Payroll Credit",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"(?:Account|Acct)\s+(?<account>[\d\*]+).*?credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))",
      type: "CREDIT",
      description: "CBE Credit with Account",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"(?:Account|Acct)\s+(?<account>[\d\*]+).*?debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))",
      type: "DEBIT",
      description: "CBE Debit with Account",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"credited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))",
      type: "CREDIT",
      description: "CBE Credit Basic",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))",
      type: "DEBIT",
      description: "CBE Debit Basic",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"transfered\s+ETB\s?(?<amount>[\d,.]+)\s+to.*?from\s+your\s+account\s+(?<account>[\d\*]+).*?Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?((id=|BranchReceipt/)(?<reference>FT\w+))",
      type: "DEBIT",
      description: "CBE Transfer Debit",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"Account\s+(?<account>\d\*+\d+).*?debited\s+with\s+ETB\s+(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "DEBIT",
      description: "CBE ATM withdrawal",
      refRequired: false,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"(?:Account|Acct)\s+(?<account>[\d\*]+).*?has\s+been\s+debited\s+with\s+ETB\s?(?<amount>[\d,.]+).*?Current\s+Balance\s+is\s+ETB\s?(?<balance>[\d,.]+).*?(id=|BranchReceipt/)(?<reference>FT\w+)",
      type: "DEBIT",
      description: "CBE to own telebirr",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 1,
      senderId: "CBE",
      regex:
          r"Account\s+(?<account>\d\*+\d+).*?(?<type>credited|debited)\s+with\s+ETB\s+(?<amount>[\d,.]+).*?Balance\s+is\s+ETB\s+(?<balance>[\d,.]+)",
      type: "CREDIT",
      description: "CBE credit, no ref",
      refRequired: false,
      hasAccount: true,
    ),
    // e& money patterns
    SmsPattern(
      bankId: 9,
      senderId: "eandmoney",
      regex:
          r"A deposit of AED (?<amount>[\d,.]+)  has been made into your e& money\. Your new balance is (?<balance>[\d,.]+) AED\. Your transaction ID is  (?<reference>\d+)",
      type: "CREDIT",
      description: "e& money deposit",
      refRequired: true,
      hasAccount: false,
    ),
    SmsPattern(
      bankId: 9,
      senderId: "eandmoney",
      regex:
          r"Good news! AED (?<amount>[\d,.]+) from (?<sender>.*?) landed in your account\.\s+Check your new balance: (?<balance>[\d,.]+)\s+Transaction ID: (?<reference>\d+)",
      type: "CREDIT",
      description: "e& money received",
      refRequired: true,
      hasAccount: false,
    ),
    SmsPattern(
      bankId: 9,
      senderId: "eandmoney",
      regex:
          r"purchase of AED (?<amount>[\d,.]+) was successfully completed at (?<receiver>.*?) using your e& money card ending with (?<account>\d+).*?Available balance: AED (?<balance>[\d,.]+).*?Transaction ID: (?<reference>\d+)",
      type: "DEBIT",
      description: "e& money purchase",
      refRequired: true,
      hasAccount: true,
    ),
    SmsPattern(
      bankId: 9,
      senderId: "eandmoney",
      regex:
          r"You sent AED (?<amount>[\d,.]+) to (?<receiver>.*?)\.\s+New balance: (?<balance>[\d,.]+)\s+Transaction ID: (?<reference>\d+)",
      type: "DEBIT",
      description: "e& money sent",
      refRequired: true,
      hasAccount: false,
    ),
    SmsPattern(
      bankId: 9,
      senderId: "eandmoney",
      regex:
          r"AED (?<amount>[\d,.]+) added to your e\& money using your card\..*?Your updated balance is AED (?<balance>[\d,.]+) \s+Transaction ID: (?<reference>\d+)",
      type: "CREDIT",
      description: "e& money card load",
      refRequired: true,
      hasAccount: false,
    ),
  ];

  void debugSms(String smsText) {
    // Show invisible characters
    // print("Raw SMS (escaped): ${jsonEncode(smsText)}");

    // // Optionally show code units for each character
    // print("Code units: ${smsText.codeUnits}");
  }

  String cleanSmsText(String text) {
    try {
      // String jsonString = jsonEncode(text);
      // String cleaned = jsonDecode(jsonString);
      // cleaned = cleaned.replaceAll('\r', ' ');
      // cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
      // cleaned = cleaned.replaceAll(RegExp(r'\.\s*([A-Z])'), ' \$1');
      return text.trim();
    } catch (e) {
      print("debug: JSON sanitization failed: $e");
      return text;
    }
  }

  Future<List<SmsPattern>> getPatterns() async {
    final db = await DatabaseHelper.instance.database;

    // First, try to load from database
    final List<Map<String, dynamic>> maps = await db.query('sms_patterns');
    if (maps.isNotEmpty) {
      try {
        final patterns = maps.map((map) {
          return SmsPattern.fromJson({
            'bankId': map['bankId'],
            'senderId': map['senderId'],
            'regex': map['regex'],
            'type': map['type'],
            'description': map['description'],
            'refRequired':
                map['refRequired'] == null ? null : (map['refRequired'] == 1),
            'hasAccount':
                map['hasAccount'] == null ? null : (map['hasAccount'] == 1),
          });
        }).toList();
        print("debug: Loaded ${patterns.length} patterns from database");
        return patterns;
      } catch (e) {
        print("debug: Error parsing stored patterns: $e");
        // Fall through to fetch from remote
      }
    }

    // If not in database, try to fetch from remote (only if internet available)
    final hasInternet = await _hasInternetConnection();
    if (hasInternet) {
      try {
        final patterns = await _fetchRemotePatterns();
        if (patterns.isNotEmpty) {
          await savePatterns(patterns);
          return patterns;
        }
      } catch (e) {
        print("debug: Error fetching remote patterns: $e");
      }
    } else {
      print("debug: No internet connection, cannot fetch remote patterns");
    }

    // Fallback to default patterns
    print("debug: Using default patterns as fallback");
    // Save defaults to database for next time
    await savePatterns(_defaultPatterns);
    return _defaultPatterns;
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // Check if we have any connection (mobile, wifi, ethernet, etc.)
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      // Additional check: try to reach a known server
      try {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 3));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    } catch (e) {
      print("debug: Error checking connectivity: $e");
      return false;
    }
  }

  Future<List<SmsPattern>> _fetchRemotePatterns() async {
    const String url =
        "https://sms-parsing-visualizer.vercel.app/sms_patterns.json";

    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        String body = response.body;

        // Handle JavaScript file that might export JSON
        // Remove any JavaScript wrapper if present
        body = body.trim();
        if (body.startsWith('export') ||
            body.startsWith('const') ||
            body.startsWith('var') ||
            body.startsWith('let')) {
          // Extract JSON from JS file
          final jsonMatch =
              RegExp(r'(\[[\s\S]*\])|(\{[\s\S]*\})').firstMatch(body);
          if (jsonMatch != null) {
            body = jsonMatch.group(0)!;
          }
        }

        // Parse JSON
        final dynamic jsonData = jsonDecode(body);
        List<SmsPattern> patterns = [];

        if (jsonData is List) {
          patterns = jsonData
              .map((item) => SmsPattern.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (jsonData is Map && jsonData.containsKey('patterns')) {
          // Handle case where JSON has a 'patterns' key
          final patternsList = jsonData['patterns'] as List;
          patterns = patternsList
              .map((item) => SmsPattern.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Manually add e& money patterns if not present (local override)
        if (!patterns.any((p) => p.senderId == "eandmoney")) {
          patterns.addAll([
            SmsPattern(
              bankId: 9,
              senderId: "eandmoney",
              regex:
                  r"A deposit of AED (?<amount>[\d,.]+)  has been made into your e& money\. Your new balance is (?<balance>[\d,.]+) AED\. Your transaction ID is  (?<reference>\d+)",
              type: "CREDIT",
              description: "e& money deposit",
              refRequired: true,
              hasAccount: false,
            ),
            SmsPattern(
              bankId: 9,
              senderId: "eandmoney",
              regex:
                  r"Good news! AED (?<amount>[\d,.]+) from (?<sender>.*?) landed in your account\.\s+Check your new balance: (?<balance>[\d,.]+)\s+Transaction ID: (?<reference>\d+)",
              type: "CREDIT",
              description: "e& money received",
              refRequired: true,
              hasAccount: false,
            ),
            SmsPattern(
              bankId: 9,
              senderId: "eandmoney",
              regex:
                  r"purchase of AED (?<amount>[\d,.]+) was successfully completed at (?<receiver>.*?) using your e& money card ending with (?<account>\d+).*?Available balance: AED (?<balance>[\d,.]+).*?Transaction ID: (?<reference>\d+)",
              type: "DEBIT",
              description: "e& money purchase",
              refRequired: true,
              hasAccount: true,
            ),
            SmsPattern(
              bankId: 9,
              senderId: "eandmoney",
              regex:
                  r"You sent AED (?<amount>[\d,.]+) to (?<receiver>.*?)\.\s+New balance: (?<balance>[\d,.]+)\s+Transaction ID: (?<reference>\d+)",
              type: "DEBIT",
              description: "e& money sent",
              refRequired: true,
              hasAccount: false,
            ),
            SmsPattern(
              bankId: 9,
              senderId: "eandmoney",
              regex:
                  r"AED (?<amount>[\d,.]+) added to your e\& money using your card\..*?Your updated balance is AED (?<balance>[\d,.]+) \s+Transaction ID: (?<reference>\d+)",
              type: "CREDIT",
              description: "e& money card load",
              refRequired: true,
              hasAccount: false,
            ),
          ]);
        }
        print("debug: Fetched ${patterns.length} patterns from remote");
        return patterns;
      } else {
        print("debug: Remote fetch failed with status ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("debug: Exception fetching remote patterns: $e");
      return [];
    }
  }

  Future<void> savePatterns(List<SmsPattern> patterns) async {
    final db = await DatabaseHelper.instance.database;

    // Clear existing patterns and insert new ones
    await db.delete('sms_patterns');

    final batch = db.batch();
    for (var pattern in patterns) {
      batch.insert('sms_patterns', {
        'bankId': pattern.bankId,
        'senderId': pattern.senderId,
        'regex': pattern.regex,
        'type': pattern.type,
        'description': pattern.description,
        'refRequired':
            pattern.refRequired == null ? null : (pattern.refRequired! ? 1 : 0),
        'hasAccount':
            pattern.hasAccount == null ? null : (pattern.hasAccount! ? 1 : 0),
      });
    }
    await batch.commit(noResult: true);
    print("debug: Saved ${patterns.length} patterns to database");
  }

  // Method to force fetch remote config (background sync)
  Future<void> syncRemoteConfig({bool showError = false}) async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      print("debug: No internet connection, skipping remote sync");
      return;
    }

    try {
      final patterns = await _fetchRemotePatterns();
      if (patterns.isNotEmpty) {
        await savePatterns(patterns);
        print("debug: Successfully synced remote config");
      } else {
        print("debug: Remote sync returned empty patterns");
      }
    } catch (e) {
      print("debug: Error syncing remote config: $e");
      if (showError) {
        rethrow;
      }
    }
  }

  // Initialize patterns on app launch
  // Returns true if internet is needed but not available
  // Only fetches if patterns don't exist (no background sync)
  Future<bool> initializePatterns() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('sms_patterns');

    // If patterns exist, return (no sync - sync only happens on explicit refresh)
    if (maps.isNotEmpty) {
      return false; // No internet needed, we have cached patterns
    }

    // No patterns stored, need to fetch
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      return true; // Internet needed but not available
    }

    // Fetch and save patterns
    try {
      final patterns = await _fetchRemotePatterns();
      if (patterns.isNotEmpty) {
        await savePatterns(patterns);
        return false; // Success
      } else {
        // Fallback to defaults
        await savePatterns(_defaultPatterns);
        return false;
      }
    } catch (e) {
      print("debug: Error initializing patterns: $e");
      // Fallback to defaults
      await savePatterns(_defaultPatterns);
      return false;
    }
  }
}
