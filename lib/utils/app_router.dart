// lib/utils/app_router.dart (VERSÃO FINAL E CORRIGIDA)

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

      // =======================================================
      // >> AS ROTAS QUE FALTAVAM FORAM ADICIONADAS AQUI <<
      // =======================================================
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      
      GoRoute(path: '/equipe', builder: (context, state) => const EquipePage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage(title: 'Geo Dengue Monitor')),
      GoRoute(path: '/paywall', builder: (context, state) => const PaywallPage()),
      GoRoute(path: '/gerente_home', builder: (context, state) => const GerenteMainPage()),
      
      // ESTRUTURA DE ROTAS PARA CAMPANHAS E NAVEGAÇÃO HIERÁRQUICA
      GoRoute(
        path: '/campanhas',
        builder: (context, state) => const ListaCampanhasPage(title: 'Minhas Campanhas',isImporting: false,),
        routes: [
          GoRoute(
            path: ':campanhaId', // Ex: /campanhas/1
            builder: (context, state) {
              final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
              return DetalhesCampanhaPage(campanhaId: campanhaId);
            },
            routes: [
              GoRoute(
                path: 'acoes/:acaoId', // Ex: /campanhas/1/acoes/2
                builder: (context, state) {
                   final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
                   final acaoId = int.tryParse(state.pathParameters['acaoId'] ?? '') ?? 0;
                   return DetalhesAcaoPage(campanhaId: campanhaId, acaoId: acaoId);
                },
                routes: [
                  GoRoute(
                    path: 'municipios/:municipioId', // Ex: /campanhas/1/acoes/2/municipios/3550308
                    builder: (context, state) {
                      final campanhaId = int.tryParse(state.pathParameters['campanhaId'] ?? '') ?? 0;
                      final acaoId = int.tryParse(state.pathParameters['acaoId'] ?? '') ?? 0;
                      final municipioId = state.pathParameters['municipioId'] ?? '';
                      return DetalhesMunicipioPage(campanhaId: campanhaId, acaoId: acaoId, municipioId: municipioId);
                    },
                    routes: [
                      GoRoute(
                        path: 'bairros/:bairroId', // Ex: /campanhas/1/acoes/2/municipios/3550308/bairros/3
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

    redirect: (BuildContext context, GoRouterState state) {
      if (!loginController.isInitialized || licenseProvider.isLoading || !teamProvider.isLoaded) {
        return '/splash';
      }
      final isLoggedIn = loginController.isLoggedIn;
      final currentRoute = state.matchedLocation;

      // Se não está logado, e não está tentando acessar login/registro, redireciona para login
      final publicRoutes = ['/login', '/register', '/forgot-password'];
      if (!isLoggedIn) {
        return publicRoutes.contains(currentRoute) ? null : '/login';
      }

      final license = licenseProvider.licenseData;
      if (license == null) {
        // Se está logado mas não tem licença, algo está errado, volta pro login
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
      
      // Se o usuário já passou por todas as verificações e está em uma página pública, redireciona para a home
      if (publicRoutes.contains(currentRoute) || currentRoute == '/splash' || currentRoute == '/equipe') {
        return isGerente ? '/gerente_home' : '/home';
      }
      
      return null;
    },
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text('A rota "${state.uri}" não existe.')),
    ),
 
  );
}