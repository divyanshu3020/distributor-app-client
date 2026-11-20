import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, outline, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final bool fullWidth;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.fullWidth = true,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppTheme.primaryBlue;
        fgColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        bgColor = AppTheme.primaryDark;
        fgColor = Colors.white;
        break;
      case ButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppTheme.primaryDark;
        borderSide = const BorderSide(color: AppTheme.borderSubtle, width: 1.5);
        break;
      case ButtonVariant.danger:
        bgColor = AppTheme.alertRed;
        fgColor = Colors.white;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    final btn = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        disabledBackgroundColor: bgColor.withOpacity(0.6),
        side: borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: content,
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: btn,
    );
  }
}
