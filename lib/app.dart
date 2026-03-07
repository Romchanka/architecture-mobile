import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/marketplace/screens/companies_screen.dart';
import 'features/marketplace/screens/complexes_screen.dart';
import 'features/marketplace/screens/apartments_screen.dart';
import 'features/marketplace/screens/apartment_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';

/// Глобальные ключи для вложенных навигаторов каждого таба.
/// Позволяют навигации внутри таба не перекрывать нижнюю панель.
final marketplaceNavKey = GlobalKey<NavigatorState>();
final profileNavKey = GlobalKey<NavigatorState>();

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Обрабатываем кнопку "назад" — сначала pop внутри таба
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navKey = _currentIndex == 0 ? marketplaceNavKey : profileNavKey;
        if (navKey.currentState?.canPop() ?? false) {
          navKey.currentState!.pop();
        } else {
          // Если нечего попать — выходим из приложения
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Таб 1: Маркетплейс с вложенным навигатором
            Navigator(
              key: marketplaceNavKey,
              onGenerateRoute: (settings) {
                Widget page;
                switch (settings.name) {
                  case '/complexes':
                    final args = settings.arguments as Map<String, dynamic>;
                    page = ComplexesScreen(
                      companyId: args['companyId'],
                      companyName: args['companyName'],
                    );
                    break;
                  case '/apartments':
                    final args = settings.arguments as Map<String, dynamic>;
                    page = ApartmentsScreen(
                      companyId: args['companyId'],
                      complexId: args['complexId'],
                      complexName: args['complexName'],
                    );
                    break;
                  case '/apartment-detail':
                    final args = settings.arguments as Map<String, dynamic>;
                    page = ApartmentDetailScreen(
                      apartmentId: args['id'],
                      companyId: args['companyId'],
                    );
                    break;
                  default:
                    page = const CompaniesScreen();
                }
                return MaterialPageRoute(builder: (_) => page, settings: settings);
              },
            ),
            // Таб 2: Профиль
            Navigator(
              key: profileNavKey,
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                  settings: settings,
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              if (i == _currentIndex) {
                // Двойной тап — вернуться в корень таба
                final navKey = i == 0 ? marketplaceNavKey : profileNavKey;
                navKey.currentState?.popUntil((route) => route.isFirst);
              } else {
                setState(() => _currentIndex = i);
              }
            },
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textMuted,
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
      ),
    );
  }
}
