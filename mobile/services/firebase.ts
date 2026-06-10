/**
 * Firebase for React Native / Expo (same project as frontend).
 * Lazy-init so missing .env keys do not crash the app at import time.
 */
import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import type { Auth } from "firebase/auth";
import ReactNativeAsyncStorage from "@react-native-async-storage/async-storage";

// Metro resolves this path; the package "exports" field does not expose it.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { getReactNativePersistence, initializeAuth, getAuth } = require(
  "@firebase/auth/dist/rn/index.js"
) as {
  getReactNativePersistence: (storage: typeof ReactNativeAsyncStorage) => unknown;
  initializeAuth: (
    app: FirebaseApp,
    opts: { persistence: unknown }
  ) => Auth;
  getAuth: (app: FirebaseApp) => Auth;
};

const firebaseConfig = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY?.trim() ?? "",
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN?.trim() ?? "",
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID?.trim() ?? "",
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET?.trim() ?? "",
  messagingSenderId:
    process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID?.trim() ?? "",
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID?.trim() ?? "",
};

export function isFirebaseConfigured(): boolean {
  return Boolean(
    firebaseConfig.apiKey &&
      firebaseConfig.authDomain &&
      firebaseConfig.projectId &&
      firebaseConfig.appId
  );
}

let app: FirebaseApp | null = null;
let authInstance: Auth | null = null;

function getFirebaseApp(): FirebaseApp {
  if (!isFirebaseConfigured()) {
    throw new Error(
      "Firebase is not configured. Copy VITE_FIREBASE_* from frontend/.env into mobile/.env as EXPO_PUBLIC_FIREBASE_*."
    );
  }
  if (!app) {
    app = getApps().length > 0 ? getApps()[0]! : initializeApp(firebaseConfig);
  }
  return app;
}

/** Auth with AsyncStorage persistence — initialized on first Google sign-in. */
export function getFirebaseAuth(): Auth {
  if (!authInstance) {
    const firebaseApp = getFirebaseApp();
    try {
      authInstance = initializeAuth(firebaseApp, {
        persistence: getReactNativePersistence(ReactNativeAsyncStorage),
      });
    } catch (error: unknown) {
      const code =
        error && typeof error === "object" && "code" in error
          ? String((error as { code: string }).code)
          : "";
      if (code === "auth/already-initialized") {
        authInstance = getAuth(firebaseApp);
      } else {
        throw error;
      }
    }
  }
  return authInstance;
}

export default function getDefaultFirebaseApp(): FirebaseApp {
  return getFirebaseApp();
}
