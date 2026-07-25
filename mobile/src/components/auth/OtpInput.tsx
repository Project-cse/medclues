import { useEffect, useRef, useState } from "react";
import {
  Animated,
  StyleSheet,
  TextInput,
  View,
  type NativeSyntheticEvent,
  type TextInputKeyPressEventData,
} from "react-native";
import { getAuthTheme, type AuthThemeKey } from "@/src/utils/authTheme";

type Props = {
  theme: AuthThemeKey;
  onComplete: (code: string) => void;
  shakeAnim: Animated.Value;
};

export function OtpInput({ theme, onComplete, shakeAnim }: Props) {
  const colors = getAuthTheme(theme);
  const [digits, setDigits] = useState(["", "", "", "", "", ""]);
  const [focused, setFocused] = useState(0);
  const refs = useRef<(TextInput | null)[]>([]);

  useEffect(() => {
    const t = setTimeout(() => refs.current[0]?.focus(), 300);
    return () => clearTimeout(t);
  }, []);

  const code = digits.join("");

  useEffect(() => {
    if (code.length === 6) onComplete(code);
  }, [code, onComplete]);

  const setDigit = (index: number, value: string) => {
    const next = [...digits];
    next[index] = value;
    setDigits(next);
  };

  const onChange = (index: number, text: string) => {
    const cleaned = text.replace(/\D/g, "");
    if (cleaned.length > 1) {
      const pasted = cleaned.slice(0, 6).split("");
      const next = ["", "", "", "", "", ""];
      pasted.forEach((ch, i) => {
        next[i] = ch;
      });
      setDigits(next);
      const last = Math.min(pasted.length, 5);
      refs.current[last]?.focus();
      setFocused(last);
      return;
    }
    setDigit(index, cleaned);
    if (cleaned && index < 5) {
      refs.current[index + 1]?.focus();
      setFocused(index + 1);
    }
  };

  const onKeyPress = (
    index: number,
    e: NativeSyntheticEvent<TextInputKeyPressEventData>
  ) => {
    if (e.nativeEvent.key === "Backspace" && !digits[index] && index > 0) {
      refs.current[index - 1]?.focus();
      setFocused(index - 1);
    }
  };

  const allFilled = digits.every((d) => d.length === 1);

  return (
    <Animated.View style={[styles.row, { transform: [{ translateX: shakeAnim }] }]}>
      {digits.map((d, i) => {
        const isFocus = focused === i;
        const borderColor = allFilled
          ? "#22C55E"
          : isFocus
            ? colors.primary
            : "#CBD5E1";
        return (
          <TextInput
            key={i}
            ref={(r) => {
              refs.current[i] = r;
            }}
            style={[styles.box, { borderColor }]}
            value={d}
            onChangeText={(t) => onChange(i, t)}
            onKeyPress={(e) => onKeyPress(i, e)}
            onFocus={() => setFocused(i)}
            keyboardType="number-pad"
            maxLength={6}
            selectTextOnFocus
            textAlign="center"
          />
        );
      })}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    justifyContent: "center",
    gap: 8,
    marginVertical: 16,
  },
  box: {
    width: 44,
    height: 54,
    borderRadius: 12,
    borderWidth: 2,
    fontSize: 22,
    fontFamily: "Poppins_700Bold",
    color: "#0F172A",
    backgroundColor: "#F8FAFC",
  },
});
