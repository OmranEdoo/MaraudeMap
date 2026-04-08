import '../models/maraude.dart';

abstract class MaraudeRepository {
  Future<List<Maraude>> listForDate(DateTime date);
  Future<List<Maraude>> listPast({
    DateTime? beforeDate,
  });
  Future<Maraude> create(Maraude maraude, {
    String? createdBy,
  });
  Future<Maraude> update(Maraude maraude);
}
