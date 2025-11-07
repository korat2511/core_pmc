import 'dart:async';

class CompanyNotifier {
  static final StreamController<bool> _controller = StreamController<bool>.broadcast();
  
  // Stream that screens can listen to
  static Stream<bool> get companyChangedStream => _controller.stream;
  
  // Notify all listeners that company has changed
  static void notifyCompanyChanged() {
    if (!_controller.isClosed) {
      _controller.add(true);
    }
  }
  
  // Clean up
  static void dispose() {
    _controller.close();
  }
}

