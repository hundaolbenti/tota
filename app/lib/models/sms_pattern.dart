class SmsPattern {
  final int bankId;
  final String senderId; // e.g., "CBE", "telebirr"
  final String regex;
  final String type; // CREDIT or DEBIT
  final String
      description; // For debugging, e.g., "CBE Debit with Service Charge"

  SmsPattern({
    required this.bankId,
    required this.senderId,
    required this.regex,
    required this.type,
    this.description = "",
  });

  factory SmsPattern.fromJson(Map<String, dynamic> json) {
    return SmsPattern(
      bankId: json['bankId'],
      senderId: json['senderId'],
      regex: json['regex'],
      type: json['type'],
      description: json['description'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankId': bankId,
      'senderId': senderId,
      'regex': regex,
      'type': type,
      'description': description,
    };
  }
}
