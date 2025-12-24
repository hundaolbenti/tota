class Bank {
  final int id;
  final String name;
  final String shortName;
  final List<String> codes;
  final String image;
  final String? currency;
  final int? maskPattern;
  final bool? uniformMasking;
  final bool? simBased;
  final List<String>? colors;

  const Bank({
    required this.id,
    required this.name,
    required this.shortName,
    required this.codes,
    required this.image,
    this.currency,
    this.maskPattern,
    this.uniformMasking,
    this.simBased,
    this.colors,
  });


  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'],
      codes: json['codes'] != null ? List<String>.from(json['codes']) : [],
      image: json['image'],
      currency: json['currency'],
      maskPattern: json['maskPattern'],
      uniformMasking: json['uniformMasking'],
      simBased: json['simBased'],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'codes': codes,
      'image': image,
      'currency': currency,
      'maskPattern': maskPattern,
      'uniformMasking': uniformMasking,
      'simBased': simBased,
      'colors': colors,
    };
  }
}

