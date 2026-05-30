import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'providers/goal_provider.dart';
import 'providers/record_provider.dart';
import 'screens/home_screen.dart';
import 'screens/goal_list_screen.dart';
import 'screens/record_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await ApiService.initialize(); // 자동 로그인 (백엔드 없어도 앱 실행됨)
  runApp(const DreamAchieverApp());
}

class DreamAchieverApp extends StatelessWidget {
  const DreamAchieverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
      ],
      child: MaterialApp(
        title: 'Dream Achiever',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en')],
        locale: const Locale('ko'),
        home: const SplashScreen(nextScreen: MainNavigation()), // 바로 메인으로!
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GoalListScreen(),
    const RecordScreen(),
    const AnalysisScreen(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF0E0D8), width: 1),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag, color: AppColors.primary),
              label: '목표',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit, color: AppColors.primary),
              label: '기록',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
              label: '분석',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
              label: '챗봇',
            ),
          ],
        ),
      ),
    );
  }
}
