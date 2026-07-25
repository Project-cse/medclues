/// Port of mobile/utils/specialityMatch.ts
const _aliases = <String, List<String>>{
  'cardiology': ['cardiol', 'cardiac', 'heart', 'cardiologist'],
  'orthopedics': ['orthop', 'orthopaedic', 'bone', 'ortho', 'orthoped'],
  'psychiatry': ['psychiat', 'psych', 'psychiatrist'],
  'ophthalmology': ['ophthal', 'eye', 'optomet', 'ophthalmologist'],
  'ent': ['otolaryng', 'ear', 'throat', 'ent'],
  'dentistry': ['dental', 'dentist', 'tooth', 'oral'],
  'general medicine': ['general physician', 'general medic', 'physician', 'gp', 'internal'],
  'gynecology': ['gynec', 'gynaec', 'obstetric', 'obgyn', 'gynecologist'],
  'dermatology': ['dermat', 'skin', 'dermatologist'],
  'pediatrics': ['pediatr', 'paediatr', 'child', 'paediatric', 'pediatrician', 'pediatricians'],
  'neurology': ['neurolog', 'neuro', 'brain', 'neurologist'],
  'gastroenterology': ['gastro', 'gastroenterol', 'digest', 'gastroenterologist'],
};

bool matchesSpeciality(String specialization, String query) {
  final spec = specialization.toLowerCase().trim();
  final target = query.toLowerCase().trim();
  if (spec.isEmpty || target.isEmpty) return false;
  if (spec.contains(target) || target.contains(spec)) return true;

  final aliases = _aliases[target];
  if (aliases != null && aliases.any((a) => spec.contains(a))) return true;

  for (final entry in _aliases.entries) {
    final key = entry.key;
    if (target.contains(key) || key.contains(target)) {
      if (entry.value.any((w) => spec.contains(w)) || spec.contains(key)) return true;
    }
  }

  return false;
}

/// Resolve home/dashboard label to canonical speciality key for strict filtering.
String? canonicalSpecialityKey(String query) {
  final target = query.toLowerCase().trim();
  if (target.isEmpty) return null;
  if (_aliases.containsKey(target)) return target;
  for (final key in _aliases.keys) {
    if (target.contains(key) || key.contains(target)) return key;
    if (_aliases[key]!.any((a) => target.contains(a))) return key;
  }
  return null;
}

String formatSpecialityTitle(String filterKey) {
  final s = filterKey.trim();
  if (s.isEmpty) return 'Doctors';
  if (s.length == 1) return '${s.toUpperCase()} Doctors';
  return '${s[0].toUpperCase()}${s.substring(1)} Doctors';
}
