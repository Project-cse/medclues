/// Fixed profile field options (signup + personal info).
class ProfileOptions {
  ProfileOptions._();

  static const genderItems = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Other'),
  ];

  static const bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const placeholderValues = {
    'not selected',
    'dd-mm-yyyy',
    'n/a',
    'na',
    '-',
  };

  static String? sanitize(String? value) {
    if (value == null) return null;
    final t = value.trim();
    if (t.isEmpty) return null;
    if (placeholderValues.contains(t.toLowerCase())) return null;
    return t;
  }

  static String? normalizeGender(String? value) {
    final t = sanitize(value)?.toLowerCase();
    if (t == null) return null;
    for (final item in genderItems) {
      if (t == item.$1 || t == item.$2.toLowerCase()) return item.$1;
    }
    if (t == 'm') return 'male';
    if (t == 'f') return 'female';
    if (t.contains('prefer')) return 'other';
    return null;
  }

  static String? normalizeBloodGroup(String? value) {
    final t = sanitize(value)?.toUpperCase();
    if (t == null) return null;
    return bloodGroups.contains(t) ? t : null;
  }
}
