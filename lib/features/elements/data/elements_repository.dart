import 'dart:convert';
import 'package:flutter/services.dart';

class ElementItem {
  final String id;
  final String name;
  final String symbol;
  final int atomicNumber;
  final String category;
  final String summary;
  final String uses;
  final String funFact;
  final int x;
  final int y;

  const ElementItem({
    required this.id,
    required this.name,
    required this.symbol,
    required this.atomicNumber,
    required this.category,
    required this.summary,
    required this.uses,
    required this.funFact,
    required this.x,
    required this.y,
  });

  factory ElementItem.fromJson(Map<String, dynamic> json, int x, int y) {
    return ElementItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      atomicNumber: (json['atomicNumber'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      uses: (json['uses'] ?? '').toString(),
      funFact: (json['funFact'] ?? '').toString(),
      x: x,
      y: y,
    );
  }
}

class ElementsRepository {
  List<ElementItem>? _cache;

  Future<List<ElementItem>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/elements.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _cache = decoded.map((e) {
      final json = e as Map<String, dynamic>;
      final symbol = (json['symbol'] ?? '').toString();
      final pos = _elementPositions[symbol] ?? (0, 0);
      return ElementItem.fromJson(json, pos.$1, pos.$2);
    }).toList();

    return _cache!;
  }

  Future<ElementItem?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Mapa de coordenadas (columna 1-18, fila 1-10)
  static const Map<String, (int, int)> _elementPositions = {
    'H': (1, 1), 'He': (18, 1),
    'Li': (1, 2), 'Be': (2, 2), 'B': (13, 2), 'C': (14, 2), 'N': (15, 2), 'O': (16, 2), 'F': (17, 2), 'Ne': (18, 2),
    'Na': (1, 3), 'Mg': (2, 3), 'Al': (13, 3), 'Si': (14, 3), 'P': (15, 3), 'S': (16, 3), 'Cl': (17, 3), 'Ar': (18, 3),
    'K': (1, 4), 'Ca': (2, 4), 'Sc': (3, 4), 'Ti': (4, 4), 'V': (5, 4), 'Cr': (6, 4), 'Mn': (7, 4), 'Fe': (8, 4), 'Co': (9, 4), 'Ni': (10, 4), 'Cu': (11, 4), 'Zn': (12, 4),
  };
}
