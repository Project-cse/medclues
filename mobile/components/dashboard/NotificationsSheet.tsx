import {
  Modal,
  Pressable,
  ScrollView,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import type { Notification } from "@/types/api";
import { AmbulanciaLottie } from "@/components/lottie/AmbulanciaLottie";
import { EmptyState } from "./EmptyState";
import { ListSkeleton } from "./Skeleton";

interface NotificationsSheetProps {
  visible: boolean;
  onClose: () => void;
  notifications: Notification[];
  loading?: boolean;
  onMarkRead: (id: string) => void;
}

export function NotificationsSheet({
  visible,
  onClose,
  notifications,
  loading,
  onMarkRead,
}: NotificationsSheetProps) {
  const insets = useSafeAreaInsets();

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onClose}
    >
      <Pressable className="flex-1 bg-black/40" onPress={onClose} />
      <View
        className="max-h-[75%] rounded-t-3xl bg-white"
        style={{ paddingBottom: insets.bottom + 16 }}
      >
        <View className="items-center py-3">
          <View className="h-1 w-10 rounded-full bg-slate-300" />
        </View>

        <View className="flex-row items-center justify-between border-b border-slate-100 px-5 pb-3">
          <Text className="text-xl font-bold text-slate-900">Notifications</Text>
          <Pressable onPress={onClose} hitSlop={12}>
            <Ionicons name="close" size={24} color="#64748b" />
          </Pressable>
        </View>

        {loading ? (
          <View className="py-4">
            <ListSkeleton rows={4} />
          </View>
        ) : (
          <ScrollView className="px-5 pt-3" showsVerticalScrollIndicator={false}>
            {notifications.length === 0 ? (
              <EmptyState
                icon="notifications-off-outline"
                title="All caught up"
                message="No new notifications right now."
              />
            ) : (
              notifications.map((n) => (
                <Pressable
                  key={n.id}
                  onPress={() => !n.read && onMarkRead(n.id)}
                  className={`mb-2 flex-row gap-3 rounded-xl p-4 ${
                    n.read ? "bg-slate-50" : "bg-primary-50"
                  }`}
                >
                  {n.type === "emergency" ? (
                    <AmbulanciaLottie width={50} height={50} loop autoPlay />
                  ) : (
                    <View
                      className={`h-10 w-10 items-center justify-center rounded-full ${
                        n.read ? "bg-slate-200" : "bg-primary-100"
                      }`}
                    >
                      <Ionicons
                        name={
                          n.type === "payment"
                            ? "card-outline"
                            : n.type === "alert"
                              ? "warning-outline"
                              : "calendar-outline"
                        }
                        size={20}
                        color="#2563EB"
                      />
                    </View>
                  )}
                  <View className="flex-1">
                    <Text className="font-semibold text-slate-900">{n.title}</Text>
                    <Text className="mt-0.5 text-sm text-slate-600">{n.body}</Text>
                  </View>
                  {!n.read ? (
                    <View className="h-2 w-2 rounded-full bg-primary-600 self-center" />
                  ) : null}
                </Pressable>
              ))
            )}
          </ScrollView>
        )}
      </View>
    </Modal>
  );
}
