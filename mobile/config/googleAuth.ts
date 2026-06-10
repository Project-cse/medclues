import { Platform } from "react-native";
import Constants from "expo-constants";
import * as AuthSession from "expo-auth-session";

/** Web client ID from Firebase → Authentication → Google → Web SDK */
export const GOOGLE_WEB_CLIENT_ID =
  process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID?.trim() ?? "";

/**
 * Android OAuth client (type "Android" in Google Cloud — NOT the web client).
 * Required for Google sign-in on physical Android / Expo Go.
 */
export const GOOGLE_ANDROID_CLIENT_ID =
  process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID?.trim() ?? "";

export const GOOGLE_IOS_CLIENT_ID =
  process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID?.trim() ?? GOOGLE_WEB_CLIENT_ID;

export const isExpoGo = Constants.appOwnership === "expo";

export function getGoogleRedirectUri(): string {
  return AuthSession.makeRedirectUri({
    scheme: "medichain",
    path: "oauth2redirect",
    preferLocalhost: false,
  });
}

/** Native Android redirect Google expects when using an Android OAuth client */
export function getAndroidNativeRedirectUri(androidClientId: string): string | null {
  if (!androidClientId.endsWith(".apps.googleusercontent.com")) return null;
  const prefix = androidClientId.replace(".apps.googleusercontent.com", "");
  return `com.googleusercontent.apps.${prefix}:/oauth2redirect`;
}

/** True when Android is using web client ID instead of a dedicated Android OAuth client */
export function isAndroidUsingWebClientFallback(): boolean {
  return Platform.OS === "android" && !GOOGLE_ANDROID_CLIENT_ID && !!GOOGLE_WEB_CLIENT_ID;
}

export function getGoogleAuthSetupHint(): string | null {
  if (!GOOGLE_WEB_CLIENT_ID) {
    return "Add EXPO_PUBLIC_GOOGLE_CLIENT_ID to mobile/.env (Firebase Web client ID).";
  }
  return null;
}

export function getGoogleAuthAndroidWarning(): string | null {
  if (isAndroidUsingWebClientFallback()) {
    return (
      "Add EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID in mobile/.env for Google login on Android. " +
      "See mobile/GOOGLE_SIGNIN.md"
    );
  }
  return null;
}

/** expo-auth-session requires androidClientId on Android — never leave it undefined */
export function resolveAndroidClientId(): string | undefined {
  if (Platform.OS !== "android") return undefined;
  return GOOGLE_ANDROID_CLIENT_ID || GOOGLE_WEB_CLIENT_ID || undefined;
}

export function logGoogleAuthDebug(): void {
  if (!__DEV__) return;
  const redirect = getGoogleRedirectUri();
  const androidNative = GOOGLE_ANDROID_CLIENT_ID
    ? getAndroidNativeRedirectUri(GOOGLE_ANDROID_CLIENT_ID)
    : null;
  console.log("[Google Auth] Expo Go:", isExpoGo);
  console.log("[Google Auth] Redirect URI:", redirect);
  if (androidNative) console.log("[Google Auth] Android native redirect:", androidNative);
}
