import 'dart:convert';

import 'package:flutter/services.dart';

class CompoundItem {
  final String id;
  final String name;
  final String formula;
  final String category;
  final double molarMass;
  final String molarMassUnit;
  final String state;
  final String summary;
  final List<String> uses;
  final String safety;

  const CompoundItem({
    required this.id,
    required this.name,
    required this.formula,
    required this.category,
    required this.molarMass,
    required this.molarMassUnit,
    required this.state,
    required this.summary,
    required this.uses,
    required this.safety,
  });

  factory CompoundItem.fromJson(Map<String, dynamic> json) {
    return CompoundItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      formula: (json['formula'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      molarMass: _molarMass(json['molarMass'] ?? json['molar_mass']),
      molarMassUnit:
          (json['molarMassUnit'] ?? json['unit_mass'] ?? 'g/mol').toString(),
      state: (json['state'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      uses: _stringList(json['uses']),
      safety: (json['safety'] ?? '').toString(),
    );
  }

  String get formattedMolarMass =>
      '${molarMass.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} $molarMassUnit';

  static double _molarMass(dynamic value) {
    if (value is num) return value.toDouble();
    final match =
        RegExp(r'[0-9]+(?:\.[0-9]+)?').firstMatch(value?.toString() ?? '');
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? const [] : [text];
  }
}

class CompoundsRepository {
  List<CompoundItem>? _cache;

  Future<List<CompoundItem>> getAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/compounds.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _cache = decoded
        .map((e) => CompoundItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cache!;
  }

  Future<CompoundItem?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((compound) => compound.id == id);
    } catch (_) {
      return null;
    }
  }
}
