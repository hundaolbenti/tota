class Bank {
  final int id;
  final String name;
  final String shortName;
  final List<String> codes;
  final String image;

  const Bank({
    required this.id,
    required this.name,
    required this.shortName,
    required this.codes,
    required this.image,
  });
}

class AppConstants {
  static Map<String, List<String>> smsTemplates = {
    "cbe": [
      "Dear Babi your Account 1*****4345 has been debited with ETB3,000.00 .Service charge of  ETB10 and VAT(15%) of ETB1.50 with a total of ETB3011. Your Current Balance is ETB 14,016.34. Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT25344M3LMC61234345",
      "Dear Babi your Account 1****4345 has been credited with ETB 17000.00. Your Current Balance is ETB 17027.84. Thank you for Banking with CBE! https://apps.cbe.com.et:100/BranchReceipt/FT25343JTQ2D&61234345",
      "Dear Babi your Account 1*****4345 has been debited with ETB1,750.00 .Including Service charge and VAT(15%) with a total of ETB 1763.80. Your Current Balance is ETB 81.11. Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT25322FQMV061234345"
          "Dear Babi your Account 1*****4345 has been Credited with ETB 6,000.00 from Edom Getaneh, on 11/11/2025 at 06:27:52 with Ref No FT25315LT0PD Your Current Balance is ETB 7,702.41. Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT25315LT0PD61234345",
      "Dear Babi, You have transfered ETB 10,000.00 to Rediet Mesfin on 02/11/2025 at 15:40:42 from your account 1*****4345. Your account has been debited with a S.charge of ETB 2.00 and  15% VAT of ETB0.30, with a total of ETB10002.30. Your Current Balance is ETB 1,298.91. Thank you for Banking with CBE! https://apps.cbe.com.et:100/?id=FT253065G5TV61234345 For feedback click the link https://forms.gle/R1s9nkJ6qZVCxRVu9"
    ],
    "telebirr": [
      '''Dear BABA 
You have transferred ETB 300.00 to Tewodros Mulugeta (2519****4152) on 10/12/2025 11:04:39. Your transaction number is CLA7SLBW69. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 1,481.54. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CLA7SLBW69.

Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA
You have transferred ETB 110.00 successfully from your telebirr account 251933333333 to Commercial Bank of Ethiopia account number 1000473596478 on 10/12/2025 10:09:55. Your telebirr transaction number is CLA8SJM3OC and your bank transaction number is FT2534435C5Z. The service fee is  ETB 2.61 and  15% VAT on the service fee is ETB 0.39. Your current balance is ETB 1,783.54. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CLA8SJM3OC
Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA
You have paid ETB 514.99 for goods purchased from 515001 - MICHAEL GIRMA TAYE 4 KILO BRANCH on 10/12/2025 08:57:04. Your transaction number is  CLA2SHIC3E. Your current balance is ETB 1,896.54. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CLA2SHIC3E
Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA 
You have received ETB 3,000.00 from mengistu abajifar(2519****5284)  on 10/12/2025 07:33:30. Your transaction number is CLA2SFOPOQ. Your current E-Money Account balance is ETB 3,072.53.
Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA
You have paid ETB 7,724.00 to Ethiopian Airlines; Payment reference number DCOBPR on 04/12/2025 15:38:33. The service fee is  ETB 38.62 and  15% VAT on the service fee is ETB 5.79.. Your transaction number is CL42N9JJCA
Your telebirr account balance is  ETB 6,815.53.To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CL42N9JJCA  
Thank you for using telebirr   
Ethio telecom''',
      '''Dear BABA ABEBE 
You have paid ETB 75.20 to Addis Ababa Water and Sewerage Authority , Bill reference number 6972819 on 10/11/2025 10:04:23. The service fee is  ETB 2.00 and  15% VAT on the service fee is ETB 0.30. Your transaction number is CKA12SHWQV
Your telebirr account balance is ETB 62,875.37.
To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CKA12SHWQV
Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA
You have transferred ETB 20.00 successfully from your telebirr account 251933333333 to Amhara Bank SC account number 9900047003508 on 10/12/2025 15:44:17. Your telebirr transaction number is CLA5SUIXJ7 and your bank transaction number is FT253441MCKV. The service fee is  ETB 0.87 and  15% VAT on the service fee is ETB 0.13. Your current balance is ETB 1,460.54. To download your payment information please click this link: https://transactioninfo.ethiotelecom.et/receipt/CLA5SUIXJ7
Thank you for using telebirr
Ethio telecom''',
      '''Dear BABA,
You have received  ETB 10.00 by transaction number CLA4SUOHNM on 2025-12-10 15:48:31 from Amhara Bank SC to your telebirr Account 251933333333 - BABA ABEBE KASU. Your current balance is ETB 1,470.54.
Thank you for using telebirr
Ethio telecom'''
    ]
  };
  static const List<Bank> banks = [
    Bank(
      id: 1,
      name: "Commercial Bank Of Ethiopia",
      shortName: "CBE",
      codes: [
        "CBE",
        "cbe",
        "889",
        "Commercial Bank Of Ethiopia",
        "+251943685872",
        "+251920945085",
        "0920945085"
      ],
      image: "assets/images/cbe.png",
    ),
    Bank(
      id: 2,
      name: "Awash Bank",
      shortName: "Awash",
      codes: ["Awash", "Awash Bank"],
      image: "assets/images/awash.png",
    ),
    Bank(
      id: 3,
      name: "Cooperative Bank Of Oromia",
      shortName: "COOP",
      codes: ["COOP", "Cooperative Bank Of Oromia"],
      image: "assets/images/coop.png",
    ),
    Bank(
      id: 4,
      name: "Global Bank Ethiopia",
      shortName: "Global",
      codes: ["Global Bank", "Global"],
      image: "assets/images/global.png",
    ),
    Bank(
      id: 5,
      name: "Oromia International Bank",
      shortName: "OIB",
      codes: ["OIB", "Oromia International Bank"],
      image: "assets/images/oib.png",
    ),
    Bank(
      id: 6,
      name: "Telebirr",
      shortName: "Telebirr",
      codes: ["Telebirr", "telebirr", "127"],
      image: "assets/images/telebirr.png",
    ),
  ];
}
