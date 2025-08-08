// lib/main.dart (VERSÃO REFATORADA PARA O GEO DENGUE MONITOR)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// <<< 1. IMPORTS ATUALIZADOS PARA A NOVA LÓGICA DE DENGUE >>>

// Páginas Principais
import 'package:geo_forest_surveillance/pages/menu/splash_page.dart';
import 'package:geo_forest_surveillance/pages/menu/login_page.dart';
import 'package:geo_forest_surveillance/pages/menu/home_page.dart'; // Renomeado para representar o Menu Principal
import 'package:geo_forest_surveillance/pages/projetos/lista_projetos_page.dart'; // Será renomeado para lista_campanhas_page
import 'package:geo_forest_surveillance/pages/menu/paywall_page.dart';

// Páginas do Gerente
import 'package:geo_forest_surveillance/pages/gerente/gerente_main_page.dart';
import 'package:geo_forest_surveillance/pages/gerente/gerente_map_page.dart';

// Providers e Controllers (a maioria dos nomes pode ser mantida)
import 'package:geo_forest_surveillance/providers/map_provider.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart'; // Mantido para identificar o agente em campo
import 'package:geo_forest_surveillance/controller/login_controller.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/providers/gerente_provider.dart';


// PONTO DE ENTRADA PRINCIPAL DO APP
Future<void> main() async {
  // Garante que os bindings do Flutter estão prontos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do SQFlite para plataformas Desktop (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializa o Firebase se ainda não tiver sido inicializado
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Roda o AppServicesLoader, que mostra a Splash Screen enquanto outros serviços carregam
  runApp(const AppServicesLoader());
}

// Este widget lida com a inicialização de serviços que podem falhar ou demorar,
// mostrando uma tela de splash e tratando erros. Nenhuma mudança necessária aqui.
class AppServicesLoader extends StatefulWidget {
  const AppServicesLoader({super.key});

  @override
  State<AppServicesLoader> createState() => _AppServicesLoaderState();
}

class _AppServicesLoaderState extends State<AppServicesLoader> {
  late Future<void> _servicesInitializationFuture;

  @override
  void initState() {
    super.initState();
    _servicesInitializationFuture = _initializeRemainingServices();
  }

  Future<void> _initializeRemainingServices() async {
    try {
      // Pequeno delay para a splash screen ser visível
      await Future.delayed(const Duration(seconds: 2));
      
      // Ativa o Firebase App Check para segurança
      const androidProvider = kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
      await FirebaseAppCheck.instance.activate(androidProvider: androidProvider);
      
      // Força a orientação do app para retrato
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
    } catch (e) {
      debugPrint("!!!!!! ERRO NA INICIALIZAÇÃO DE SERVIÇOS SECUNDÁRIOS: $e !!!!!");
      rethrow; // Propaga o erro para o FutureBuilder
    }
  }

  void _retryInitialization() {
    setState(() {
      _servicesInitializationFuture = _initializeRemainingServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _servicesInitializationFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ErrorScreen(
              message: "Falha ao inicializar os serviços do aplicativo:\n${snapshot.error.toString()}",
              onRetry: _retryInitialization,
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashPage(),
          );
        }
        // Se tudo carregou, mostra o aplicativo principal
        return const MyApp();
      },
    );
  }
}

// O widget principal do aplicativo, agora adaptado para a nova lógica.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // <<< 2. PROVIDERS MANTIDOS, MAS COM PROPÓSITOS ATUALIZADOS >>>
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
        ChangeNotifierProvider(create: (_) => GerenteProvider()), // Para o dashboard do gerente de saúde
        ChangeNotifierProvider(create: (_) => MapProvider()), // Para o mapa de focos
        ChangeNotifierProvider(create: (_) => TeamProvider()), // Para identificar o agente de campo
      ],
      child: MaterialApp(
        title: 'Geo Dengue Monitor',
        debugShowCheckedModeBanner: false,
        theme: _buildThemeData(Brightness.light), // Você pode ajustar o tema como quiser
        darkTheme: _buildThemeData(Brightness.dark),
        
        // O AuthCheck decide para onde o usuário vai após a inicialização
        initialRoute: '/auth_check',
        
        // <<< 3. ROTAS ATUALIZADAS PARA O NOVO CONTEXTO >>>
        routes: {
          '/auth_check': (context) => const AuthCheck(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(title: 'Geo Dengue Monitor'), // Menu Principal
          '/lista_campanhas': (context) => const ListaProjetosPage(title: 'Minhas Campanhas'), // Aponta para a antiga lista de projetos
          '/paywall': (context) => const PaywallPage(),
          '/gerente_home': (context) => const GerenteMainPage(), // Dashboard do gerente
          '/gerente_map': (context) => const GerenteMapPage(), // Mapa geral do gerente
        },
      ),
    );
  }

  // Lógica de tema, pode ser mantida ou alterada
  ThemeData _buildThemeData(Brightness brightness) {
    final baseColor = const Color(0xFF00838F); // Um tom de azul/verde, bom para saúde
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: baseColor, brightness: brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightlight ? baseColor : Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

// Este widget verifica o estado de autenticação e licença para direcionar o usuário.
// A lógica é a mesma, apenas o destino muda.
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = context.watch<LoginController>();
    final licenseProvider = context.watch<LicenseProvider>();

    // Enquanto os controllers não estão prontos, mostra loading
    if (!loginController.isInitialized || licenseProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Se não está logado, vai para a tela de login
    if (!loginController.isLoggedIn) {
      return const LoginPage();
    }
    
    // Se houve erro na licença, mostra a tela de erro
    if (licenseProvider.error != null) {
      return ErrorScreen(
        message: "Não foi possível verificar sua licença:\n${licenseProvider.error}",
        onRetry: () => context.read<LicenseProvider>().fetchLicenseData(),
      );
    }
    
    // Se a licença é válida e ativa...
    final license = licenseProvider.licenseData;
    if (license != null && (license.status == 'ativa' || license.status == 'trial')) {
      // ...verifica o cargo do usuário
      if (license.cargo == 'gerente') {
        // Se for gerente, vai para a tela principal do gerente
        return const GerenteMainPage();
      } else {
        // Se for equipe de campo, vai para o menu principal de coleta
        return const HomePage(title: 'Geo Dengue Monitor');
      }
    } else {
      // Se a licença não for válida, vai para a tela de pagamento/planos
      return const PaywallPage();
    }
  }
}


// Widget genérico para exibir erros, nenhuma mudança necessária.
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 60),
              const SizedBox(height: 20),
              Text('Erro na Aplicação', style: TextStyle(color: Colors.red[700], fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Tentar Novamente'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}