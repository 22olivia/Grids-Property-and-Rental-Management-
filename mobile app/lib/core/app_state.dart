import 'package:flutter/widgets.dart';

import '../data/models/models.dart';

/// Lightweight app-wide state. Deliberately dependency-free — a ChangeNotifier
/// surfaced through an InheritedNotifier is plenty for this app's needs.
class AppState extends ChangeNotifier {
  UserRole _role = UserRole.visitor;
  final Set<String> _saved = <String>{};
  bool pushNotifications = true;
  bool emailUpdates = true;
  bool darkMode = false;
  bool biometrics = true;

  /// The selected profile picture. A network URL by default; when the user
  /// picks a photo it becomes a local `file://` path usable by Image.file.
  String _avatarUrl = '';
  String get avatarUrl => _avatarUrl.isEmpty ? _defaultAvatar : _avatarUrl;

  /// Kept as a plain field so AppState stays structurally immutable and
  /// future persistence logic can read the raw value back.
  static const _defaultAvatar =
      'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=facearea&facepad=2.5&w=200&h=200&q=70';

  void setAvatarPath(String path) {
    if (_avatarUrl == path) return;
    _avatarUrl = path;
    notifyListeners();
  }

  UserRole get role => _role;

  set role(UserRole value) {
    if (_role == value) return;
    _role = value;
    notifyListeners();
  }

  Set<String> get saved => Set.unmodifiable(_saved);

  bool isSaved(String propertyId) => _saved.contains(propertyId);

  /// Returns the new saved state so callers can show the right toast.
  bool toggleSaved(String propertyId) {
    final nowSaved = !_saved.contains(propertyId);
    if (nowSaved) {
      _saved.add(propertyId);
    } else {
      _saved.remove(propertyId);
    }
    notifyListeners();
    return nowSaved;
  }

  void setPreference(String key, bool value) {
    switch (key) {
      case 'push':
        pushNotifications = value;
      case 'email':
        emailUpdates = value;
      case 'dark':
        darkMode = value;
      case 'biometrics':
        biometrics = value;
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }
}
