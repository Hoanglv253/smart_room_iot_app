import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> runBusyTask<T extends Object>(Future<T?> Function() task) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      return await task();
    } catch (error) {
      _errorMessage = _normalizeError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> runBusyAction(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _normalizeError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _normalizeError(Object error) {
    final text = error.toString().trim();
    const exceptionPrefix = 'Exception:';

    if (text.startsWith(exceptionPrefix)) {
      return text.substring(exceptionPrefix.length).trim();
    }

    return text;
  }
}
