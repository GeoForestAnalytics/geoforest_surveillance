// lib/pages/gerente/gerente_main_page.dart
import 'package:flutter/material.dart';
import 'package:geo_forest_surveillance/pages/gerente/gerente_dashboard_page.dart';
import 'package:geo_forest_surveillance/pages/menu/home_page.dart';

class GerenteMainPage extends StatefulWidget {
  const GerenteMainPage({super.key});

  @override
  State<GerenteMainPage> createState() => _GerenteMainPageState();
}

class _GerenteMainPageState extends State<GerenteMainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    GerenteDashboardPage(), // O Dashboard do gerente será refatorado
    HomePage(title: 'Modo de Campo', showAppBar: false), // Acesso ao menu de coleta
  ];

  // <<< TÍTULOS E LABELS ATUALIZADOS >>>
  static const List<String> _pageTitles = <String>[
    'Painel de Controle',
    'Modo de Campo',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles.elementAt(_selectedIndex)),
        automaticallyImplyLeading: false, 
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pin_drop_outlined),
            label: 'Campo',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}