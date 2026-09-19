import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Router placeholder: le route reali arrivano dalla Fase 1 in poi.
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('CiaMaFa')),
      ),
    ),
  ],
);
