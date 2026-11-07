import 'package:flutter/widgets.dart';

/// Reuses the application's single Profile route, including PKCE callbacks.
class AccountNavigationScope extends InheritedWidget {
  final Future<void> Function({String? returnLabel}) openAccount;
  const AccountNavigationScope({
    super.key,
    required this.openAccount,
    required super.child,
  });
  static AccountNavigationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountNavigationScope>();
  @override
  bool updateShouldNotify(AccountNavigationScope oldWidget) =>
      openAccount != oldWidget.openAccount;
}
