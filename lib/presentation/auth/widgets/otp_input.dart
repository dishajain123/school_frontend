import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    required this.onChanged,
    this.length = 6,
  });

  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onChanged;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      widget.onChanged(_currentOtp);
      return;
    }

    final digit = value[value.length - 1];
    _controllers[index].text = digit;
    _controllers[index].selection =
        const TextSelection.collapsed(offset: 1);

    widget.onChanged(_currentOtp);

    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      if (_currentOtp.length == widget.length) {
        widget.onCompleted(_currentOtp);
      }
    }
  }

  void _onKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        final isFocused = _focusNodes[i].hasFocus;
        final isFilled = _controllers[i].text.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 46,
          height: 56,
          decoration: BoxDecoration(
            color: isFocused
                ? AppColors.white
                : isFilled
                    ? AppColors.navyDeep.withValues(alpha: 0.04)
                    : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? AppColors.navyMedium
                  : isFilled
                      ? AppColors.navyDeep.withValues(alpha: 0.3)
                      : AppColors.surface200,
              width: isFocused ? 2 : 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color:
                          AppColors.navyMedium.withValues(alpha: 0.15),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyEvent(i, event),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
              cursorColor: AppColors.navyMedium,
              cursorWidth: 1.5,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              onChanged: (value) => _onDigitEntered(i, value),
            ),
          ),
        );
      }),
    );
  }
}