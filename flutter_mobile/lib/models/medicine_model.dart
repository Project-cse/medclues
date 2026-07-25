class MedicineCard {
  MedicineCard({
    required this.medicineKey,
    required this.medicineName,
    this.brandName,
    this.genericName,
    this.manufacturer,
    this.dosageForm,
    this.route,
    this.shortDescription,
    this.placeholderType = 'tablet',
  });

  final String medicineKey;
  final String medicineName;
  final String? brandName;
  final String? genericName;
  final String? manufacturer;
  final String? dosageForm;
  final String? route;
  final String? shortDescription;
  final String placeholderType;

  factory MedicineCard.fromJson(Map<String, dynamic> json) {
    return MedicineCard(
      medicineKey: '${json['medicineKey'] ?? ''}',
      medicineName: '${json['medicineName'] ?? json['brandName'] ?? 'Medicine'}',
      brandName: json['brandName']?.toString(),
      genericName: json['genericName']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      dosageForm: json['dosageForm']?.toString(),
      route: json['route']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      placeholderType: '${json['placeholderType'] ?? 'tablet'}',
    );
  }
}

class MedicineDetails {
  MedicineDetails({
    required this.medicineKey,
    required this.medicineName,
    this.brandName,
    this.genericName,
    this.manufacturer,
    this.purpose,
    this.uses,
    this.indications,
    this.activeIngredients = const [],
    this.inactiveIngredients = const [],
    this.dosageForm,
    this.route,
    this.warnings,
    this.boxedWarning,
    this.pregnancyWarning,
    this.pediatricUse,
    this.geriatricUse,
    this.drugAbuse,
    this.drugInteractions,
    this.contraindications,
    this.sideEffects,
    this.storage,
    this.howSupplied,
    this.packageLabel,
    this.stopUse,
    this.askDoctor,
    this.doNotUse,
    this.dosageAndAdministration,
    this.placeholderType = 'tablet',
  });

  final String medicineKey;
  final String medicineName;
  final String? brandName;
  final String? genericName;
  final String? manufacturer;
  final String? purpose;
  final String? uses;
  final String? indications;
  final List<String> activeIngredients;
  final List<String> inactiveIngredients;
  final String? dosageForm;
  final String? route;
  final String? warnings;
  final String? boxedWarning;
  final String? pregnancyWarning;
  final String? pediatricUse;
  final String? geriatricUse;
  final String? drugAbuse;
  final String? drugInteractions;
  final String? contraindications;
  final String? sideEffects;
  final String? storage;
  final String? howSupplied;
  final String? packageLabel;
  final String? stopUse;
  final String? askDoctor;
  final String? doNotUse;
  final String? dosageAndAdministration;
  final String placeholderType;

  factory MedicineDetails.fromJson(Map<String, dynamic> json) {
    List<String> listOf(dynamic v) {
      if (v is List) {
        return v.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    return MedicineDetails(
      medicineKey: '${json['medicineKey'] ?? ''}',
      medicineName: '${json['medicineName'] ?? 'Medicine'}',
      brandName: json['brandName']?.toString(),
      genericName: json['genericName']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      purpose: json['purpose']?.toString(),
      uses: json['uses']?.toString(),
      indications: json['indications']?.toString(),
      activeIngredients: listOf(json['activeIngredients']),
      inactiveIngredients: listOf(json['inactiveIngredients']),
      dosageForm: json['dosageForm']?.toString(),
      route: json['route']?.toString(),
      warnings: json['warnings']?.toString(),
      boxedWarning: json['boxedWarning']?.toString(),
      pregnancyWarning: json['pregnancyWarning']?.toString(),
      pediatricUse: json['pediatricUse']?.toString(),
      geriatricUse: json['geriatricUse']?.toString(),
      drugAbuse: json['drugAbuse']?.toString(),
      drugInteractions: json['drugInteractions']?.toString(),
      contraindications: json['contraindications']?.toString(),
      sideEffects: json['sideEffects']?.toString(),
      storage: json['storage']?.toString(),
      howSupplied: json['howSupplied']?.toString(),
      packageLabel: json['packageLabel']?.toString(),
      stopUse: json['stopUse']?.toString(),
      askDoctor: json['askDoctor']?.toString(),
      doNotUse: json['doNotUse']?.toString(),
      dosageAndAdministration: json['dosageAndAdministration']?.toString(),
      placeholderType: '${json['placeholderType'] ?? 'tablet'}',
    );
  }

  MedicineCard toCard() => MedicineCard(
        medicineKey: medicineKey,
        medicineName: medicineName,
        brandName: brandName,
        genericName: genericName,
        manufacturer: manufacturer,
        dosageForm: dosageForm,
        route: route,
        shortDescription: purpose ?? indications,
        placeholderType: placeholderType,
      );
}
