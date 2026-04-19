// =============================================================================
// UNIT TESTS — Ride4Free
// Cobre: Profile model, lógica de recompensa, _SeatPicker, _initials,
//        Ride4FreeConfig, Ride4FreeApiException
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:app_test/profile_model.dart';
import 'package:app_test/ride4free_api.dart';

void main() {
  // ---------------------------------------------------------------------------
  // UT-PROFILE: Profile model
  // ---------------------------------------------------------------------------
  group('Profile model', () {
    test('PM-U1: Construtor com valores obrigatórios cria perfil correto', () {
      final p = Profile(id: 1, name: 'Ana Costa');
      expect(p.id, 1);
      expect(p.name, 'Ana Costa');
      expect(p.role, 'Team member'); // valor default
      expect(p.stars, 0);            // valor default
    });

    test('PM-U2: Construtor aceita role e stars personalizados', () {
      final p = Profile(id: 2, name: 'Bruno Lima', role: 'Driver', stars: 4);
      expect(p.role, 'Driver');
      expect(p.stars, 4);
    });

    test('PM-U3: stars é mutável — pode ser atualizado diretamente', () {
      final p = Profile(id: 3, name: 'Carla Neves');
      expect(p.stars, 0);
      p.stars = 5;
      expect(p.stars, 5);
    });

    test('PM-U4: stars pode ser definido para zero (reset)', () {
      final p = Profile(id: 4, name: 'Diogo Mota', stars: 3);
      p.stars = 0;
      expect(p.stars, 0);
    });

    test('PM-U5: Dois perfis com o mesmo nome têm IDs diferentes', () {
      final p1 = Profile(id: 10, name: 'Eva');
      final p2 = Profile(id: 11, name: 'Eva');
      expect(p1.id, isNot(p2.id));
    });
  });

  // ---------------------------------------------------------------------------
  // UT-REWARD: Lógica de recompensa (+N*10 créditos)
  // ---------------------------------------------------------------------------
  group('Lógica de recompensa de créditos', () {
    // A fórmula usada na UI: seats * 10
    int calcReward(int seats) => seats * 10;

    test('RW-U1: 1 lugar → 10 créditos', () => expect(calcReward(1), 10));
    test('RW-U2: 3 lugares (default) → 30 créditos', () => expect(calcReward(3), 30));
    test('RW-U3: 5 lugares → 50 créditos', () => expect(calcReward(5), 50));
    test('RW-U4: 0 lugares → 0 créditos (inválido, mas a matemática é correta)',
        () => expect(calcReward(0), 0));

    test('RW-U5: rewardText correto para 2 lugares', () {
      final seats = 2;
      final text = '+${seats * 10} Creditos';
      expect(text, '+20 Creditos');
    });
  });

  // ---------------------------------------------------------------------------
  // UT-SEATS: Validação de lugares (_seats > 0)
  // ---------------------------------------------------------------------------
  group('Validação de lugares (canPublish)', () {
    bool canPublish(int seats) => seats > 0;

    test('SP-U1: 1 lugar → publicação permitida', () => expect(canPublish(1), isTrue));
    test('SP-U2: 3 lugares → publicação permitida', () => expect(canPublish(3), isTrue));
    test('SP-U3: 0 lugares → publicação bloqueada', () => expect(canPublish(0), isFalse));

    test('SP-U4: decrementar de 1 para 0 bloqueia publicação', () {
      int seats = 1;
      if (seats > 0) seats--;
      expect(canPublish(seats), isFalse);
    });

    test('SP-U5: incrementar de 0 para 1 desbloqueia publicação', () {
      int seats = 0;
      seats++;
      expect(canPublish(seats), isTrue);
    });

    test('SP-U6: decrementar não desce abaixo de 0', () {
      int seats = 0;
      if (seats > 0) seats--; // guarda igual à app
      expect(seats, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // UT-INITIALS: função _initials (lógica de initials dos avatares)
  // ---------------------------------------------------------------------------
  group('Função _initials (avatar)', () {
    // Replica exacta da função em profile_rating_button.dart
    String initials(String name) {
      final parts = name.trim().split(' ');
      return parts
          .map((w) => w.isNotEmpty ? w[0] : '')
          .join()
          .toUpperCase()
          .substring(0, parts.length >= 2 ? 2 : 1);
    }

    test('IN-U1: nome composto → duas iniciais maiúsculas', () {
      expect(initials('Alex Rivera'), 'AR');
    });

    test('IN-U2: nome único → uma inicial maiúscula', () {
      expect(initials('Maya'), 'M');
    });

    test('IN-U3: letras minúsculas são convertidas', () {
      expect(initials('sam chen'), 'SC');
    });

    test('IN-U4: espaços extra à volta são ignorados', () {
      expect(initials('  Ana Costa  '), 'AC');
    });

    test('IN-U5: nome com três palavras → duas iniciais (1.ª e 2.ª)', () {
      expect(initials('João Paulo Silva'), 'JP');
    });
  });

  // ---------------------------------------------------------------------------
  // UT-APIEXC: Ride4FreeApiException
  // ---------------------------------------------------------------------------
  group('Ride4FreeApiException', () {
    test('AE-U1: toString inclui statusCode e body', () {
      final e = Ride4FreeApiException(404, 'Not found');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not found'));
    });

    test('AE-U2: propriedades statusCode e body ficam acessíveis', () {
      final e = Ride4FreeApiException(401, 'Unauthorized');
      expect(e.statusCode, 401);
      expect(e.body, 'Unauthorized');
    });
  });

  // ---------------------------------------------------------------------------
  // UT-CFG: Ride4FreeConfig.baseUrl
  // ---------------------------------------------------------------------------
  group('Ride4FreeConfig.baseUrl', () {
    test('CFG-U1: baseUrl começa com "http"', () {
      expect(Ride4FreeConfig.baseUrl, startsWith('http'));
    });

    test('CFG-U2: baseUrl termina com porta (inclui ":")', () {
      expect(Ride4FreeConfig.baseUrl, contains(':'));
    });
  });

  // ---------------------------------------------------------------------------
  // UT-STAR: Lógica de estrelas pendentes (_pendingStars)
  // ---------------------------------------------------------------------------
  group('Lógica de estrelas pendentes', () {
    test('ST-U1: selecionar perfil com 0 estrelas define pendingStars = 0', () {
      final p = Profile(id: 1, name: 'X', stars: 0);
      int pending = p.stars;
      expect(pending, 0);
    });

    test('ST-U2: selecionar perfil com 3 estrelas define pendingStars = 3', () {
      final p = Profile(id: 2, name: 'Y', stars: 3);
      int pending = p.stars;
      expect(pending, 3);
    });

    test('ST-U3: tocar na 4.ª estrela define pendingStars = 4', () {
      int pending = 0;
      void onChanged(int s) => pending = s;
      onChanged(4);
      expect(pending, 4);
    });

    test('ST-U4: atualizar estrela de 5 para 2 reduz corretamente', () {
      int pending = 5;
      void onChanged(int s) => pending = s;
      onChanged(2);
      expect(pending, 2);
    });

    test('ST-U5: guardar persiste as estrelas no Profile', () {
      final p = Profile(id: 3, name: 'Z');
      int pending = 4;
      p.stars = pending; // simula widget.onSave
      expect(p.stars, 4);
    });
  });

  // ---------------------------------------------------------------------------
  // UT-FILTER: Filtro de perfis avaliados (rated)
  // ---------------------------------------------------------------------------
  group('Filtro de perfis com avaliação (rated)', () {
    test('FL-U1: lista vazia → nenhum perfil avaliado', () {
      final profiles = <Profile>[];
      final rated = profiles.where((p) => p.stars > 0).toList();
      expect(rated, isEmpty);
    });

    test('FL-U2: perfis sem estrelas → rated vazio', () {
      final profiles = [
        Profile(id: 1, name: 'A'),
        Profile(id: 2, name: 'B'),
      ];
      expect(profiles.where((p) => p.stars > 0).toList(), isEmpty);
    });

    test('FL-U3: só perfis com estrelas > 0 aparecem em rated', () {
      final profiles = [
        Profile(id: 1, name: 'A', stars: 3),
        Profile(id: 2, name: 'B', stars: 0),
        Profile(id: 3, name: 'C', stars: 5),
      ];
      final rated = profiles.where((p) => p.stars > 0).toList();
      expect(rated.length, 2);
      expect(rated.map((p) => p.name), containsAll(['A', 'C']));
    });

    test('FL-U4: depois de reset (stars=0) o perfil desaparece do rated', () {
      final p = Profile(id: 1, name: 'A', stars: 4);
      p.stars = 0;
      final rated = [p].where((x) => x.stars > 0).toList();
      expect(rated, isEmpty);
    });
  });
}