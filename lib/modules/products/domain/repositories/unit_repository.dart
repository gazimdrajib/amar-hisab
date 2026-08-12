import '../entities/unit.dart';

abstract class UnitRepository {
  Future<List<Unit>> findAll(int businessId, {bool includeInactive = false});
  Future<Unit?> findById(int id);
  Future<Unit?> findByAbbreviation(int businessId, String abbreviation);
  Future<Unit> insert(Unit unit);
  Future<Unit> update(Unit unit);
  Future<void> deactivate(int id);
}
