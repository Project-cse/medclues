import { useState } from "react";
import { Redirect } from "expo-router";
import { AmbulanciaStartupSplash } from "@/components/animations/AmbulanciaStartupSplash";
import { useAuth } from "@/hooks/useAuth";
import { getPostLoginRoute } from "@/utils/authRoutes";

export default function Index() {
  const { isAuthenticated, isHydrated, user } = useAuth();
  const [splashDone, setSplashDone] = useState(false);

  if (!isHydrated) return null;

  if (!splashDone) {
    return <AmbulanciaStartupSplash onFinish={() => setSplashDone(true)} />;
  }

  if (isAuthenticated && user?.role) {
    return <Redirect href={getPostLoginRoute(user.role)} />;
  }

  return <Redirect href="/(auth)/login-patient" />;
}
