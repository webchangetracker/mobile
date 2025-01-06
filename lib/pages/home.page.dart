import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wct_mobile/pages/login.page.dart';
import 'package:wct_mobile/pages/tracker_form.page.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/trackers_provider.dart';
import '../providers/dio_provider.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(selectedIndex.value == 0 ? 'Trackers' : 'Profile'),
      ),
      body: IndexedStack(
        index: selectedIndex.value,
        children: const [
          TrackersTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.value,
        onDestinationSelected: (index) => selectedIndex.value = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.track_changes),
            label: 'Trackers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: selectedIndex.value == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TrackerFormPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class TrackersTab extends HookConsumerWidget {
  const TrackersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(trackersProvider);

    Future<void> deleteTracker(int id) async {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('/trackers/$id');

        ref.invalidate(trackersProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tracker deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tracker: ${e.toString()}')),
          );
        }
      }
    }

    return trackersAsync.when(
      data: (trackers) {
        if (trackers.isEmpty) {
          return const Center(
            child: Text('No trackers yet. Create one by tapping the + button!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: trackers.length,
          itemBuilder: (context, index) {
            final tracker = trackers[index];
            return Card(
              child: ListTile(
                title: Text(tracker.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('URL: ${tracker.websiteUrl}'),
                    Text('Cron: ${tracker.cronExpr}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TrackerFormPage(tracker: tracker),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Tracker'),
                            content: Text(
                                'Are you sure you want to delete "${tracker.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  deleteTracker(tracker.id);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }
}

class ProfileTab extends HookConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    void logout() {
      ref.read(authProvider.notifier).logout();
      ref.invalidate(userProvider);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }

    return Center(
      child: userAsync.when(
        data: (user) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'Welcome, '),
                  TextSpan(
                    text: user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '!'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(text: 'Email: '),
                  TextSpan(
                    text: user.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) {
          logout();
          return Text('Error: ${error.toString()}');
        },
      ),
    );
  }
}
