import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Dismiss keyboard when tapping on empty space
        FocusScope.of(context).unfocus();
        // Also clear any text selection
        SystemChannels.textInput.invokeMethod('TextInput.clearClient');
      },
      child: child,
    );
  }
}

void closeKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.clearClient');
}

// Helper function to show dialog with keyboard dismissal
Future<T?> showDialogWithKeyboardDismissal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  // Dismiss keyboard before showing dialog
  FocusScope.of(context).unfocus();
  
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
  );
}