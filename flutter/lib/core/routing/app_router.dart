import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/bookmarks/presentation/saved_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/featured/presentation/featured_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/venues/presentation/venues_screen.dart';
import '../../features/venues/presentation/venue_events_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/featured',
                builder: (context, state) => const FeaturedScreen(),
                routes: [
                  GoRoute(
                    path: 'event/:id',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedScreen(),
                routes: [
                  GoRoute(
                    path: 'event/:id',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(
                  scopeKey: 'events-tab',
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/just-announced',
                builder: (context, state) => const EventsScreen(
                  scopeKey: 'just-announced',
                  title: 'Just Announced',
                  defaultSort: 'createdAt,desc',
                  showDatePresets: false,
                  basePath: '/just-announced',
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => EventDetailScreen(
                      eventId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/venues',
                builder: (context, state) => const VenuesScreen(),
                routes: [
                  GoRoute(
                    path: ':id/events',
                    builder: (context, state) {
                      final venueId = state.pathParameters['id']!;
                      final venueName = state.uri.queryParameters['name'] ?? 'Venue';
                      final venueSlug = state.uri.queryParameters['slug'] ?? '';
                      return VenueEventsScreen(
                        venueId: venueId,
                        venueName: venueName,
                        venueSlug: venueSlug,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: ':eid',
                        builder: (context, state) => EventDetailScreen(
                          eventId: state.pathParameters['eid']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Featured',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'New',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Venues',
          ),
        ],
      ),
    );
  }
}
