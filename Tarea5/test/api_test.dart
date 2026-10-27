import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:directorio_utesa/data/repository.dart';

void main() {
  test('GET users convierte nombre, correo y empresa', () async {
    final api = DirectoryApi(
      MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/users');
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Ana',
              'email': 'ana@example.com',
              'company': {'name': 'UTESA'},
            },
          ]),
          200,
        );
      }),
    );
    final result = await api.users();
    expect(result.single.name, 'Ana');
    expect(result.single.company, 'UTESA');
    api.close();
  });
  test('posts filtra por el ID solicitado', () async {
    final api = DirectoryApi(
      MockClient((request) async {
        expect(request.url.queryParameters, {'userId': '7'});
        return http.Response('[{"id":3,"title":"Hola","body":"Texto"}]', 200);
      }),
    );
    expect((await api.posts(7)).single.title, 'Hola');
    api.close();
  });
  test('HTTP 500 se convierte en error controlable', () async {
    final api = DirectoryApi(
      MockClient((_) async => http.Response('error', 500)),
    );
    await expectLater(api.users(), throwsA(isA<ApiException>()));
    api.close();
  });
  test('JSON inválido no se acepta como lista válida', () async {
    final api = DirectoryApi(
      MockClient((_) async => http.Response('invalid', 200)),
    );
    await expectLater(api.users(), throwsFormatException);
    api.close();
  });
}
