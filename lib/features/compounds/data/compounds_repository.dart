import 'dart:convert';

import 'package:flutter/services.dart';

class CompoundItem {
  final String id;
  final String name;
  final String formula;
  final String category;
  final String molarMass;
  final String state;
  final String summary;
  final String uses;
  final String safety;

  const CompoundItem({
    required this.id,
    required this.name,
    required this.formula,
    required this.category,
    required this.molarMass,
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
      molarMass: (json['molarMass'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      uses: (json['uses'] ?? '').toString(),
      safety: (json['safety'] ?? '').toString(),
    );
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
