import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../shared/providers/area_provider.dart';
import '../shared/providers/streetlight_provider.dart';
import '../shared/providers/settings_provider.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/room_control/room_control_screen.dart';  // ✅ ADD
import '../features/history/history_screen.dart';            // ✅ ADD  
import '../features/settings/settings_screen.dart';          // ✅ ADD

class SmartClassroomApp extends StatelessWidget {
  const SmartClassroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AreaProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => StreetlightProvider()..initialize(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const RoomControlScreen(),   // ✅ NOW AVAILABLE
    const HistoryScreen(),       // ✅ NOW AVAILABLE
    const SettingsScreen(),      // ✅ NOW AVAILABLE
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb),
      label: 'Control',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}