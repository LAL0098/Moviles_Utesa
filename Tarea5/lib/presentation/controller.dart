import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/models.dart';
import '../data/repository.dart';

class DirectoryController extends ChangeNotifier {
  final DirectoryRepository repository;
  DirectoryController(this.repository);
  List<User> users = [], favorites = [];
  bool loading = false, saving = false, offline = false;
  String? error, storageError;
  bool _disposed = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  void emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    try {
      favorites = await repository.store.read();
    } catch (_) {
      storageError = 'No se pudieron leer los favoritos guardados.';
    }
    try {
      offline = (await Connectivity().checkConnectivity()).contains(
        ConnectivityResult.none,
      );
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        final wasOffline = offline;
        offline = results.contains(ConnectivityResult.none);
        emit();
        if (wasOffline && !offline) {
          load();
        }
      });
    } catch (_) {
      /* La petición HTTP sigue siendo la prueba definitiva. */
    }
    await load();
  }

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    emit();
    try {
      if (offline) {
        error = 'Sin conexión. Consulta tus favoritos guardados.';
      } else {
        users = await repository.api.users();
      }
    } on ApiException catch (e) {
      error = 'El servidor respondió con error ${e.status}. Intenta de nuevo.';
    } on TimeoutException {
      error = 'La conexión tardó demasiado. Revisa Internet y reintenta.';
    } catch (_) {
      error = 'No se pudo conectar o leer la respuesta. Revisa Internet y reintenta.';
    } finally {
      loading = false;
      emit();
    }
  }

  bool isFavorite(User u) => favorites.any((f) => f.id == u.id);
  Future<void> toggle(User u) async {
    if (saving) return;
    saving = true;
    storageError = null;
    emit();
    final next = [...favorites];
    if (isFavorite(u)) {
      next.removeWhere((f) => f.id == u.id);
    } else {
      next.add(u);
    }
    try {
      await repository.store.write(next);
      favorites = next;
    } catch (_) {
      storageError = 'No se pudo guardar el cambio. Inténtalo de nuevo.';
    } finally {
      saving = false;
      emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    repository.api.close();
    super.dispose();
  }
}
