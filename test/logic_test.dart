// AH MEDICALS — pure-logic tests: expiry day counts, low stock,
// stock value, date parsing, seed sanity.
import 'package:ah_medicals_inventory/models.dart';
import 'package:ah_medicals_inventory/seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 26);

  test('daysToExpiry counts correctly', () {
    expect(daysToExpiry(DateTime(2026, 12, 18), now), 22);
    expect(daysToExpiry(DateTime(2026, 11, 26), now), 0);
    expect(daysToExpiry(DateTime(2026, 10, 15), now), -42);
    expect(daysToExpiry(DateTime(2027, 6, 30), now), 216);
  });

  test('expiryStatus bands: expired / 30 / 90 / ok', () {
    expect(expiryStatus(DateTime(2026, 10, 15), now), ExpiryStatus.expired);
    expect(expiryStatus(DateTime(2026, 12, 18), now), ExpiryStatus.near30);
    expect(expiryStatus(DateTime(2027, 1, 20), now), ExpiryStatus.near90);
    expect(expiryStatus(DateTime(2027, 6, 30), now), ExpiryStatus.ok);
  });

  test('low stock at or below min level', () {
    expect(isLowStock(5, 10), true);
    expect(isLowStock(10, 10), true);
    expect(isLowStock(11, 10), false);
  });

  test('stock value = stock x purchase price', () {
    expect(stockValue(120, 24.0), 2880.0);
    expect(stockValue(0, 100.0), 0.0);
  });

  test('parseDate rejects invalid dates', () {
    expect(parseDate('2027-06-30'), DateTime(2027, 6, 30));
    expect(parseDate('2027-13-01'), isNull);
    expect(parseDate('2027-02-30'), isNull);
    expect(parseDate('not-a-date'), isNull);
  });

  test('seed: 12 medicines, 1 expired, 1 near-30, 1 near-90, 2 low stock', () {
    expect(sampleMedicines.length, 12);
    final expired = sampleMedicines
        .where((m) => m.statusAt(now) == ExpiryStatus.expired)
        .length;
    final near30 = sampleMedicines
        .where((m) => m.statusAt(now) == ExpiryStatus.near30)
        .length;
    final near90 = sampleMedicines
        .where((m) => m.statusAt(now) == ExpiryStatus.near90)
        .length;
    final low = sampleMedicines.where((m) => m.lowStock).length;
    expect(expired, 1);
    expect(near30, 1);
    expect(near90, 1);
    expect(low, 2);
    // Total sample stock value is positive and consistent.
    final total = sampleMedicines.fold<double>(0, (s, m) => s + m.value);
    expect(total, greaterThan(20000));
    // Every seed medicine has the required fields.
    for (final m in sampleMedicines) {
      expect(m.name.isNotEmpty, true);
      expect(m.batch.isNotEmpty, true);
      expect(m.expiryDate, isNotNull);
      expect(m.mrp, greaterThan(0));
      expect(m.stock, greaterThanOrEqualTo(0));
    }
  });
}
