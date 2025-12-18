import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:totals/data/consts.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/utils/text_utils.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _transactionChannelId = 'transactions';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initializationSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _transactionChannelId,
        'Transactions',
        description: 'Notifications when a new transaction is detected',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<void> requestPermissionsIfNeeded() async {
    try {
      await ensureInitialized();

      if (kIsWeb) return;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('debug: Notification permission request failed: $e');
      }
    }
  }

  Future<void> showTransactionNotification({
    required Transaction transaction,
    required int? bankId,
  }) async {
    try {
      await ensureInitialized();

      final bank = _findBank(bankId);
      final title = _buildTitle(bank, transaction);
      final body = _buildBody(transaction);

      final id = _notificationId(transaction);

      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _transactionChannelId,
            'Transactions',
            channelDescription:
                'Notifications when a new transaction is detected',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('debug: Failed to show transaction notification: $e');
      }
    }
  }

  static Bank? _findBank(int? bankId) {
    if (bankId == null) return null;
    for (final bank in AppConstants.banks) {
      if (bank.id == bankId) return bank;
    }
    return null;
  }

  static int _notificationId(Transaction transaction) {
    // Stable ID so "same reference" updates instead of spamming.
    final raw = transaction.reference.isEmpty
        ? '${transaction.time ?? ''}|${transaction.amount}'
        : transaction.reference;
    return raw.hashCode & 0x7fffffff;
  }

  static String _buildTitle(Bank? bank, Transaction transaction) {
    final bankLabel = bank?.shortName ?? 'Totals';
    final kind = switch (transaction.type) {
      'CREDIT' => 'Money In',
      'DEBIT' => 'Money Out',
      _ => 'Transaction',
    };
    return '$bankLabel • $kind';
  }

  static String _buildBody(Transaction transaction) {
    final sign = switch (transaction.type) {
      'CREDIT' => '+',
      'DEBIT' => '-',
      _ => '',
    };

    final counterparty = _firstNonEmpty([
      transaction.creditor,
      transaction.receiver,
    ]);

    final amount = '${sign}ETB ${formatNumberWithComma(transaction.amount)}';
    if (counterparty == null) return amount;
    return '$amount • $counterparty';
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final trimmed = v?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
