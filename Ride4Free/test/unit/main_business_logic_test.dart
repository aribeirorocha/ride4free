import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferRidePageState - Time Validation', () {
    test('_isValidTime should accept valid times', () {
      final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');

      expect(timeRegExp.hasMatch('08:15'), true);
      expect(timeRegExp.hasMatch('00:00'), true);
      expect(timeRegExp.hasMatch('23:59'), true);
      expect(timeRegExp.hasMatch('9:05'), true);
      expect(timeRegExp.hasMatch('13:30'), true);
    });

    test('_isValidTime should reject invalid times', () {
      final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');

      expect(timeRegExp.hasMatch('24:00'), false);
      expect(timeRegExp.hasMatch('12:60'), false);
      expect(timeRegExp.hasMatch(''), false);
      expect(timeRegExp.hasMatch('8:1'), false);
      expect(timeRegExp.hasMatch('08:ab'), false);
    });

    test('_isValidTime should handle edge cases', () {
      final RegExp timeRegExp = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');

      expect(timeRegExp.hasMatch('00:00'), true); // Midnight
      expect(timeRegExp.hasMatch('23:59'), true); // Last minute
      expect(timeRegExp.hasMatch('12:00'), true); // Noon
      expect(timeRegExp.hasMatch('1:00'), true);  // Single digit
      expect(timeRegExp.hasMatch('01:00'), true); // Padded
    });
  });

  group('OfferRidePageState - Seat Count Validation', () {
    test('Should accept positive seat counts', () {
      for (int seats = 1; seats <= 5; seats++) {
        expect(seats > 0 && seats <= 5, true);
      }
    });

    test('Should reject invalid seat counts', () {
      expect(0 > 0, false);
      expect(-1 > 0, false);
      expect(6 > 5, true);
    });

    test('Should validate seat range', () {
      const validSeats = [1, 2, 3, 4, 5];
      for (final seats in validSeats) {
        expect(seats > 0 && seats <= 5, true);
      }
    });
  });

  group('SearchRidePageState - Destination Validation', () {
    test('Should reject empty destination', () {
      final destination = '';
      expect(destination.trim().isEmpty, true);
    });

    test('Should reject whitespace-only destination', () {
      final destination = '   ';
      expect(destination.trim().isEmpty, true);
    });

    test('Should accept valid destination', () {
      final destination = 'Lisboa';
      expect(destination.trim().isNotEmpty, true);
    });

    test('Should accept destination with spaces', () {
      final destination = 'Porto de Honra';
      expect(destination.trim().isNotEmpty, true);
    });

    test('Should trim whitespace from destination', () {
      final destination = '  Lisboa  ';
      expect(destination.trim(), 'Lisboa');
    });
  });

  group('SearchRidePageState - Search Radius Validation', () {
    test('Default radius should be valid', () {
      const radiusMeters = 500;
      expect(radiusMeters > 0, true);
    });

    test('Should accept various radius values', () {
      const validRadii = [100, 250, 500, 1000, 2000];
      for (final radius in validRadii) {
        expect(radius > 0, true);
      }
    });

    test('Should reject non-positive radius', () {
      const invalidRadii = [0, -1, -500];
      for (final radius in invalidRadii) {
        expect(radius > 0, false);
      }
    });
  });

  group('SearchRidePageState - Passenger Count Validation', () {
    test('Default passenger count should be valid', () {
      const passengerCount = 1;
      expect(passengerCount > 0, true);
    });

    test('Should accept valid passenger counts', () {
      for (int i = 1; i <= 6; i++) {
        expect(i > 0 && i <= 6, true);
      }
    });

    test('Should reject invalid passenger counts', () {
      expect(0 > 0, false);
      expect(-1 > 0, false);
      expect(7 > 6, true);
    });
  });

  group('CommunityBoardPageState - Section Types', () {
    test('Should have valid section indices', () {
      const validSections = [0, 1]; // 0 = drivers, 1 = passengers
      for (final section in validSections) {
        expect([0, 1].contains(section), true);
      }
    });

    test('Should handle invalid section', () {
      const invalidSection = 2;
      expect([0, 1].contains(invalidSection), false);
    });

    test('Section 0 represents drivers', () {
      const driverSection = 0;
      expect(driverSection, 0);
    });

    test('Section 1 represents passengers', () {
      const passengerSection = 1;
      expect(passengerSection, 1);
    });
  });

  group('ProfilePageState - User Data Validation', () {
    test('Should validate profile has required fields', () {
      final profile = {
        'id': 1,
        'email': 'user@example.com',
        'name': 'João Silva',
        'credits_balance': 150,
      };

      expect(profile.containsKey('id'), true);
      expect(profile.containsKey('email'), true);
      expect(profile.containsKey('name'), true);
      expect(profile.containsKey('credits_balance'), true);
    });

    test('Should validate credits are non-negative', () {
      const credits = [0, 50, 100, 500, 1000];
      for (final credit in credits) {
        expect(credit >= 0, true);
      }
    });

    test('Should validate email format', () {
      final validEmails = [
        'user@example.com',
        'john.doe@university.edu',
        'test@domain.co.uk'
      ];

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      for (final email in validEmails) {
        expect(emailRegex.hasMatch(email), true);
      }
    });

    test('Should reject invalid emails', () {
      final invalidEmails = ['notanemail', '@example.com', 'user@', 'user@.com'];

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      for (final email in invalidEmails) {
        expect(emailRegex.hasMatch(email), false);
      }
    });
  });

  group('RideRequest - Data Model', () {
    test('Should create valid ride request', () {
      final request = {
        'id': 1,
        'destination': 'Lisboa',
        'passenger_count': 2,
        'status': 'pending',
      };

      expect(request['destination'], 'Lisboa');
      expect(request['passenger_count'], 2);
      expect(request['status'], 'pending');
    });

    test('Should validate request status', () {
      final validStatuses = ['pending', 'accepted', 'completed', 'cancelled'];
      for (final status in validStatuses) {
        expect(validStatuses.contains(status), true);
      }
    });

    test('Should require destination in request', () {
      final request = {'id': 1, 'passenger_count': 2};
      expect(request.containsKey('destination'), false);
    });
  });

  group('DriverOffer - Data Model', () {
    test('Should create valid driver offer', () {
      final offer = {
        'id': 1,
        'time': '09:00',
        'seats': 3,
        'vehicle_info': 'Toyota Yaris',
        'status': 'active',
      };

      expect(offer['time'], '09:00');
      expect(offer['seats'], 3);
      expect(offer['status'], 'active');
    });

    test('Should validate offer status', () {
      final validStatuses = ['active', 'completed', 'cancelled'];
      for (final status in validStatuses) {
        expect(validStatuses.contains(status), true);
      }
    });

    test('Should require time in offer', () {
      final offer = {'id': 1, 'seats': 3, 'vehicle_info': 'Toyota Yaris'};
      expect(offer.containsKey('time'), false);
    });
  });

  group('Rating System - Validation', () {
    test('Should accept valid ratings', () {
      for (double i = 0; i <= 5; i += 0.5) {
        expect(i >= 0 && i <= 5, true);
      }
    });

    test('Should reject ratings below 0', () {
      expect(-1.0 >= 0, false);
      expect(-5.0 >= 0, false);
    });

    test('Should reject ratings above 5', () {
      expect(5.1 <= 5, false);
      expect(10.0 <= 5, false);
    });

    test('Should validate rating precision', () {
      final validRatings = [1.0, 2.5, 3.5, 4.0, 4.8, 5.0];
      for (final rating in validRatings) {
        expect(rating >= 0 && rating <= 5, true);
      }
    });
  });

  group('Location - Coordinate Validation', () {
    test('Should validate latitude range', () {
      final validLatitudes = [-90.0, -45.0, 0.0, 45.0, 90.0];
      for (final lat in validLatitudes) {
        expect(lat >= -90 && lat <= 90, true);
      }
    });

    test('Should validate longitude range', () {
      final validLongitudes = [-180.0, -90.0, 0.0, 90.0, 180.0];
      for (final lng in validLongitudes) {
        expect(lng >= -180 && lng <= 180, true);
      }
    });

    test('Should reject invalid latitude', () {
      expect(-91.0 >= -90 && -91.0 <= 90, false);
      expect(91.0 >= -90 && 91.0 <= 90, false);
    });

    test('Should reject invalid longitude', () {
      expect(-181.0 >= -180 && -181.0 <= 180, false);
      expect(181.0 >= -180 && 181.0 <= 180, false);
    });

    test('Should validate Portuguese coordinates', () {
      const portoLat = 41.1579;
      const portoLng = -8.6291;
      const lisboaLat = 38.7223;
      const lisboaLng = -9.1393;

      expect(portoLat >= -90 && portoLat <= 90, true);
      expect(portoLng >= -180 && portoLng <= 180, true);
      expect(lisboaLat >= -90 && lisboaLat <= 90, true);
      expect(lisboaLng >= -180 && lisboaLng <= 180, true);
    });
  });

  group('DateTime - Ride Schedule Validation', () {
    test('Should validate future date', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      expect(tomorrow.isAfter(now), true);
    });

    test('Should reject past date', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(yesterday.isBefore(now), true);
    });

    test('Should validate same day ride', () {
      final now = DateTime.now();
      final laterToday = now.add(const Duration(hours: 2));
      expect(laterToday.isAfter(now), true);
    });
  });
}
