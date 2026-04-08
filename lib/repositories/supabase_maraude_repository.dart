import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maraude.dart';
import 'maraude_repository.dart';

class SupabaseMaraudeRepository implements MaraudeRepository {
  SupabaseMaraudeRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Maraude>> listForDate(DateTime date) async {
    final rows = await _client
        .from('maraudes')
        .select()
        .eq('date', Maraude.formatDatabaseDate(date))
        .order('start_time');

    return _rowsToMaraudes(rows);
  }

  @override
  Future<List<Maraude>> listPast({
    DateTime? beforeDate,
  }) async {
    final limitDate = beforeDate ?? DateTime.now();
    final rows = await _client
        .from('maraudes')
        .select()
        .lt('date', Maraude.formatDatabaseDate(limitDate))
        .order('date', ascending: false)
        .order('start_time');

    return _rowsToMaraudes(rows);
  }

  @override
  Future<Maraude> create(
    Maraude maraude, {
    String? createdBy,
  }) async {
    final payload = maraude.toSupabaseWriteMap(
      createdBy: createdBy,
      includeId: false,
    );

    final row = await _client.from('maraudes').insert(payload).select().single();
    return Maraude.fromSupabaseMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<Maraude> update(Maraude maraude) async {
    final row = await _client
        .from('maraudes')
        .update(maraude.toSupabaseWriteMap())
        .eq('id', maraude.id)
        .select()
        .single();

    return Maraude.fromSupabaseMap(Map<String, dynamic>.from(row));
  }

  List<Maraude> _rowsToMaraudes(dynamic rows) {
    final items = rows as List<dynamic>;
    return items
        .map((row) => Maraude.fromSupabaseMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}
