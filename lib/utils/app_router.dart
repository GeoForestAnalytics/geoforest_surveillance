// lib/utils/app_router.dart (VERSÃO COM CORREÇÃO DO LOOP DE REDIRECIONAMENTO)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Providers e Controllers
import 'package:geo_forest_surveillance/controller/login_controller.dart';
import 'package:geo_forest_surveillance/providers/license_provider.dart';
import 'package:geo_forest_surveillance/providers/team_provider.dart';

// Páginas da Aplicação
import 'package:geo_forest_surveillance/pages/menu/splash_page.dart';
import 'package:geo_forest_surveillance/pages/menu/login_page.dart';
import 'package:geo_forest_surveillance/pages/menu/equipe_page.dart';
import 'package:geo_forest_surveillance/pages/menu/home_page.dart';
import 'package:geo_forest_surveillance/pages/menu/paywall_page.dart';
import 'package:geo_forest_surveillance/pages/gerente/gerente_main_page.dart';
import 'package:geo_forest_surveillance/pages/projetos/detalhes_campanha_page.dart';
import 'package:geo_forest_surveillance/pages/acoes/detalhes_acao_page.dart';
import 'package:geo_forest_surveillance/pages/municipios/detalhes_municipio_page.dart';
import 'package:geo_forest_surveillance/pages/bairros/detalhes_bairro_page.dart';
import 'package:geo_forest_surveillance/pages/projetos/lista_campanhas_page.dart';
import 'package:geo_forest_surveillance/pages/menu/register_page.dart';
import 'package:geo_forest_surveillance/pages/menu/forgot_password_page.dart';


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
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/equipe', builder: (context, state) => const EquipePage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage(title: 'Geo Dengue Monitor')),
      GoRoute(path: '/paywall', builder: (context, state) => const PaywallPage()),
      GoRoute(path: '/gerente_home', builder: (context, state) => const GerenteMainPage()),
      
      GoRoute(
        path: '/campanhas',
        builder: (context, state) => const ListaCampanhasPage(title: 'Minhas Campanhas',isImporting: false,),
        routes: [
          GoRoute(
            path: ':campanhaId',
            builder: (context, state) {
              final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
              return DetalhesCampanhaPage(campanhaId: campanhaId);
            },
            routes: [
              GoRoute(
                path: 'acoes/:acaoId',
                builder: (context, state) {
                   final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
                   final acaoId = int.tryParse(state.pathParameters['acaoId'] ?? '') ?? 0;
                   return DetalhesAcaoPage(campanhaId: campanhaId, acaoId: acaoId);
                },
                routes: [
                  GoRoute(
                    path: 'municipios/:municipioId',
                    builder: (context, state) {
                      final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
                      final acaoId = int.tryParse(state.pathParameters['acaoId'] ?? '') ?? 0;
                      final municipioId = state.pathParameters['municipioId'] ?? '';
                      return DetalhesMunicipioPage(campanhaId: campanhaId, acaoId: acaoId, municipioId: municipioId);
                    },
                    routes: [
                      GoRoute(
                        path: 'bairros/:bairroId',
                        builder: (context, state) {
                          final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
                          final acaoId = int.tryParse(state.pathParameters['acaoId'] ?? '') ?? 0;
                          final municipioId = state.pathParameters['municipioId'] ?? '';
                          final bairroId = int.tryParse(state.pathParameters['bairroId'] ?? '') ?? 0;
                          return DetalhesBairroPage(
                            campanhaId: campanhaId,
                            acaoId: acaoId,
                            municipioId: municipioId,
                            bairroId: bairroId,
                          );
                        },
                      ),
                    ]
                  ),
                ]
              ),
            ]
          ),
        ],
      ),
    ],

    // ===========================================
    // >> LÓGICA DE REDIRECIONAMENTO CORRIGIDA <<
    // ===========================================
    redirect: (BuildContext context, GoRouterState state) {
      final isInitializing = !loginController.isInitialized || licenseProvider.isLoading || !teamProvider.isLoaded;
      final isLoggedIn = loginController.isLoggedIn;
      final currentRoute = state.matchedLocation;
      final publicRoutes = ['/login', '/register', '/forgot-password'];

      // Se estiver inicializando, mostre o splash. A exceção é se já tivermos caído na tela de login,
      // para evitar o loop de redirecionamento.
      if (isInitializing && !publicRoutes.contains(currentRoute)) {
        return '/splash';
      }

      // Se não estiver logado
      if (!isLoggedIn) {
        // Se já estiver em uma rota pública, pode ficar. Senão, vai para o login.
        return publicRoutes.contains(currentRoute) ? null : '/login';
      }

      // Se chegou aqui, O USUÁRIO ESTÁ LOGADO
      final license = licenseProvider.licenseData;
      if (license == null) {
        // Logado mas sem licença? Algo muito errado. Volta para o login para segurança.
        return '/login';
      }

      final isLicenseOk = (license.status == 'ativa' || license.status == 'trial');
      if (!isLicenseOk) {
        return currentRoute == '/paywall' ? null : '/paywall';
      }
      
      final isGerente = license.cargo == 'gerente';
      final precisaIdentificarEquipe = !isGerente && (teamProvider.lider == null || teamProvider.lider!.isEmpty);
      if (precisaIdentificarEquipe) {
        return currentRoute == '/equipe' ? null : '/equipe';
      }
      
      // Se o usuário já logado está em alguma página inicial/pública, redireciona para a home correta.
      if (publicRoutes.contains(currentRoute) || currentRoute == '/splash' || currentRoute == '/equipe') {
        return isGerente ? '/gerente_home' : '/home';
      }
      
      // Se nenhuma regra se aplica, não redireciona.
      return null;
    },
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text('A rota "${state.uri}" não existe.')),
    ),
 
  );
}