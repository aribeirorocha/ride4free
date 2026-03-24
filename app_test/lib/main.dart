import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_rating_button.dart';

void main() => runApp(const MyApp());

// ── Theme colours ─────────────────────────────────────────────────────────────

const kRed     = Color(0xFFD32F2F);
const kBlack   = Color(0xFF0A0A0A);
const kCard    = Color(0xFF1A1A1A);
const kDivider = Color(0xFF2C2C2C);
const kLight = Color(0x67676767);
const kLighter = Color(0x00000000);

// ── App ───────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBlack,
        colorScheme: const ColorScheme.dark(
          primary: kRed,
          surface: kCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        dividerColor: kDivider,
      ),
      home: const HomePage(),
    );
  }
}

// ── Home Page ─────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conference Tool'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kRed),
        ),
      ),
      body: Column(
        children: [
          // ── Profile rating section ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'RATE PROFILES',
                  style: TextStyle(
                    color: kRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                ProfileRatingButton(),
              ],
            ),
          ),

          Container(height: 1, color: kDivider),

          // ── Map label ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LOCATION',
                style: TextStyle(
                  color: kRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // ── Map ───────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(41.1496, -8.6109), // Porto
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.conference_tool',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: const LatLng(41.1496, -8.6109),
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.location_pin,
                            color: kRed,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}