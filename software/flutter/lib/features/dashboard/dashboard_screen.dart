import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/area_provider.dart';
import '../../shared/providers/streetlight_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../widgets/home_carousel.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _carouselImages = ['assets/images/carouselImages_2.jpeg'];
  
  // ✅ DEBOUNCE manual refresh
  Timer? _refreshDebounce;

  Future<void> _refreshAll() async {
    _refreshDebounce?.cancel();

    final areaProvider = context.read<AreaProvider>();
    final streetlightProvider = context.read<StreetlightProvider>();

    final completer = Completer<void>();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), () async {
      await Future.wait([
        Future.microtask(() => areaProvider.refresh()),
        Future.microtask(() => streetlightProvider.refresh()),
      ]);
      completer.complete();
    });

    return completer.future;
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double bannerRatio = 3.0;
    final double headerHeight = screenWidth / bannerRatio;
    const double sidePadding = 16.0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body:  RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height:  headerHeight + MediaQuery.of(context).padding.top,
                    width: double.infinity,
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        SizedBox(
                          height:  headerHeight,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(27),
                              bottomRight:  Radius.circular(27),
                            ),
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: screenWidth,
                                height: headerHeight,
                                child: HomeCarousel(
                                  imageUrls: _carouselImages,
                                  height: headerHeight,
                                  autoPlay: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: sidePadding,
                    top: MediaQuery.of(context).padding.top + 10,
                    child: const _BrandChip(
                      iconSize: 24,
                      textSize: 20,
                      fontWeight: FontWeight.bold,
                      italic: false,
                      transparency: 0.40,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Positioned(
                    right:  sidePadding,
                    top: MediaQuery.of(context).padding.top + 10,
                    child: _ReloadButton(
                      onTap: _refreshAll,
                      transparency: 0.40,
                      iconColor: isDark ? Colors.white :  Colors.black87,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    left: sidePadding,
                    right: sidePadding,
                    bottom: -120,
                    child: _buildWelcomeHeaderSolid(isDark:  isDark),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 135)),
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedQuickStats(),
                    const SizedBox(height: 24),
                    _buildEnhancedClassroomAreas(),
                    const SizedBox(height: 24),
                    _buildMainLighting(),
                    const SizedBox(height: 24),
                    _buildEmergencyControls(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeaderSolid({required bool isDark}) {
    final Color subtitleColor = isDark ? const Color(0xFFBBDEFB) : const Color(0xFFE3F2FD);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:  BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment:  CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Smart Classroom',
            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor and control all classroom lighting systems',
            style: TextStyle(color: subtitleColor, fontSize:  13),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical:  6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child:  const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Connected', style: TextStyle(color:  Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickStats() {
    return Consumer<AreaProvider>(
      builder: (context, areaProvider, _) {
        if (areaProvider.isLoading) {
          return const LoadingWidget(message: 'Loading stats...');
        }

        final totalAreas = areaProvider.totalAreas;
        final onlineAreas = areaProvider.onlineAreas;
        final offlineAreas = areaProvider. offlineAreas;
        final occupiedAreas = areaProvider. areas.where((area) => area.isOccupied).length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Classroom', totalAreas. toString(), Icons.room, AppTheme.infoColor)),
                const SizedBox(width: 12),
                Expanded(child:  _buildStatCard('Active', onlineAreas.toString(), Icons.lightbulb, AppTheme. successColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Inactive', offlineAreas.toString(), Icons.lightbulb_outline, AppTheme.errorColor)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Occupied', occupiedAreas.toString(), Icons.people, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Empty', (totalAreas - occupiedAreas).toString(), Icons.people_outline, Colors.grey)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Occupancy',
                    totalAreas > 0 ? '${((occupiedAreas / totalAreas) * 100).toInt()}%' : '0%',
                    Icons. analytics,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ✅ CONST for static parts
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color. withOpacity(0.1),
        borderRadius: BorderRadius. circular(12),
        border: Border.all(color: color. withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),  // ✅ const
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEnhancedClassroomAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Classroom Areas', style: Theme.of(context).textTheme.titleLarge?. copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Consumer<AreaProvider>(
          builder: (context, areaProvider, _) {
            if (areaProvider.isLoading) return const LoadingWidget(message: 'Loading areas...');
            if (areaProvider.errorMessage != null) {
              return CustomErrorWidget(message: areaProvider.errorMessage!, onRetry: () => areaProvider.refresh());
            }
            return Column(children: areaProvider.areas.map((area) => _buildEnhancedAreaCard(area)).toList());
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedAreaCard(dynamic area) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child:  Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: area.statusColor, shape: BoxShape.circle)),
                const SizedBox(width:  16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment. start,
                    children: [
                      Row(
                        children: [
                          Text(area.displayName, style: const TextStyle(fontSize: 16, fontWeight:  FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: area.isOccupied ? Colors.orange : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(area.isOccupied ? Icons.people : Icons.people_outline, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  area.isOccupied ? 'OCCUPIED' : 'EMPTY',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${area.modeText} • ${area.isOn ? "ON" : "OFF"}', style: TextStyle(fontSize: 14, color: area.statusColor)),
                      Text('Updated: ${area.lastUpdatedFormatted}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: area. isOn,
                  onChanged: (value) {
                    context.read<AreaProvider>().setAreaOutput(area.name, value ?  'ON' : 'OFF');
                  },
                ),
              ],
            ),
            if (area.isOn) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Brightness', style: TextStyle(fontSize:  12)),
                      Text('${area.brightnessPercentage. toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: area.brightnessPercentage / 100,
                    backgroundColor: Colors.grey. shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(area.statusColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainLighting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Main Lighting', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Consumer<StreetlightProvider>(
          builder:  (context, streetlightProvider, _) {
            if (streetlightProvider.isLoading) return const LoadingWidget(message:  'Loading main lighting...');

            final streetlight = streetlightProvider.streetlight;
            return Card(
              child: Padding(
                padding:  const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration:  BoxDecoration(color: streetlight.statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment. start,
                        children: [
                          const Text('Main Classroom Lighting', style: TextStyle(fontSize: 16, fontWeight:  FontWeight.w600)),
                          const SizedBox(height:  4),
                          Text('${streetlight.modeText} • ${streetlight. isOn ? "ON" : "OFF"}', style: TextStyle(fontSize: 14, color: streetlight.statusColor)),
                        ],
                      ),
                    ),
                    Switch(value: streetlight.isOn, onChanged: (value) => streetlightProvider.setOutput(value ? 'ON' : 'OFF')),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emergency Controls', style: Theme.of(context).textTheme.titleLarge?. copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showEmergencyDialog,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emergency, size: 24),
                SizedBox(width: 12),
                Text('EMERGENCY STOP ALL', style: TextStyle(fontSize:  16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Emergency Stop')]),
          content: const Text('This will immediately turn OFF all lights in the classroom. This action cannot be undone.  Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AreaProvider>().emergencyStopAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🚨 Emergency stop executed - all lights turned OFF'), backgroundColor: Colors.red),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('STOP ALL'),
            ),
          ],
        );
      },
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.iconSize, required this. textSize, required this.fontWeight, required this.italic, required this.transparency, this.letterSpacing = 0.0});
  final double iconSize, textSize, transparency, letterSpacing;
  final FontWeight fontWeight;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? Colors.black. withOpacity(transparency) : Colors.white.withOpacity(transparency);
    final Color fg = isDark ? Colors.white : Colors. black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: isDark ? Colors.white : AppTheme.primaryColor, size: iconSize),
          const SizedBox(width: 8),
          Text(AppConstants.appName, style: TextStyle(color: fg, fontSize: textSize, fontWeight: fontWeight, fontStyle: italic ?  FontStyle.italic : FontStyle.normal, letterSpacing: letterSpacing)),
        ],
      ),
    );
  }
}

class _ReloadButton extends StatelessWidget {
  const _ReloadButton({required this.onTap, required this.transparency, required this.iconColor, this.size = 22});
  final VoidCallback onTap;
  final double transparency, size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness. dark;
    final Color bg = isDark ? Colors.black.withOpacity(transparency) : Colors.white.withOpacity(transparency);

    return SafeArea(
      minimum: const EdgeInsets.only(top: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.refresh, color: iconColor, size: size),
          ),
        ),
      ),
    );
  }
}