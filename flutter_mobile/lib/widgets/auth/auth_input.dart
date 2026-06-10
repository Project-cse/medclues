import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_login_theme.dart';

class AuthInput extends StatefulWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.hintText,
    this.onFocusChange,
    this.premium = true,
    this.bottomGap = 20,
    this.autofillHints,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final String? hintText;
  final ValueChanged<bool>? onFocusChange;
  final bool premium;
  final double bottomGap;
  final Iterable<String>? autofillHints;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (_focused == focused) return;
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.premium ? PremiumLoginTheme.fieldRadius : 12.0;
    final height = widget.premium ? PremiumLoginTheme.fieldHeight : 48.0;
    final labelColor = widget.premium ? PremiumLoginTheme.text : const Color(0xFF1F2937);
    final borderColor = _focused ? PremiumLoginTheme.accentBlue : PremiumLoginTheme.inputBorder;
    final borderWidth = _focused ? 1.5 : 1.0;

    final fieldTheme = Theme.of(context).copyWith(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: PremiumLoginTheme.accentBlue,
        selectionColor: Color(0x332563EB),
        selectionHandleColor: PremiumLoginTheme.accentBlue,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: PremiumLoginTheme.white,
        hoverColor: Colors.transparent,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderWidth),
            color: PremiumLoginTheme.white,
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _focused ? PremiumLoginTheme.accentBlue : PremiumLoginTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Theme(
                  data: fieldTheme,
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    validator: widget.validator,
                    autofillHints: widget.autofillHints,
                    autocorrect: false,
                    enableSuggestions: !widget.obscureText,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: PremiumLoginTheme.text,
                      height: 1.2,
                    ),
                    cursorColor: PremiumLoginTheme.accentBlue,
                    cursorHeight: 18,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: PremiumLoginTheme.placeholder,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: true,
                      fillColor: PremiumLoginTheme.white,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        if (widget.bottomGap > 0) SizedBox(height: widget.bottomGap),
      ],
    );
  }
}
