import '../utils/speciality_match.dart';

/// One searchable health concept → ranked specialty keys (must match [homeSpecialities] / doctor data).
class SymptomConcept {
  const SymptomConcept({
    required this.id,
    required this.label,
    required this.synonyms,
    required this.specialties,
  });

  final String id;
  final String label;
  /// Lowercase search phrases that resolve to this concept.
  final List<String> synonyms;
  /// Canonical specialty keys in priority order (see speciality_match / home specialities).
  final List<String> specialties;
}

/// Curated common searches. Expand over time; keep specialties aligned with app data.
const symptomConcepts = <SymptomConcept>[
  SymptomConcept(
    id: 'fever',
    label: 'Fever',
    synonyms: [
      'fever',
      'high fever',
      'high temperature',
      'temperature',
      'pyrexia',
      'body heat',
      'chills',
    ],
    specialties: ['general medicine', 'pediatrics'],
  ),
  SymptomConcept(
    id: 'cold_cough',
    label: 'Cold & cough',
    synonyms: [
      'cold',
      'cough',
      'flu',
      'running nose',
      'runny nose',
      'sneeze',
      'sore throat',
      'throat pain',
      'congestion',
    ],
    specialties: ['ent', 'general medicine', 'pediatrics'],
  ),
  SymptomConcept(
    id: 'headache',
    label: 'Headache',
    synonyms: [
      'headache',
      'migraine',
      'head pain',
      'head ache',
    ],
    specialties: ['neurology', 'general medicine'],
  ),
  SymptomConcept(
    id: 'chest_pain',
    label: 'Chest pain',
    synonyms: [
      'chest pain',
      'chest discomfort',
      'heart pain',
      'palpitation',
      'palpitations',
      'breathlessness',
      'shortness of breath',
    ],
    specialties: ['cardiology', 'general medicine'],
  ),
  SymptomConcept(
    id: 'stomach',
    label: 'Stomach pain',
    synonyms: [
      'stomach pain',
      'stomach ache',
      'abdomen pain',
      'abdominal pain',
      'gas',
      'acidity',
      'constipation',
      'diarrhea',
      'diarrhoea',
      'vomiting',
      'nausea',
      'indigestion',
      'ulcer',
    ],
    specialties: ['gastroenterology', 'general medicine'],
  ),
  SymptomConcept(
    id: 'skin',
    label: 'Skin / rash',
    synonyms: [
      'skin',
      'rash',
      'itching',
      'itch',
      'acne',
      'eczema',
      'psoriasis',
      'allergy skin',
      'hives',
      'hair fall',
      'dandruff',
    ],
    specialties: ['dermatology', 'pediatrics'],
  ),
  SymptomConcept(
    id: 'bone_joint',
    label: 'Bone / joint pain',
    synonyms: [
      'bone pain',
      'joint pain',
      'knee pain',
      'back pain',
      'neck pain',
      'fracture',
      'sprain',
      'arthritis',
      'shoulder pain',
      'hip pain',
    ],
    specialties: ['orthopedics'],
  ),
  SymptomConcept(
    id: 'eye',
    label: 'Eye problems',
    synonyms: [
      'eye',
      'eye pain',
      'blurred vision',
      'red eye',
      'vision',
      'cataract',
      'glasses',
    ],
    specialties: ['ophthalmology'],
  ),
  SymptomConcept(
    id: 'ear',
    label: 'Ear problems',
    synonyms: [
      'ear',
      'ear pain',
      'earache',
      'hearing',
      'deaf',
      'vertigo',
      'tinnitus',
    ],
    specialties: ['ent'],
  ),
  SymptomConcept(
    id: 'dental',
    label: 'Dental / tooth',
    synonyms: [
      'tooth',
      'teeth',
      'dental',
      'toothache',
      'gum',
      'cavity',
      'wisdom tooth',
    ],
    specialties: ['dentistry'],
  ),
  SymptomConcept(
    id: 'women',
    label: "Women's health",
    synonyms: [
      'pregnancy',
      'pregnant',
      'period',
      'periods',
      'menstrual',
      'pcos',
      'gynec',
      'gynaec',
      'women',
      'uterus',
    ],
    specialties: ['gynecology'],
  ),
  SymptomConcept(
    id: 'child',
    label: 'Child health',
    synonyms: [
      'child',
      'baby',
      'infant',
      'kids',
      'vaccination',
      'pediatric',
      'paediatric',
    ],
    specialties: ['pediatrics'],
  ),
  SymptomConcept(
    id: 'mental',
    label: 'Stress / mental health',
    synonyms: [
      'depression',
      'anxiety',
      'stress',
      'sleep',
      'insomnia',
      'mental',
      'panic',
    ],
    specialties: ['psychiatry'],
  ),
  SymptomConcept(
    id: 'neuro',
    label: 'Nerve / brain',
    synonyms: [
      'seizure',
      'epilepsy',
      'stroke',
      'numbness',
      'tingling',
      'paralysis',
      'memory',
      'parkinson',
    ],
    specialties: ['neurology'],
  ),
  SymptomConcept(
    id: 'diabetes',
    label: 'Diabetes',
    synonyms: [
      'diabetes',
      'sugar',
      'blood sugar',
      'thyroid',
      'hormone',
    ],
    specialties: ['general medicine'],
  ),
  SymptomConcept(
    id: 'bp',
    label: 'Blood pressure',
    synonyms: [
      'bp',
      'blood pressure',
      'hypertension',
      'high bp',
      'low bp',
    ],
    specialties: ['cardiology', 'general medicine'],
  ),
  SymptomConcept(
    id: 'allergy',
    label: 'Allergy / asthma',
    synonyms: [
      'allergy',
      'allergic',
      'asthma',
      'wheeze',
      'breathing problem',
    ],
    specialties: ['general medicine', 'ent', 'pediatrics'],
  ),
  SymptomConcept(
    id: 'uti',
    label: 'Urinary problems',
    synonyms: [
      'uti',
      'urine',
      'urinary',
      'burning urine',
      'kidney pain',
    ],
    specialties: ['general medicine', 'gynecology'],
  ),
  SymptomConcept(
    id: 'general',
    label: 'General checkup',
    synonyms: [
      'checkup',
      'check up',
      'general',
      'weakness',
      'fatigue',
      'tired',
      'body pain',
      'infection',
    ],
    specialties: ['general medicine'],
  ),
];

