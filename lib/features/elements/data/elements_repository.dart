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
    'K': (1, 4), 'Ca': (2, 4), 'Sc': (3, 4), 'Ti': (4, 4), 'V': (5, 4), 'Cr': (6, 4), 'Mn': (7, 4), 'Fe': (8, 4), 'Co': (9, 4), 'Ni': (10, 4), 'Cu': (11, 4), 'Zn': (12, 4), 'Ga': (13, 4), 'Ge': (14, 4), 'As': (15, 4), 'Se': (16, 4), 'Br': (17, 4), 'Kr': (18, 4),
    'Rb': (1, 5), 'Sr': (2, 5), 'Y': (3, 5), 'Zr': (4, 5), 'Nb': (5, 5), 'Mo': (6, 5), 'Tc': (7, 5), 'Ru': (8, 5), 'Rh': (9, 5), 'Pd': (10, 5), 'Ag': (11, 5), 'Cd': (12, 5), 'In': (13, 5), 'Sn': (14, 5), 'Sb': (15, 5), 'Te': (16, 5), 'I': (17, 5), 'Xe': (18, 5),
    'Cs': (1, 6), 'Ba': (2, 6), 'Hf': (4, 6), 'Ta': (5, 6), 'W': (6, 6), 'Re': (7, 6), 'Os': (8, 6), 'Ir': (9, 6), 'Pt': (10, 6), 'Au': (11, 6), 'Hg': (12, 6), 'Tl': (13, 6), 'Pb': (14, 6), 'Bi': (15, 6), 'Po': (16, 6), 'At': (17, 6), 'Rn': (18, 6),
    'Fr': (1, 7), 'Ra': (2, 7), 'Rf': (4, 7), 'Db': (5, 7), 'Sg': (6, 7), 'Bh': (7, 7), 'Hs': (8, 7), 'Mt': (9, 7), 'Ds': (10, 7), 'Rg': (11, 7), 'Cn': (12, 7), 'Nh': (13, 7), 'Fl': (14, 7), 'Mc': (15, 7), 'Lv': (16, 7), 'Ts': (17, 7), 'Og': (18, 7),
    'La': (3, 8), 'Ce': (4, 8), 'Pr': (5, 8), 'Nd': (6, 8), 'Pm': (7, 8), 'Sm': (8, 8), 'Eu': (9, 8), 'Gd': (10, 8), 'Tb': (11, 8), 'Dy': (12, 8), 'Ho': (13, 8), 'Er': (14, 8), 'Tm': (15, 8), 'Yb': (16, 8), 'Lu': (17, 8),
    'Ac': (3, 9), 'Th': (4, 9), 'Pa': (5, 9), 'U': (6, 9), 'Np': (7, 9), 'Pu': (8, 9), 'Am': (9, 9), 'Cm': (10, 9), 'Bk': (11, 9), 'Cf': (12, 9), 'Es': (13, 9), 'Fm': (14, 9), 'Md': (15, 9), 'No': (16, 9), 'Lr': (17, 9),
  };
}
