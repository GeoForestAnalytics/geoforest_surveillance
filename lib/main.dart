// lib/main.dart (VERSÃO CORRIGIDA)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Imports do Projeto
import 'package:geo_forest_surveillance/providers/team_provider.dart';
import 'package:geo_forest_surveillance/controller/login_controller.dart';
import 'package:geo_forest_surveillance/pages/menu/splash_page.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/providers/gerente_provider.dart';
import 'package:geo_forest_surveillance/utils/app_router.dart';
import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:geo_forest_surveillance/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  const androidProvider = kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
  await FirebaseAppCheck.instance.activate(androidProvider: androidProvider);
  
  runApp(const AppServicesLoader());
}

class AppServicesLoader extends StatefulWidget {
  const AppServicesLoader({super.key});
  @override
  State<AppServicesLoader> createState() => _AppServicesLoaderState();
}

class _AppServicesLoaderState extends State<AppServicesLoader> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeAllServices();
  }

  Future<void> _initializeAllServices() async {
    try {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
    } catch (e) {
      debugPrint("!!!!!! ERRO NA INICIALIZAÇÃO DOS SERVIÇOS: $e !!!!!");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ErrorScreen(message: "Falha ao inicializar: ${snapshot.error}"),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(debugShowCheckedModeBanner: false, home: SplashPage());
        }
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
        ChangeNotifierProvider(create: (_) => GerenteProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        // =======================================================
        // >> CORREÇÃO APLICADA AQUI <<
        // =======================================================
        builder: (context, themeProvider, child) { // <<< O 'builder' PRECISA DOS 3 ARGUMENTOS
          final appRouter = AppRouter(
            loginController: context.read<LoginController>(),
            licenseProvider: context.read<LicenseProvider>(),
            teamProvider: context.read<TeamProvider>(),
          ).router;

          return MaterialApp.router(
            routerConfig: appRouter,
            title: 'Geo Dengue Monitor',
            debugShowCheckedModeBanner: false,
            theme: _buildThemeData(Brightness.light),
            darkTheme: _buildThemeData(Brightness.dark),
            themeMode: themeProvider.themeMode, // <<< AGORA O 'themeProvider' É RECONHECIDO
          );
        },
      ),
    );
  }

  ThemeData _buildThemeData(Brightness brightness) {
    final baseColor = const Color(0xFF00838F); // Tom de azul/verde para saúde
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: baseColor,
        brightness: brightness,
        surface: isLight ? Colors.grey[50] : Colors.grey[900],
        background: isLight ? Colors.white : Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? baseColor : Colors.grey[850],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Erro: $message', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
