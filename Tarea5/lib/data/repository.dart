import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class ApiException implements Exception {
  final int status;
  ApiException(this.status);
}

class DirectoryApi {
  final http.Client client;
  DirectoryApi(this.client);
  Future<List<dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.https('jsonplaceholder.typicode.com', path, query);
    final response = await client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw ApiException(response.statusCode);
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  Future<List<User>> users() async =>
      (await _get('/users'))
          .map((j) => User(j as Map<String, dynamic>))
          .toList();
  Future<List<Post>> posts(int id) async => (await _get('/posts', {
    'userId': '$id',
  })).map((j) => Post.fromJson(j as Map<String, dynamic>)).toList();
  void close() => client.close();
}

// Los favoritos son datos públicos, pequeños y no críticos. Se guarda
// el usuario completo, no solamente su ID, para poder abrirlo sin red.
class FavoritesStore {
  final SharedPreferencesAsync prefs;
  FavoritesStore(this.prefs);
  Future<List<User>> read() async {
    final raw = await prefs.getString('favorites_v1');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => User(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> write(List<User> users) => prefs.setString(
    'favorites_v1',
    jsonEncode(users.map((u) => u.json).toList()),
  );
}

class DirectoryRepository {
  final DirectoryApi api;
  final FavoritesStore store;
  DirectoryRepository(this.api, this.store);
}
