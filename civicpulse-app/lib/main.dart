import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/api_endpoints.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await ApiEndpoints.init();
  runApp(
    const ProviderScope(
      child: CivicPulseApp(),
    ),
  );
}
