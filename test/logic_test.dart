// DawaKhata — pure-logic tests: expiry day counts, low stock,
// stock value, date parsing.
import 'package:dawakhata/models.dart';
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
}
