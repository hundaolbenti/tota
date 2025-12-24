import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/bank.dart';

class BankConfigService {
  static final List<Bank> _defaultBanks = [
    Bank(
      id: 1,
      name: "Commercial Bank Of Ethiopia",
      shortName: "CBE",
      codes: ["CBE"],
      image: "assets/images/cbe.png",
      currency: "ETB",
      maskPattern: 4,
      uniformMasking: true,
    ),
    Bank(
      id: 8,
      name: "e& money",
      shortName: "e& money",
      codes: ["eandmoney"],
      image: "assets/images/eandmoney.png",
      currency: "AED",
      maskPattern: 4,
      uniformMasking: true,
    ),
  ];

  Future<List<Bank>> getBanks() async {
    // Force use of default banks and sync to DB
    await saveBanks(_defaultBanks);
    return _defaultBanks;
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

  Future<List<Bank>> _fetchRemoteBanks() async {
    const String url = "https://sms-parsing-visualizer.vercel.app/banks.json";

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
        List<Bank> banks = [];

        if (jsonData is List) {
          banks = jsonData
              .map((item) => Bank.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (jsonData is Map && jsonData.containsKey('banks')) {
          // Handle case where JSON has a 'banks' key
          final banksList = jsonData['banks'] as List;
          banks = banksList
              .map((item) => Bank.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        print("debug: Fetched ${banks.length} banks from remote");
        return banks;
      } else {
        print("debug: Remote fetch failed with status ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("debug: Exception fetching remote banks: $e");
      return [];
    }
  }

  Future<void> saveBanks(List<Bank> banks) async {
    final db = await DatabaseHelper.instance.database;

    // Clear existing banks and insert new ones
    await db.delete('banks');

    final batch = db.batch();
    for (var bank in banks) {
      batch.insert(
          'banks',
          {
            'id': bank.id,
            'name': bank.name,
            'shortName': bank.shortName,
            'codes': jsonEncode(bank.codes),
            'image': bank.image,
            'currency': bank.currency,
            'maskPattern': bank.maskPattern,
            'uniformMasking': bank.uniformMasking == null
                ? null
                : (bank.uniformMasking! ? 1 : 0),
            'simBased': bank.simBased == null ? null : (bank.simBased! ? 1 : 0),
            'colors': bank.colors != null ? jsonEncode(bank.colors) : null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    print("debug: Saved ${banks.length} banks to database");
  }

  // Method to force fetch remote config (background sync)
  Future<void> syncRemoteConfig({bool showError = false}) async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      print("debug: No internet connection, skipping remote sync");
      return;
    }

    try {
      final banks = await _fetchRemoteBanks();
      if (banks.isNotEmpty) {
        await saveBanks(banks);
        print("debug: Successfully synced remote banks config");
      } else {
        print("debug: Remote sync returned empty banks");
      }
    } catch (e) {
      print("debug: Error syncing remote banks config: $e");
      if (showError) {
        rethrow;
      }
    }
  }

  // Initialize banks on app launch
  // Force reset to default banks provided in code
  Future<bool> initializeBanks() async {
    await saveBanks(_defaultBanks);
    return false;
  }
}
