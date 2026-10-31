import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const contentInset = 19.0;
  static const cardInset = 28.0;
}

abstract final class AppInsets {
  static const screen = EdgeInsets.all(AppSpacing.xl);
  static const cardMargin = EdgeInsets.all(AppSpacing.xxl);
  static const cardContent = EdgeInsets.all(AppSpacing.cardInset);
  static const contentHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.contentInset,
  );
  static const dialogContent = EdgeInsets.fromLTRB(30, 32, 30, 36);
}

abstract final class AppRadii {
  static const small = BorderRadius.all(Radius.circular(5));
  static const standard = BorderRadius.all(Radius.circular(10));
  static const card = BorderRadius.all(Radius.circular(10));
  static const cardInner = BorderRadius.all(Radius.circular(8));
  static const row = BorderRadius.all(Radius.circular(8));
  static const sheet = BorderRadius.vertical(top: Radius.circular(12));
  static const pill = BorderRadius.all(Radius.circular(6));
}
