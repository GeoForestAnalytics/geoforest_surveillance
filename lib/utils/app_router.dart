// lib/utils/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Providers e Controllers
import 'package:geo_forest_surveillance/controller/login_controller.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';

// Páginas
import 'package:geo_forest_surveillance/pages/menu/splash_page.dart';
import 'package:geo_forest_surveillance/pages/menu/login_page.dart';
import 'package:geo_forest_surveillance/pages/menu/equipe_page.dart';
import 'package:geo_forest_surveillance/pages/menu/home_page.dart';
import 'package:geo_forest_surveillance/pages/projetos/lista_campanhas_page.dart';
import 'package:geo_forest_surveillance/pages/menu/paywall_page.dart';
import 'package:geo_forest_surveillance/pages/gerente/gerente_main_page.dart';

class AppRouter {
  final LoginController loginController;
  final LicenseProvider licenseProvider;
  final TeamProvider teamProvider;

  AppRouter({
    required this.loginController,
    required this.licenseProvider,
    required this.teamProvider,
  });

  late final GoRouter router = GoRouter(
    refreshListenable: Listenable.merge([loginController, licenseProvider, teamProvider]),
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/equipe', builder: (context, state) => const EquipePage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage(title: 'Geo Dengue Monitor')),
      GoRoute(path: '/paywall', builder: (context, state) => const PaywallPage()),
      GoRoute(path: '/gerente_home', builder: (context, state) => const GerenteMainPage()),
      GoRoute(
        path: '/campanhas',
        builder: (context, state) => const ListaCampanhasPage(title: 'Minhas Campanhas'),
        // Rotas filhas (detalhes da campanha, etc.) virão aqui
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // 1. Aguarda inicialização dos providers
      if (!loginController.isInitialized || licenseProvider.isLoading || !teamProvider.isLoaded) {
        return '/splash';
      }
      
      final bool isLoggedIn = loginController.isLoggedIn;
      final String currentRoute = state.matchedLocation;

      // 2. Se não está logado, força a ida para /login
      if (!isLoggedIn) {
        return currentRoute == '/login' ? null : '/login';
      }

      // 3. Se está logado, verifica a licença
      final license = licenseProvider.licenseData;
      if (license == null) {
        return '/login'; // Algo deu errado, volta para o login
      }
      
      final bool isLicenseOk = (license.status == 'ativa' || license.status == 'trial');
      if (!isLicenseOk) {
        return currentRoute == '/paywall' ? null : '/paywall';
      }
      
      // 4. Se a licença está OK, verifica a identificação da equipe (apenas para não-gerentes)
      final bool isGerente = license.cargo == 'gerente';
      final bool precisaIdentificarEquipe = !isGerente && (teamProvider.lider == null || teamProvider.lider!.isEmpty);
      
      if (precisaIdentificarEquipe) {
        return currentRoute == '/equipe' ? null : '/equipe';
      }

      // 5. Se já passou por todas as verificações, não deixa voltar para as telas iniciais
      if (currentRoute == '/login' || currentRoute == '/splash' || currentRoute == '/equipe') {
        return isGerente ? '/gerente_home' : '/home';
      }
      
      // Se nenhuma regra de redirecionamento se aplicou, permite a navegação.
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text('A rota "${state.uri}" não existe.')),
    ),
  );
}