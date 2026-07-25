import { router, type Href } from "expo-router";

/** Typed-route workaround until Expo regenerates `.expo/types` */
export function navigate(href: string) {
  router.push(href as Href);
}

export function replace(href: string) {
  router.replace(href as Href);
}
