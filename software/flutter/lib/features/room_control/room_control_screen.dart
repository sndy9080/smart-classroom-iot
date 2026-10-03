import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/area_provider.dart';
import '../../core/theme/app_theme.dart';

class RoomControlScreen extends StatelessWidget {
  const RoomControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Control'),
        centerTitle: true,
      ),
      body: Consumer<AreaProvider>(
        builder: (context, areaProvider, _) {
          if (areaProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading room data...'),
                ],
              ),
            );
          }

          if (areaProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${areaProvider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => areaProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: areaProvider.areas.length,
            itemBuilder: (context, index) {
              final area = areaProvider.areas[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Area Header
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: area.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  area.displayName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${area.modeText} • ${area.isOn ? "ON" : "OFF"}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: area.statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: area.isOn,
                            onChanged: (value) async {
                              final success = await areaProvider.setAreaOutput(
                                area.name, 
                                value ? 'ON' : 'OFF'
                              );
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to toggle ${area.displayName}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Mode Control Buttons
                      Text(
                        'Mode Control',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeButton(
                              context,
                              'Auto',
                              area.currentMode == 0,
                              AppTheme.areaAutoColor,
                              () => areaProvider.setAreaMode(area.name, 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModeButton(
                              context,
                              'Manual',
                              area.currentMode == 1,
                              AppTheme.areaManualColor,
                              () => areaProvider.setAreaMode(area.name, 1),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildModeButton(
                              context,
                              'Always ON',
                              area.currentMode == 2,
                              AppTheme.areaAlwaysOnColor,
                              () => areaProvider.setAreaMode(area.name, 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModeButton(
                              context,
                              'Always OFF',
                              area.currentMode == 3,
                              AppTheme.areaAlwaysOffColor,
                              () => areaProvider.setAreaMode(area.name, 3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String label,
    bool isActive,
    Color activeColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? activeColor : null,
        foregroundColor: isActive ? Colors.white : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}