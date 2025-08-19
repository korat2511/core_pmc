import 'package:flutter/material.dart';

class NavigationUtils {
  // Push to new screen
  static Future<T?> push<T extends Object?>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  // Push and replace current screen
  static Future<T?> pushReplacement<T extends Object?>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute<T>(
        builder: (context) => screen,
      ),
    );
  }

  // Push and remove all previous screens
  static Future<T?> pushAndRemoveAll<T extends Object?>(BuildContext context, Widget screen) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (context) => screen,
      ),
      (route) => false,
    );
  }

  // Push and remove until specific route
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget screen,
    RoutePredicate predicate,
  ) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (context) => screen,
      ),
      predicate,
    );
  }

  // Pop current screen
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  // Pop until specific route
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  // Pop to first route
  static void popToFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Can pop check
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  // Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    String? currentRoute;
    Navigator.of(context).popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }

  // Navigate with custom transition
  static Future<T?> pushWithTransition<T extends Object?>(
    BuildContext context,
    Widget screen, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Navigate with fade transition
  static Future<T?> pushWithFade<T extends Object?>(
    BuildContext context,
    Widget screen, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // Navigate with scale transition
  static Future<T?> pushWithScale<T extends Object?>(
    BuildContext context,
    Widget screen, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
      ),
    );
  }
} 