import 'package:flutter/material.dart';

@immutable
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final AppointmentStatusColors appointmentStatusColors;

  const CustomThemeExtension({
    required this.appointmentStatusColors,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    AppointmentStatusColors? appointmentStatusColors,
  }) {
    return CustomThemeExtension(
      appointmentStatusColors: appointmentStatusColors ?? this.appointmentStatusColors,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
    ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      appointmentStatusColors: AppointmentStatusColors.lerp(
        appointmentStatusColors,
        other.appointmentStatusColors,
        t,
      ),
    );
  }
}

class AppointmentStatusColors {
  final Color pendingBackground;
  final Color pendingText;
  final Color pendingIcon;
  final Color confirmedBackground;
  final Color confirmedText;
  final Color confirmedIcon;
  final Color canceledBackground;
  final Color canceledText;
  final Color canceledIcon;

  const AppointmentStatusColors({
    required this.pendingBackground,
    required this.pendingText,
    required this.pendingIcon,
    required this.confirmedBackground,
    required this.confirmedText,
    required this.confirmedIcon,
    required this.canceledBackground,
    required this.canceledText,
    required this.canceledIcon,
  });

  static AppointmentStatusColors lerp(
    AppointmentStatusColors a,
    AppointmentStatusColors b,
    double t,
  ) {
    return AppointmentStatusColors(
      pendingBackground: Color.lerp(a.pendingBackground, b.pendingBackground, t)!,
      pendingText: Color.lerp(a.pendingText, b.pendingText, t)!,
      pendingIcon: Color.lerp(a.pendingIcon, b.pendingIcon, t)!,
      confirmedBackground: Color.lerp(a.confirmedBackground, b.confirmedBackground, t)!,
      confirmedText: Color.lerp(a.confirmedText, b.confirmedText, t)!,
      confirmedIcon: Color.lerp(a.confirmedIcon, b.confirmedIcon, t)!,
      canceledBackground: Color.lerp(a.canceledBackground, b.canceledBackground, t)!,
      canceledText: Color.lerp(a.canceledText, b.canceledText, t)!,
      canceledIcon: Color.lerp(a.canceledIcon, b.canceledIcon, t)!,
    );
  }
} 