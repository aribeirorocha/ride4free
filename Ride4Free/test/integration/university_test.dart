import 'dart:convert';

import 'package:Ride4Free/session/university_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ajusta os imports conforme o teu projeto
import 'package:Ride4Free/session/university_session_store.dart';
import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';

void main() {
  group('UniversitySessionStore — Tratamento de Erros', () {
    
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('USS-1: markLoggedIn deve cobrir o catch e rethrow quando a API falha', () async {
      // 1. Criar um MockClient "Tóxico"
      // Devolvemos sempre status 500 (Internal Server Error) para qualquer pedido.
      // Isto vai fazer com que o syncRide4FreeApiSession falhe o login e falhe o register, 
      // atirando uma exceção real cá para fora!
      final mockClient = MockClient((request) async {
        return http.Response('Servidor em baixo', 500);
      });

      await http.runWithClient(() async {
        // 2. Instanciar a store que vai usar a rede corrompida
        final store = UniversitySessionStore();
        
        final identity = UniversityIdentity(
          username: 'up202012345',
          displayName: 'Estudante Coverage',
          photoUrl: 'https://sigarra.up.pt/foto.jpg',
        );

        // 3. Capturar o rethrow!
        // Como a tua função faz "rethrow", o erro tem de subir para o teste.
        // O expectLater com throwsA garante que o teste fica verde ao apanhar a explosão.
        await expectLater(
          () => store.markLoggedIn(identity),
          throwsA(anything),
        );
        
      }, () => mockClient);
    });
    test('USS-2: markLoggedIn deve cobrir o setString da foto quando identity tem URL', () async {
  // 1. Usar um MockClient que devolve sucesso (200 OK) para evitar o erro do catch
  final mockClient = MockClient((request) async {
    return http.Response(jsonEncode({'token': 'abc', 'user': {'id': 1, 'email': 'a@a.pt', 'name': 'N'}}), 200);
  });

  await http.runWithClient(() async {
    final store = UniversitySessionStore();
    
    // 2. Identity COM foto (garante que entra no IF)
    final identityComFoto = UniversityIdentity(
      username: 'up123',
      displayName: 'Teste',
      photoUrl: 'https://sigarra.up.pt/foto.jpg',
    );

    // 3. Executar o método
    await store.markLoggedIn(identityComFoto);

    // 4. Verificar se o SharedPreferences guardou a URL corretamente
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('university_photo_url'), equals('https://sigarra.up.pt/foto.jpg'));
    
  }, () => mockClient);
});
test('USS-3: markLoggedIn cobre ramificação TesterAuth', () async {
  // Mock para simular sucesso na API
  final mockClient = MockClient((request) async {
    return http.Response(jsonEncode({'token': 'test_token', 'user': {'id': 1, 'email': 't@t.pt', 'name': 'Tester'}}), 200);
  });

  await http.runWithClient(() async {
    final store = UniversitySessionStore();
    
    // Usamos um username que o TesterAuth reconheça como tester (ex: 'tester_01')
    final identityTester = UniversityIdentity(
      username: 'tester_01', 
      displayName: 'Testador',
    );

    // Se o teu TesterAuth.isTesterUsername retornar true para 'tester_01',
    // esta chamada vai executar exatamente a linha "? TesterAuth.apiCredentials..."
    await store.markLoggedIn(identityTester);
    
    // Verifica se a sessão foi gravada
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('university_logged_in'), isTrue);
  }, () => mockClient);
});
  });
}