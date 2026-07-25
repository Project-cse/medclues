import { StyleSheet, Text, View } from "react-native";
import { GoogleSignInButton } from "@/components/auth/GoogleSignInButton";
import { useGoogleSignIn } from "@/hooks/useGoogleSignIn";
import { GOOGLE_WEB_CLIENT_ID } from "@/config/googleAuth";
import { isFirebaseConfigured } from "@/services/firebase";
import { router } from "expo-router";
import { useToast } from "@/providers/ToastProvider";
import { useQueryClient } from "@tanstack/react-query";
import { prefetchPatientData } from "@/hooks/usePatientData";

/**
 * Isolated so useGoogleSignIn (and Google.useIdTokenAuthRequest) only runs
 * when Firebase web client ID is configured.
 */
export function PatientGoogleSignIn() {
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const google = useGoogleSignIn();

  if (!GOOGLE_WEB_CLIENT_ID || !isFirebaseConfigured()) {
    return null;
  }

  const handleGoogle = async () => {
    const result = await google.signIn();
    if (result.ok && result.route) {
      await prefetchPatientData(queryClient);
      showToast("Signed in with Google!", "success");
      router.replace(result.route);
      return;
    }
    if (result.error && result.error !== "cancelled") {
      showToast(result.error, "error");
    }
  };

  return (
    <View>
      <GoogleSignInButton
        onPress={handleGoogle}
        loading={google.loading}
        disabled={!google.ready}
      />
      {google.setupHint ? <Text style={styles.warn}>{google.setupHint}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  warn: {
    marginTop: 10,
    fontSize: 11,
    color: "#C0392B",
    fontFamily: "Poppins_400Regular",
    lineHeight: 16,
  },
});
