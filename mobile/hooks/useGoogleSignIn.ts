import { useCallback, useEffect, useState } from "react";
import { Platform } from "react-native";
import * as WebBrowser from "expo-web-browser";
import * as Google from "expo-auth-session/providers/google";
import { GoogleAuthProvider, signInWithCredential } from "firebase/auth";
import { getFirebaseAuth, isFirebaseConfigured } from "@/services/firebase";
import { authService } from "@/services/auth";
import { useAuthStore } from "@/store/authStore";
import api from "@/services/api";
import { getPostLoginRoute } from "@/utils/authRoutes";
import type { Href } from "expo-router";
import {
  GOOGLE_IOS_CLIENT_ID,
  GOOGLE_WEB_CLIENT_ID,
  getGoogleAuthAndroidWarning,
  getGoogleAuthSetupHint,
  isAndroidUsingWebClientFallback,
  logGoogleAuthDebug,
  resolveAndroidClientId,
} from "@/config/googleAuth";

WebBrowser.maybeCompleteAuthSession();

type Raw = Record<string, unknown>;

export function useGoogleSignIn(onSuccess?: () => void) {
  const [loading, setLoading] = useState(false);
  const setupHint = getGoogleAuthSetupHint();
  const androidWarning = getGoogleAuthAndroidWarning();
  const androidClientId = resolveAndroidClientId();

  const [request, , promptAsync] = Google.useIdTokenAuthRequest(
    {
      webClientId: GOOGLE_WEB_CLIENT_ID,
      androidClientId,
      iosClientId: GOOGLE_IOS_CLIENT_ID || GOOGLE_WEB_CLIENT_ID,
    },
    { scheme: "medichain", path: "oauth2redirect", preferLocalhost: false }
  );

  useEffect(() => {
    logGoogleAuthDebug();
  }, []);

  const completeSignIn = useCallback(
    async (idToken: string, accessToken?: string) => {
      const credential = GoogleAuthProvider.credential(idToken, accessToken);
      const result = await signInWithCredential(getFirebaseAuth(), credential);
      const firebaseUser = result.user;

      if (!firebaseUser.email) {
        throw new Error("Google account has no email");
      }

      const { data } = await api.post<Raw>("/api/user/social-login", {
        email: firebaseUser.email,
        name: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        provider: "google",
        uid: firebaseUser.uid,
      });

      if (!data.success || !data.token) {
        throw new Error(String(data.message ?? "Google sign-in failed"));
      }

      const token = String(data.token);
      await useAuthStore.getState().setAuth(token, {
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? "",
        email: firebaseUser.email,
        role: "patient",
        branch_id: null,
        image: firebaseUser.photoURL ?? undefined,
      });

      try {
        const me = await authService.getMe();
        await useAuthStore.getState().setAuth(token, {
          id: me.id,
          name: me.name,
          email: me.email ?? firebaseUser.email,
          role: "patient",
          branch_id: null,
          phone: me.phone,
          image: me.profilePicUrl ?? firebaseUser.photoURL ?? undefined,
        });
      } catch {
        /* profile optional */
      }

      onSuccess?.();
      return getPostLoginRoute("patient");
    },
    [onSuccess]
  );

  const signIn = useCallback(async (): Promise<{
    ok: boolean;
    error?: string;
    route?: Href;
  }> => {
    if (!isFirebaseConfigured()) {
      return {
        ok: false,
        error:
          "Firebase is not configured. Add EXPO_PUBLIC_FIREBASE_* to mobile/.env (copy from frontend/.env).",
      };
    }
    if (setupHint) {
      return { ok: false, error: setupHint };
    }
    if (isAndroidUsingWebClientFallback()) {
      return {
        ok: false,
        error:
          "Android needs a separate Google OAuth client. Add EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID to mobile/.env — see GOOGLE_SIGNIN.md",
      };
    }
    if (!request) {
      return { ok: false, error: "Google sign-in is not ready yet. Try again." };
    }

    setLoading(true);
    try {
      const result = await promptAsync();
      if (result.type === "success") {
        const idToken = result.params.id_token;
        const accessToken = result.authentication?.accessToken;
        if (!idToken && !accessToken) {
          return { ok: false, error: "No token from Google" };
        }
        const route = await completeSignIn(idToken ?? "", accessToken);
        return { ok: true, route };
      }
      if (result.type === "cancel" || result.type === "dismiss") {
        return { ok: false, error: "cancelled" };
      }
      return {
        ok: false,
        error:
          "Google blocked sign-in (Error 400). Add Android OAuth client ID in mobile/.env — see GOOGLE_SIGNIN.md",
      };
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Google sign-in failed";
      return { ok: false, error: msg };
    } finally {
      setLoading(false);
    }
  }, [setupHint, request, promptAsync, completeSignIn]);

  const ready = Boolean(request) && !setupHint && Boolean(GOOGLE_WEB_CLIENT_ID);

  return {
    signIn,
    loading,
    ready,
    setupHint,
    androidWarning,
    configured: Boolean(GOOGLE_WEB_CLIENT_ID),
  };
}
