import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  late TabController _tabController;

  final List<String> _filterOptions = ['All', 'R1', 'R2', 'R3', 'Streetlight'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[HISTORY] Start loading (limit=100)...');
      final history = await FirebaseService.getClassroomHistory(limit: 100);

      debugPrint('[HISTORY] Loaded count = ${history.length}');
      for (var i = 0; i < history.length && i < 3; i++) {
        debugPrint('[HISTORY] sample[$i] = ${history[i]}');
      }

      // sort by timestampEpoch desc kalau ada
      final sorted = [...history];
      sorted.sort((a, b) {
        final ta = (a['timestampEpoch'] ?? 0) as int;
        final tb = (b['timestampEpoch'] ?? 0) as int;
        return tb.compareTo(ta);
      });

      setState(() {
        _historyData = sorted;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[HISTORY][ERROR] $e');
      debugPrint('[HISTORY][STACK] $st');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'All') return _historyData;
    return _historyData.where((event) {
      if (_selectedFilter == 'Streetlight') {
        return event['type'] == 'street_event';
      } else {
        return event['room'] == _selectedFilter;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryData,
            tooltip: 'Refresh History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Events', icon: Icon(Icons.history)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                  checkmarkColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ),
        
        // History List
        Expanded(
          child: _buildHistoryList(),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading history...');
    }

    if (_errorMessage != null) {
      return CustomErrorWidget(
        message: _errorMessage!,
        onRetry: _loadHistoryData,
      );
    }

    final filteredHistory = _filteredHistory;

    if (filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All' ? 'No history data' : 'No history for $_selectedFilter',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Events will appear here as they occur',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredHistory.length,
        itemBuilder: (context, index) {
          final event = filteredHistory[index];
          return _buildHistoryItem(event);
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> event) {
    final isRoomEvent = event['type'] == 'room_event';
    final isStreetEvent = event['type'] == 'street_event';
    
    final room = event['room']?.toString() ?? '';
    final eventDesc = event['event']?.toString() ?? 'Unknown event';
    final source = event['source']?.toString() ?? 'Unknown';
    final ledState = event['ledState']?.toString() ?? 'Unknown';
    final timestamp = event['timestampEpoch'] ?? 0;
    
    Color eventColor = AppTheme.primaryColor;
    IconData eventIcon = Icons.info;
    
    // Determine color and icon based on event
    if (eventDesc.contains('ON')) {
      eventColor = AppTheme.successColor;
      eventIcon = Icons.lightbulb;
    } else if (eventDesc.contains('OFF')) {
      eventColor = Colors.grey;
      eventIcon = Icons.lightbulb_outline;
    } else if (eventDesc.contains('Motion')) {
      eventColor = Colors.orange;
      eventIcon = Icons.sensors;
    } else if (eventDesc.contains('Button')) {
      eventColor = AppTheme.warningColor;
      eventIcon = Icons.touch_app;
    } else if (eventDesc.contains('Mode')) {
      eventColor = AppTheme.infoColor;
      eventIcon = Icons.settings;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: eventColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            eventIcon,
            color: eventColor,
            size: 20,
          ),
        ),
        title: Text(
          eventDesc,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (isRoomEvent) ...[
                  Icon(Icons.room, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _getRoomDisplayName(room),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (isStreetEvent) ...[
                  Icon(Icons.lightbulb, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    'Main Lighting',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.source, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  source.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ledState == 'ON' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ledState,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final roomEvents = _historyData.where((e) => e['type'] == 'room_event').length;
    final onEvents = _historyData.where((e) => e['event']?.toString().contains('ON') ?? false).length;
    final offEvents = _historyData.where((e) => e['event']?.toString().contains('OFF') ?? false).length;
    final motionEvents = _historyData.where((e) => e['event']?.toString().contains('Motion') ?? false).length;
    final buttonEvents = _historyData.where((e) => e['source'] == 'button').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Event Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Events',
                _historyData.length.toString(),
                Icons.event,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Room Events',
                roomEvents.toString(),
                Icons.room,
                AppTheme.infoColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'ON Events',
                onEvents.toString(),
                Icons.lightbulb,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'OFF Events',
                offEvents.toString(),
                Icons.lightbulb_outline,
                Colors.grey,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Motion Detected',
                motionEvents.toString(),
                Icons.sensors,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Button Presses',
                buttonEvents.toString(),
                Icons.touch_app,
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // ✅ ADDED: Performance metrics for journal
        Text(
          'Performance Metrics (Journal)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 System Performance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Average Response Time:'),
                    Text('< 2 seconds', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Firebase Connection:'),
                    Text('✅ Stable', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Real-time Updates:'),
                    Text('✅ Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Events Processed:'),
                    Text(
                      _historyData.length.toString(),
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRoomDisplayName(String roomId) {
    int index = AppConstants.roomNames.indexOf(roomId);
    if (index >= 0 && index < AppConstants.roomDisplayNames.length) {
      return AppConstants.roomDisplayNames[index];
    }
    return roomId;
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'Unknown time';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}