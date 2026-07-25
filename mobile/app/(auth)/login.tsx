import { Redirect } from "expo-router";

/** Legacy route — patient login is the default entry */
export default function LoginRedirect() {
  return <Redirect href="/(auth)/login-patient" />;
}
