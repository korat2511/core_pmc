import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DismissKeyboard extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;

  const DismissKeyboard({
    super.key, 
    required this.child,
    this.dismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismissOnTap ? () {
        // Dismiss keyboard when tapping on empty space
        FocusScope.of(context).unfocus();
        // Also clear any text selection
        SystemChannels.textInput.invokeMethod('TextInput.clearClient');
      } : null,
      child: child,
    );
  }
}

void closeKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.clearClient');
}

// Enhanced keyboard dismissal with additional options
void dismissKeyboard(BuildContext context, {bool clearSelection = true}) {
  FocusScope.of(context).unfocus();
  if (clearSelection) {
    SystemChannels.textInput.invokeMethod('TextInput.clearClient');
  }
}

// Dismiss keyboard and clear focus from all text fields
void dismissAllFocus(BuildContext context) {
  FocusScope.of(context).unfocus();
  FocusManager.instance.primaryFocus?.unfocus();
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