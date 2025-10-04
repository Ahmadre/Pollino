import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'screens/home_screen.dart';
import 'screens/poll_screen.dart';

final routes = RouteMap(
  routes: {
    '/': (_) => const MaterialPage(child: HomeScreen()),
    '/poll/:id': (info) => MaterialPage(child: PollScreen(pollId: info.pathParameters['id']!)),
  },
);