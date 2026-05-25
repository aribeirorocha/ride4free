// =============================================================================
// UNIT TESTS — SigarraAuthService e UniversityIdentity
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. UT-IDENTITY: Testes do Modelo UniversityIdentity
  // ---------------------------------------------------------------------------
  group('Unit Tests - UniversityIdentity', () {
    test('ID-U1: Criação com todos os parâmetros', () {
      final identity = UniversityIdentity(
        username: 'up123456789',
        displayName: 'Engenheiro Teste',
        photoUrl: 'https://sigarra.up.pt/foto.jpg',
      );

      expect(identity.username, 'up123456789');
      expect(identity.displayName, 'Engenheiro Teste');
      expect(identity.photoUrl, 'https://sigarra.up.pt/foto.jpg');
    });

    test('ID-U2: Criação sem photoUrl (Nulo permitido)', () {
      final identity = UniversityIdentity(
        username: 'up987654321',
        displayName: 'Anónimo',
      );

      expect(identity.photoUrl, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. UT-SIGARRA: Testes do Serviço de Autenticação (Com Mocking)
  // ---------------------------------------------------------------------------
  group('Unit Tests - SigarraAuthService', () {
    
    test('SIG-U1: Login Bem Sucedido - Extrai Nome e Foto corretamente', () async {
      // 1. Criamos um "Servidor Falso" que devolve o HTML simulado do Sigarra
      final mockClient = MockClient((request) async {
        
        // Simular a resposta do POST de Login
        if (request.url.path.contains('vld_validacao.validacao')) {
          return http.Response(
            '<html><head><meta http-equiv="refresh" content="0;url=..."></head></html>',
            200,
            headers: {'set-cookie': 'SI_SESSION=abcdef12345; path=/'},
          );
        }
        
        // Simular a resposta do GET da Página Inicial (onde está o nome/foto)
        if (request.url.path.contains('web_page.inicial')) {
          // HTML falso contendo os padrões Regex que criaste no serviço
          const mockHtml = '''
            <html>
              <body>
                <img src="/fotografias_service.foto?pct_cod=up123456789">
                <div>Fotografia de André Rocha</div>
              </body>
            </html>
          ''';
          return http.Response(mockHtml, 200);
        }

        return http.Response('Not Found', 404);
      });

      // 2. Injetamos o cliente falso no nosso serviço
      final service = SigarraAuthService(client: mockClient);

      // 3. Executamos o método
      final result = await service.login(username: 'up123456789', password: 'password_falsa');

      // 4. Verificamos se o Regex parseou os dados do HTML simulado
      expect(result, isNotNull);
      expect(result!.username, 'up123456789');
      expect(result.displayName, 'André Rocha', reason: 'O Regex falhou a extrair o nome do HTML');
      expect(result.photoUrl, 'https://sigarra.up.pt/fotografias_service.foto?pct_cod=up123456789');
    });

    test('SIG-U2: Falha no Login - Status 401 ou Credenciais Erradas', () async {
      final mockClient = MockClient((request) async {
        // Simular que o Sigarra disse "Acesso Negado" (não devolve o meta refresh)
        return http.Response('<html><body>Credenciais inválidas</body></html>', 200);
      });

      final service = SigarraAuthService(client: mockClient);
      final result = await service.login(username: 'up000000', password: 'errada');

      expect(result, isNull, reason: 'O serviço devia devolver null se não houver meta refresh');
    });

    test('SIG-U3: Falha no Login - Servidor Sigarra em Baixo (Status 500)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = SigarraAuthService(client: mockClient);
      final result = await service.login(username: 'up111111', password: 'pwd');

      expect(result, isNull, reason: 'O serviço devia devolver null em caso de erro 500');
    });

    test('SIG-U4: Extração de nome fallback usando outro padrão Regex ("Bem-vindo")', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('vld_validacao.validacao')) {
          return http.Response('<html><meta http-equiv="refresh"></html>', 200);
        }
        if (request.url.path.contains('web_page.inicial')) {
          // Testamos o segundo Regex do teu código
          const mockHtml = '<html><body>Bem-vindo, Maria Silva!</body></html>';
          return http.Response(mockHtml, 200);
        }
        return http.Response('', 404);
      });

      final service = SigarraAuthService(client: mockClient);
      final result = await service.login(username: 'up123', password: '123');

      expect(result!.displayName, 'Maria Silva!');
    });
  });
}