import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/settings_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/services.dart'; // for clipboard (copy)

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String university = 'Muhammadiyah University of Karanganyar';
  static const String program = 'Program: Computer Engineering';
  static const String lecturer = 'Erwin Apriliyanto, S.Kom., M.Kom';
  static const List<String> team = [
    'Sendy Tegar Mahendra (NIM: TK0122004)',
    'Rossi Arizona Dewantara Putra',
    'Muhammad Nur Sidiq (NIM: TK0122002)',
    'Uut Haryanto (NIM: TK0122023)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // TOP: centered logo + university + program
              Column(
                children: [
                  // Logo
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        const AssetImage('assets/images/univ_logo.png'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    university,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    program,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Institution Card (Lecturer + Team)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with title and copy button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Project Team & Lecturer',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            tooltip: 'Copy team info',
                            onPressed: () {
                              final info = StringBuffer()
                                ..writeln(university)
                                ..writeln(program)
                                ..writeln('Lecturer: $lecturer')
                                ..writeln('Team:')
                                ..writeln(team.join('\n'));
                              Clipboard.setData(
                                  ClipboardData(text: info.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Team info copied')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Lecturer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Supervising Lecturer',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(lecturer),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Team list
                      const Text('Team Members',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...team.map((name) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(fontSize: 18, height: 1.4)),
                                Expanded(child: Text(name)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // OTHER SETTINGS (e.g., Display)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Display',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme'),
                        value: settings.isDarkMode,
                        onChanged: (value) => settings.setDarkMode(value),
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Add more display-related settings here if needed
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Placeholder for more setting sections (you can add more cards below)
              // e.g., Notification, Privacy, About, etc.

              // APP INFORMATION at the BOTTOM
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('${AppConstants.appName} ${AppConstants.appVersion}'),
                      const SizedBox(height: 4),
                      const Text('Smart Classroom IoT Control'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}