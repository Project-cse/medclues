import { Pressable, StyleSheet, Text, View } from "react-native";
import { StatusPill } from "@/components/ui/StatusPill";
import { AvatarImage } from "@/components/ui/AvatarImage";
import { MedicalMetaIcon } from "@/components/ui/MedicalMetaIcon";
import { useColors } from "@/hooks/useColors";
import { formatSlotDate } from "@/utils/format";
import type { Appointment } from "@/types/domain";

export function AppointmentCard({
  appointment,
  showBadge = true,
  onPress,
}: {
  appointment: Appointment;
  showBadge?: boolean;
  onPress?: () => void;
}) {
  const colors = useColors();
  const isUpcoming =
    !appointment.cancelled &&
    !appointment.isCompleted &&
    appointment.status !== "cancelled" &&
    appointment.status !== "completed";

  const content = (
    <>
      <View style={[styles.avatarRing, { borderColor: colors.primaryTeal }]}>
        <AvatarImage uri={appointment.doctor.profilePicUrl} size={44} />
      </View>
      <View style={styles.body}>
        <Text style={[styles.name, { color: colors.textPrimary }]}>{appointment.doctor.name}</Text>
        {appointment.doctor.specialization ? (
          <Text style={[styles.spec, { color: colors.textSecondary }]}>
            {appointment.doctor.specialization}
          </Text>
        ) : null}
        <View style={styles.metaRow}>
          <MedicalMetaIcon variant="calendar" size={12} />
          <Text style={[styles.meta, { color: colors.textSecondary }]}>
            {formatSlotDate(appointment.date)} • {appointment.time}
          </Text>
        </View>
        {appointment.hospital.name ? (
          <View style={styles.metaRow}>
            <MedicalMetaIcon variant="hospital" size={12} />
            <Text style={[styles.hospital, { color: colors.textSecondary }]}>
              {appointment.hospital.name}
            </Text>
          </View>
        ) : null}
      </View>
      {showBadge && isUpcoming ? <StatusPill variant="upcoming" /> : null}
    </>
  );

  const cardStyle = [
    styles.card,
    colors.shadows.card,
    { backgroundColor: colors.white },
  ];

  if (onPress) {
    return (
      <Pressable style={cardStyle} onPress={onPress}>
        {content}
      </Pressable>
    );
  }

  return <View style={cardStyle}>{content}</View>;
}

const styles = StyleSheet.create({
  card: {
    flexDirection: "row",
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 14,
    gap: 12,
    alignItems: "flex-start",
  },
  avatarRing: {
    borderWidth: 2,
    borderRadius: 28,
    padding: 2,
    position: "relative",
  },
  body: { flex: 1 },
  name: { fontSize: 15, fontWeight: "700" },
  spec: { fontSize: 12, marginTop: 2 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 6 },
  meta: { fontSize: 12, flex: 1 },
  hospital: { fontSize: 11, flex: 1 },
});
