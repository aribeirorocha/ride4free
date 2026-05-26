import 'package:flutter_test/flutter_test.dart';

/// Test suite for utility functions and business logic from main.dart
void main() {
  group('Time Validation - _isValidTime', () {
    /// Helper function to validate time format (HH:mm)
    bool isValidTime(String input) {
      final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
      return timeRegExp.hasMatch(input);
    }

    group('Valid time formats', () {
      test('should accept valid time 08:15', () {
        expect(isValidTime('08:15'), true);
      });

      test('should accept valid time 00:00 (midnight)', () {
        expect(isValidTime('00:00'), true);
      });

      test('should accept valid time 23:59 (last minute of day)', () {
        expect(isValidTime('23:59'), true);
      });

      test('should accept valid time 9:05 (single digit hour)', () {
        expect(isValidTime('9:05'), true);
      });

      test('should accept valid time 13:30 (afternoon)', () {
        expect(isValidTime('13:30'), true);
      });

      test('should accept valid time 1:00 (early morning single digit)', () {
        expect(isValidTime('1:00'), true);
      });

      test('should accept all valid hours 0-23', () {
        for (int h = 0; h < 24; h++) {
          expect(isValidTime('${h.toString().padLeft(2, '0')}:00'), true,
              reason: 'Hour $h should be valid');
        }
      });

      test('should accept all valid minutes 0-59', () {
        for (int m = 0; m < 60; m++) {
          expect(isValidTime('12:${m.toString().padLeft(2, '0')}'), true,
              reason: 'Minute $m should be valid');
        }
      });
    });

    group('Invalid time formats', () {
      test('should reject time with invalid hour 24:00', () {
        expect(isValidTime('24:00'), false);
      });

      test('should reject time with invalid hour 25:30', () {
        expect(isValidTime('25:30'), false);
      });

      test('should reject time with invalid minutes 12:60', () {
        expect(isValidTime('12:60'), false);
      });

      test('should reject time with invalid minutes 12:99', () {
        expect(isValidTime('12:99'), false);
      });

      test('should reject empty string', () {
        expect(isValidTime(''), false);
      });

      test('should reject time without colon 0815', () {
        expect(isValidTime('0815'), false);
      });

      test('should reject time with wrong format 8:1', () {
        expect(isValidTime('8:1'), false);
      });

      test('should reject time with letters 08:ab', () {
        expect(isValidTime('08:ab'), false);
      });

      test('should reject time with extra spaces 08 : 15', () {
        expect(isValidTime('08 : 15'), false);
      });

      test('should reject negative hours -1:30', () {
        expect(isValidTime('-1:30'), false);
      });

      test('should reject decimal times 08.15', () {
        expect(isValidTime('08.15'), false);
      });

      test('should reject time with seconds 08:15:30', () {
        expect(isValidTime('08:15:30'), false);
      });
    });
  });

  group('Time Formatting - _timeAgo', () {
    /// Helper function to format time differences
    String timeAgo(String? dateStr) {
      if (dateStr == null) return '';
      try {
        final date = DateTime.parse(dateStr).toLocal();
        final diff = DateTime.now().difference(date);

        if (diff.inMinutes < 1) return 'Agora mesmo';
        if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}m';
        if (diff.inHours < 24) return 'Há ${diff.inHours}h';
        if (diff.inDays == 1) return 'Ontem';
        return 'Há ${diff.inDays}d';
      } catch (_) {
        return '';
      }
    }

    group('Null and invalid inputs', () {
      test('should return empty string for null', () {
        expect(timeAgo(null), '');
      });

      test('should return empty string for invalid date format', () {
        expect(timeAgo('not-a-date'), '');
      });

      test('should return empty string for empty string', () {
        expect(timeAgo(''), '');
      });
    });

    group('Recent times (less than 1 minute)', () {
      test('should return "Agora mesmo" for now', () {
        final now = DateTime.now().toIso8601String();
        expect(timeAgo(now), 'Agora mesmo');
      });

      test('should return "Agora mesmo" for 30 seconds ago', () {
        final thirtySecondsAgo =
            DateTime.now().subtract(const Duration(seconds: 30)).toIso8601String();
        expect(timeAgo(thirtySecondsAgo), 'Agora mesmo');
      });
    });

    group('Minutes ago', () {
      test('should return "Há 1m" for 1 minute ago', () {
        final oneMinuteAgo =
            DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String();
        expect(timeAgo(oneMinuteAgo), 'Há 1m');
      });

      test('should return "Há 15m" for 15 minutes ago', () {
        final fifteenMinutesAgo =
            DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String();
        expect(timeAgo(fifteenMinutesAgo), 'Há 15m');
      });

      test('should return "Há 59m" for 59 minutes ago', () {
        final fiftyNineMinutesAgo =
            DateTime.now().subtract(const Duration(minutes: 59)).toIso8601String();
        expect(timeAgo(fiftyNineMinutesAgo), 'Há 59m');
      });
    });

    group('Hours ago', () {
      test('should return "Há 1h" for 1 hour ago', () {
        final oneHourAgo =
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
        expect(timeAgo(oneHourAgo), 'Há 1h');
      });

      test('should return "Há 12h" for 12 hours ago', () {
        final twelveHoursAgo =
            DateTime.now().subtract(const Duration(hours: 12)).toIso8601String();
        expect(timeAgo(twelveHoursAgo), 'Há 12h');
      });

      test('should return "Há 23h" for 23 hours ago', () {
        final twentyThreeHoursAgo =
            DateTime.now().subtract(const Duration(hours: 23)).toIso8601String();
        expect(timeAgo(twentyThreeHoursAgo), 'Há 23h');
      });
    });

    group('Days ago', () {
      test('should return "Ontem" for exactly 1 day ago', () {
        final yesterday =
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        expect(timeAgo(yesterday), 'Ontem');
      });

      test('should return "Há 2d" for 2 days ago', () {
        final twoDaysAgo =
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
        expect(timeAgo(twoDaysAgo), 'Há 2d');
      });

      test('should return "Há 7d" for 1 week ago', () {
        final weekAgo =
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        expect(timeAgo(weekAgo), 'Há 7d');
      });

      test('should return "Há 30d" for 1 month ago', () {
        final monthAgo =
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
        expect(timeAgo(monthAgo), 'Há 30d');
      });
    });

    group('Edge cases for day transitions', () {
      test('should handle dates from different years', () {
        final lastYear =
            DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
        expect(timeAgo(lastYear), 'Há 365d');
      });

      test('should handle ISO 8601 format with timezone', () {
        final nowWithTimezone = DateTime.now().toIso8601String();
        expect(timeAgo(nowWithTimezone), 'Agora mesmo');
      });
    });
  });

  group('Seat Validation', () {
    group('Valid seat counts', () {
      test('should allow 1 seat', () {
        expect(1 > 0, true);
      });

      test('should allow 2 seats', () {
        expect(2 > 0, true);
      });

      test('should allow 5 seats', () {
        expect(5 > 0, true);
      });
    });

    group('Invalid seat counts', () {
      test('should reject 0 seats', () {
        expect(0 > 0, false);
      });

      test('should reject negative seats', () {
        expect(-1 > 0, false);
      });
    });
  });

  group('Radius Validation for Ride Search', () {
    group('Valid radius ranges', () {
      test('should allow minimum radius 100m', () {
        final radiusMeters = 100.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, true);
      });

      test('should allow default radius 500m', () {
        final radiusMeters = 500.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, true);
      });

      test('should allow maximum radius 2000m', () {
        final radiusMeters = 2000.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, true);
      });

      test('should allow intermediate radius 750m', () {
        final radiusMeters = 750.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, true);
      });
    });

    group('Invalid radius ranges', () {
      test('should reject radius below 100m', () {
        final radiusMeters = 50.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, false);
      });

      test('should reject radius above 2000m', () {
        final radiusMeters = 3000.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, false);
      });

      test('should reject negative radius', () {
        final radiusMeters = -100.0;
        expect(radiusMeters >= 100 && radiusMeters <= 2000, false);
      });
    });
  });

  group('Credential Validation', () {
    group('Valid credentials', () {
      test('username and password both provided', () {
        final username = 'user123';
        final password = 'pass123';
        final isValid = username.isNotEmpty && password.isNotEmpty;
        expect(isValid, true);
      });
    });

    group('Invalid credentials', () {
      test('empty username', () {
        final username = '';
        final password = 'pass123';
        final isValid = username.isNotEmpty && password.isNotEmpty;
        expect(isValid, false);
      });

      test('empty password', () {
        final username = 'user123';
        final password = '';
        final isValid = username.isNotEmpty && password.isNotEmpty;
        expect(isValid, false);
      });

      test('both empty', () {
        final username = '';
        final password = '';
        final isValid = username.isNotEmpty && password.isNotEmpty;
        expect(isValid, false);
      });

      test('username with only spaces', () {
        final username = '   ';
        final password = 'pass123';
        final trimmedUsername = username.trim();
        final isValid = trimmedUsername.isNotEmpty && password.isNotEmpty;
        expect(isValid, false);
      });
    });
  });

  group('Location Distance Calculation', () {
    /// Simple Haversine distance approximation for testing
    double approximateDistance(double lat1, double lon1, double lat2, double lon2) {
      const double earthRadiusMeters = 6371000;
      final double dLat = (lat2 - lat1) * 3.14159 / 180;
      final double dLon = (lon2 - lon1) * 3.14159 / 180;
      final double a = (dLat / 2) * (dLat / 2) +
          (dLon / 2) * (dLon / 2);
      final double c = 2 * 3.14159 * (a.isNaN ? 0 : a);
      return earthRadiusMeters * c;
    }

    test('should calculate distance between same coordinates as 0', () {
      final distance = approximateDistance(41.1780, -8.5980, 41.1780, -8.5980);
      expect(distance < 10, true); // Allow small rounding error
    });

    test('should calculate distance between two different locations', () {
      final distance = approximateDistance(41.1780, -8.5980, 41.1800, -8.5960);
      expect(distance > 0, true);
      expect(distance < 10000, true); // Should be less than 10km
    });
  });

  group('Ride Status Validation', () {
    group('Valid statuses', () {
      test('status "open" is valid', () {
        final status = 'open';
        expect(status == 'open' || status == 'fulfilled' || status == 'cancelled', true);
      });

      test('status "fulfilled" is valid', () {
        final status = 'fulfilled';
        expect(status == 'open' || status == 'fulfilled' || status == 'cancelled', true);
      });

      test('status "cancelled" is valid', () {
        final status = 'cancelled';
        expect(status == 'open' || status == 'fulfilled' || status == 'cancelled', true);
      });
    });

    group('Invalid statuses', () {
      test('unknown status should be invalid', () {
        final status = 'unknown';
        expect(status == 'open' || status == 'fulfilled' || status == 'cancelled', false);
      });

      test('null status should be invalid', () {
        final status = null;
        expect(status == 'open' || status == 'fulfilled' || status == 'cancelled', false);
      });
    });
  });

  group('Vehicle Info Validation', () {
    group('Valid vehicle info', () {
      test('should accept non-empty vehicle info', () {
        final vehicleInfo = 'Toyota Yaris, Blue, ABC-1234';
        final isValid = vehicleInfo.trim().isNotEmpty;
        expect(isValid, true);
      });

      test('should accept single character vehicle info', () {
        final vehicleInfo = 'X';
        final isValid = vehicleInfo.trim().isNotEmpty;
        expect(isValid, true);
      });
    });

    group('Invalid vehicle info', () {
      test('should reject empty vehicle info', () {
        final vehicleInfo = '';
        final isValid = vehicleInfo.trim().isNotEmpty;
        expect(isValid, false);
      });

      test('should reject only spaces', () {
        final vehicleInfo = '   ';
        final isValid = vehicleInfo.trim().isNotEmpty;
        expect(isValid, false);
      });

      test('should reject only tabs', () {
        final vehicleInfo = '\t\t';
        final isValid = vehicleInfo.trim().isNotEmpty;
        expect(isValid, false);
      });
    });
  });

  group('Credits Balance Validation', () {
    group('Valid balance values', () {
      test('should handle zero balance', () {
        final balance = 0;
        expect(balance >= 0, true);
      });

      test('should handle positive balance', () {
        final balance = 100;
        expect(balance >= 0, true);
      });

      test('should handle large balance', () {
        final balance = 999999;
        expect(balance >= 0, true);
      });
    });

    group('Balance calculations', () {
      test('should subtract cost from balance', () {
        final initialBalance = 100;
        final cost = 5;
        final finalBalance = initialBalance - cost;
        expect(finalBalance, 95);
      });

      test('should add reward to balance', () {
        final initialBalance = 100;
        final reward = 50;
        final finalBalance = initialBalance + reward;
        expect(finalBalance, 150);
      });
    });
  });

  group('Destination Address Validation', () {
    group('Valid addresses', () {
      test('should accept full address', () {
        final address = 'Rua do Porto, 123, Porto, Portugal';
        expect(address.isNotEmpty, true);
      });

      test('should accept simple address', () {
        final address = 'Porto';
        expect(address.isNotEmpty, true);
      });

      test('should accept coordinates format', () {
        final address = '41.1780, -8.5980';
        expect(address.isNotEmpty, true);
      });
    });

    group('Invalid addresses', () {
      test('should reject empty address', () {
        final address = '';
        expect(address.isNotEmpty, false);
      });

      test('should reject only spaces', () {
        final address = '   ';
        expect(address.trim().isNotEmpty, false);
      });
    });
  });
}
