import 'package:flutter/material.dart';

class AnalyticsService {
  NavigatorObserver get navObserver => _NavObserver();

  void logEvent(String name, {Map<String, Object?>? params}) {
    // MVP: solo imprime. Luego lo conectas a Firebase/PostHog.
    // ignore: avoid_print
    print('[analytics] $name ${params ?? {}}');
  }
}

class _NavObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // ignore: avoid_print
    print('[nav] push: ${route.settings.name ?? route.runtimeType}');
  }
}
