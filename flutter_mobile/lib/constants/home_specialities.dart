import 'speciality_assets.dart';

class HomeSpeciality {
  const HomeSpeciality({
    required this.name,
    required this.filterKey,
    required this.assetPath,
  });

  final String name;
  final String filterKey;
  final String assetPath;
}

/// Fixed 12 specialties — 4 columns × 3 rows on home dashboard.
List<HomeSpeciality> get homeSpecialities {
  const specs = [
    ('Cardiology', 'cardiology'),
    ('Orthopedics', 'orthopedics'),
    ('Psychiatry', 'psychiatry'),
    ('Ophthalmology', 'ophthalmology'),
    ('ENT', 'ent'),
    ('Dentistry', 'dentistry'),
    ('General Medicine', 'general medicine'),
    ('Gynecology', 'gynecology'),
    ('Dermatology', 'dermatology'),
    ('Pediatrics', 'pediatrics'),
    ('Neurology', 'neurology'),
    ('Gastroenterology', 'gastroenterology'),
  ];
  return specs
      .map(
        (s) => HomeSpeciality(
          name: s.$1,
          filterKey: s.$2,
          assetPath: SpecialityAssets.assetPathFor(s.$1) ?? '',
        ),
      )
      .where((s) => s.assetPath.isNotEmpty)
      .toList();
}
