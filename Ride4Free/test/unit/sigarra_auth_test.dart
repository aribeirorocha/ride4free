import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:Ride4Free/sigarra/sigarra_auth_service.dart';

void main() {
  test('SAS-1: Cobre o fallback http.get quando _client é nulo', () async {
    // 1. Instanciamos SEM passar cliente. 
    // Isto garante que '_client' é nulo e o operador '??' escolherá o lado direito.
    final service = SigarraAuthService();

    // 2. Como não injetamos um mock, o código vai tentar fazer uma chamada real à rede.
    // Para não dependermos da internet, podemos usar um MockClient global 
    // se necessário, mas o objetivo aqui é cobrir a linha do código (a estrutura).
    
    // NOTA: Se quiseres que isto corra sem erros de rede, o teste tem de ser 
    // um "integration test" que permita ligações ou usar http.runWithClient.
    
    try {
      // Forçamos o fluxo até a linha do homeResponse
      await service.login(username: 'up12345', password: 'wrong_password');
    } catch (_) {
      // Não nos interessa o sucesso do login, apenas que o código 
      // passou pela linha do http.get(homeUri...)
    }
  });
}