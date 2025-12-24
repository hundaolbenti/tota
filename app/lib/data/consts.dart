import 'package:totals/models/bank.dart';

class AppConstants {
  static const List<Bank> banks = [
    Bank(
      id: 1,
      name: "Commercial Bank Of Ethiopia",
      shortName: "CBE",
      codes: [
        "CBE",
      ],
      image: "assets/images/cbe.png",
      currency: "ETB",
    ),
    Bank(
      id: 8,
      name: "e& money",
      shortName: "e& money",
      codes: [
        "eandmoney",
      ],
      image: "assets/images/eandmoney.png",
      currency: "AED",
    ),
  ];
}
