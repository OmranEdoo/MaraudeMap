import 'package:flutter/material.dart';

import '../models/maraude.dart';
import 'maraude_repository.dart';

class DemoMaraudeRepository implements MaraudeRepository {
  DemoMaraudeRepository._();

  static final DemoMaraudeRepository instance = DemoMaraudeRepository._();

  final List<Maraude> _maraudes = _seedMaraudes();

  static List<Maraude> _seedMaraudes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      Maraude(
        id: '1',
        associationName: 'TAYBA',
        location: 'Stalingrad',
        address: 'Place de la Bataille de Stalingrad, 75019 Paris',
        date: today,
        startTime: '19h',
        endTime: '20h',
        estimatedPlates: 100,
        distributionType: 'Standard',
        latitude: 48.8835,
        longitude: 2.3619,
        status: MaraudeStatus.planned,
      ),
      Maraude(
        id: '2',
        associationName: 'EILMY',
        location: 'Pont-Marie',
        address: 'Quai de l Hotel de Ville, 75004 Paris',
        date: today,
        startTime: '20h30',
        endTime: '21h',
        estimatedPlates: 120,
        distributionType: 'Standard',
        latitude: 48.8530,
        longitude: 2.3610,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: '3',
        associationName: 'TAYBA',
        location: 'Bastille',
        address: 'Place de la Bastille, 75011 Paris',
        date: today.subtract(const Duration(days: 5)),
        startTime: '19h30',
        endTime: '21h00',
        estimatedPlates: 110,
        distributionType: 'Standard',
        comment: 'Equipe complete',
        latitude: 48.8532,
        longitude: 2.3692,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: '4',
        associationName: 'Aurore',
        location: 'Porte de la Villette',
        address: 'Avenue de la Porte de la Villette, 75019 Paris',
        date: today.subtract(const Duration(days: 30)),
        startTime: '18h45',
        endTime: '20h00',
        estimatedPlates: 85,
        distributionType: 'Standard',
        latitude: 48.8985,
        longitude: 2.3887,
        status: MaraudeStatus.completed,
      ),
      Maraude(
        id: '5',
        associationName: 'TAYBA',
        location: 'Foyer Ivry',
        address: 'Rue Michelet, 94200 Ivry-sur-Seine',
        date: today.add(const Duration(days: 1)),
        startTime: '19h15',
        endTime: '20h15',
        estimatedPlates: 140,
        distributionType: 'Standard',
        latitude: 48.8151,
        longitude: 2.3872,
        status: MaraudeStatus.planned,
      ),
    ];
  }

  @override
  Future<Maraude> create(
    Maraude maraude, {
    String? createdBy,
  }) async {
    final created = maraude.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    _maraudes.add(created);
    return created;
  }

  @override
  Future<List<Maraude>> listForDate(DateTime date) async {
    return _maraudes
        .where((maraude) => DateUtils.isSameDay(maraude.date, date))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Maraude>> listPast({
    DateTime? beforeDate,
  }) async {
    final source = beforeDate ?? DateTime.now();
    final limit = DateTime(source.year, source.month, source.day);

    return _maraudes
        .where((maraude) => maraude.date.isBefore(limit))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Maraude> update(Maraude maraude) async {
    final index = _maraudes.indexWhere((item) => item.id == maraude.id);
    if (index != -1) {
      _maraudes[index] = maraude;
    }
    return maraude;
  }
}
