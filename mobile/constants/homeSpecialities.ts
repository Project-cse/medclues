import type { Ionicons } from "@expo/vector-icons";

export type HomeSpeciality = {
  name: string;
  filterKey: string;
  icon: keyof typeof Ionicons.glyphMap;
};

export const HOME_SPECIALITIES: HomeSpeciality[] = [
  { name: "Cardiology", filterKey: "cardiology", icon: "heart" },
  { name: "Orthopedics", filterKey: "orthopedics", icon: "body" },
  { name: "Psychiatry", filterKey: "psychiatry", icon: "happy" },
  { name: "Ophthalmology", filterKey: "ophthalmology", icon: "eye" },
  { name: "ENT", filterKey: "ent", icon: "ear" },
  { name: "Dentistry", filterKey: "dentistry", icon: "medical" },
  { name: "General Medicine", filterKey: "general medicine", icon: "medkit" },
  { name: "Gynecology", filterKey: "gynecology", icon: "female" },
  { name: "Dermatology", filterKey: "dermatology", icon: "color-palette" },
  { name: "Pediatrics", filterKey: "pediatrics", icon: "happy-outline" },
  { name: "Neurology", filterKey: "neurology", icon: "pulse" },
  { name: "Gastroenterology", filterKey: "gastroenterology", icon: "nutrition" },
];