/// Popular chips shown before / with search.
const popularSymptomChips = <String>[
  'Fever',
  'Cold & cough',
  'Headache',
  'Stomach pain',
  'Skin rash',
  'Chest pain',
  'Tooth pain',
  'Diabetes',
];

class SymptomMatchResult {
  const SymptomMatchResult({
    required this.concept,
    required this.specialties,
  });

  final SymptomConcept? concept;
  final List<String> specialties;

  bool get hasMatch => specialties.isNotEmpty;
}

/// Resolve free-text query to ranked specialty keys.
SymptomMatchResult resolveSymptomQuery(String raw) {
  final q = raw.toLowerCase().trim();
  if (q.isEmpty) {
    return const SymptomMatchResult(concept: null, specialties: []);
  }

  // Direct specialty name / alias (e.g. "cardiology", "ortho").
  final direct = canonicalSpecialityKey(q);
  if (direct != null) {
    return SymptomMatchResult(concept: null, specialties: [direct]);
  }

  SymptomConcept? best;
  var bestScore = 0;
  for (final c in symptomConcepts) {
    for (final syn in c.synonyms) {
      if (q == syn) {
        return SymptomMatchResult(concept: c, specialties: List.of(c.specialties));
      }
      if (q.contains(syn) || syn.contains(q)) {
        final score = syn.length;
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
    }
    if (q.contains(c.label.toLowerCase())) {
      final score = c.label.length;
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
  }

  if (best != null) {
    return SymptomMatchResult(concept: best, specialties: List.of(best.specialties));
  }

  // Weak fallback: any specialty alias substring in query.
  final found = <String>{};
  for (final key in [
    'cardiology',
    'orthopedics',
    'psychiatry',
    'ophthalmology',
    'ent',
    'dentistry',
    'general medicine',
    'gynecology',
    'dermatology',
    'pediatrics',
    'neurology',
    'gastroenterology',
  ]) {
    if (matchesSpeciality(key, q) || matchesSpeciality(q, key)) {
      found.add(key);
    }
  }
  if (found.isNotEmpty) {
    return SymptomMatchResult(concept: null, specialties: found.toList());
  }

  return const SymptomMatchResult(concept: null, specialties: []);
}

String specialtyDisplayName(String key) {
  switch (key) {
    case 'ent':
      return 'ENT';
    case 'general medicine':
      return 'General Medicine';
    default:
      if (key.isEmpty) return key;
      return key
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
  }
}
