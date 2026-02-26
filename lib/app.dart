import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/marketplace/screens/companies_screen.dart';
import 'features/marketplace/screens/complexes_screen.dart';
import 'features/marketplace/screens/apartments_screen.dart';
import 'features/marketplace/screens/apartment_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';

class ArchitectureApp extends ConsumerWidget {
  const ArchitectureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Квартиры Бишкек',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        // Companies → Complexes
        if (settings.name == '/complexes') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (ctx) => ComplexesScreen(
              companyId: args['companyId'],
              companyName: args['companyName'],
            ),
          );
        }
        // Complexes → Apartments
        if (settings.name == '/apartments') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (ctx) => ApartmentsScreen(
              companyId: args['companyId'],
              complexId: args['complexId'],
              complexName: args['complexName'],
            ),
          );
        }
        // Apartment detail
        if (settings.name == '/apartment-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (ctx) => ApartmentDetailScreen(
              apartmentId: args['id'],
              companyId: args['companyId'],
            ),
          );
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    CompaniesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_rounded),
              label: 'Маркетплейс',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }
}
