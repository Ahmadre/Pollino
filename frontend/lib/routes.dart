import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'screens/home_screen.dart';
import 'screens/poll_screen.dart';
import 'screens/admin_screen.dart';

final routes = RouteMap(
  routes: {
    '/': (_) => const MaterialPage(child: HomeScreen()),
    '/poll/:id': (info) => MaterialPage(child: PollScreen(pollId: info.pathParameters['id']!)),
    '/admin/:pollId/:token': (info) => MaterialPage(
          child: AdminScreen(
            pollId: info.pathParameters['pollId']!,
            adminToken: info.pathParameters['token']!,
          ),
        ),
  },
);
