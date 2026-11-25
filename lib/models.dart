// AH MEDICALS — data models + pure logic (no Flutter UI here, so it is
// unit-testable with plain `flutter test`).

enum ExpiryStatus { expired, near30, near90, ok }

/// Days from [now] until [expiry]. Negative = already expired.
int daysToExpiry(DateTime expiry, DateTime now) {
  final a = DateTime(now.year, now.month, now.day);
  final b = DateTime(expiry.year, expiry.month, expiry.day);
  return b.difference(a).inDays;
}

ExpiryStatus expiryStatus(DateTime expiry, DateTime now) {
  final d = daysToExpiry(expiry, now);
  if (d < 0) return ExpiryStatus.expired;
  if (d <= 30) return ExpiryStatus.near30;
  if (d <= 90) return ExpiryStatus.near90;
  return ExpiryStatus.ok;
}

bool isLowStock(int stock, int minStock) => stock <= minStock;

/// Stock value = stock x purchase price, in paise-safe doubles (rupees).
double stockValue(int stock, double purchasePrice) => stock * purchasePrice;

/// Parse a yyyy-MM-dd date, null when invalid.
DateTime? parseDate(String s) {
  try {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.parse(p[0]);
    final m = int.parse(p[1]);
    final d = int.parse(p[2]);
    final dt = DateTime(y, m, d);
    if (dt.year != y || dt.month != m || dt.day != d) return null;
    return dt;
  } catch (_) {
    return null;
  }
}

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

String fmtMoney(double v) => '₹${v.toStringAsFixed(2)}';

const categories = [
  'Tablet',
  'Capsule',
  'Syrup',
  'Injection',
  'Ointment',
  'Drops',
  'Other',
];

class Medicine {
  final int? id;
  final String name;
  final String generic;
  final String company;
  final String category;
  final String batch;
  final String expiry; // yyyy-MM-dd
  final double mrp;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int minStock;
  final double gst;
  final String hsn;
  final String barcode;
  final String rack;
  final String supplier;
  final bool rxRequired;
  final bool isSample;

  const Medicine({
    this.id,
    required this.name,
    this.generic = '',
    this.company = '',
    this.category = 'Tablet',
    required this.batch,
    required this.expiry,
    required this.mrp,
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    required this.stock,
    this.minStock = 10,
    this.gst = 12,
    this.hsn = '',
    this.barcode = '',
    this.rack = '',
    this.supplier = '',
    this.rxRequired = false,
    this.isSample = false,
  });

  Medicine copyWith({
    int? id,
    String? name,
    String? generic,
    String? company,
    String? category,
    String? batch,
    String? expiry,
    double? mrp,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? minStock,
    double? gst,
    String? hsn,
    String? barcode,
    String? rack,
    String? supplier,
    bool? rxRequired,
    bool? isSample,
  }) =>
      Medicine(
        id: id ?? this.id,
        name: name ?? this.name,
        generic: generic ?? this.generic,
        company: company ?? this.company,
        category: category ?? this.category,
        batch: batch ?? this.batch,
        expiry: expiry ?? this.expiry,
        mrp: mrp ?? this.mrp,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        stock: stock ?? this.stock,
        minStock: minStock ?? this.minStock,
        gst: gst ?? this.gst,
        hsn: hsn ?? this.hsn,
        barcode: barcode ?? this.barcode,
        rack: rack ?? this.rack,
        supplier: supplier ?? this.supplier,
        rxRequired: rxRequired ?? this.rxRequired,
        isSample: isSample ?? this.isSample,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'generic': generic,
        'company': company,
        'category': category,
        'batch': batch,
        'expiry': expiry,
        'mrp': mrp,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'stock': stock,
        'minStock': minStock,
        'gst': gst,
        'hsn': hsn,
        'barcode': barcode,
        'rack': rack,
        'supplier': supplier,
        'rxRequired': rxRequired ? 1 : 0,
        'isSample': isSample ? 1 : 0,
      };

  factory Medicine.fromMap(Map<String, dynamic> m) => Medicine(
        id: m['id'] as int?,
        name: (m['name'] ?? '') as String,
        generic: (m['generic'] ?? '') as String,
        company: (m['company'] ?? '') as String,
        category: (m['category'] ?? 'Tablet') as String,
        batch: (m['batch'] ?? '') as String,
        expiry: (m['expiry'] ?? '') as String,
        mrp: (m['mrp'] as num? ?? 0).toDouble(),
        purchasePrice: (m['purchasePrice'] as num? ?? 0).toDouble(),
        sellingPrice: (m['sellingPrice'] as num? ?? 0).toDouble(),
        stock: (m['stock'] as num? ?? 0).toInt(),
        minStock: (m['minStock'] as num? ?? 10).toInt(),
        gst: (m['gst'] as num? ?? 12).toDouble(),
        hsn: (m['hsn'] ?? '') as String,
        barcode: (m['barcode'] ?? '') as String,
        rack: (m['rack'] ?? '') as String,
        supplier: (m['supplier'] ?? '') as String,
        rxRequired: (m['rxRequired'] as num? ?? 0) == 1,
        isSample: (m['isSample'] as num? ?? 0) == 1,
      );

  DateTime? get expiryDate => parseDate(expiry);

  ExpiryStatus statusAt(DateTime now) {
    final e = expiryDate;
    if (e == null) return ExpiryStatus.ok;
    return expiryStatus(e, now);
  }

  bool get lowStock => isLowStock(stock, minStock);
  double get value => stockValue(stock, purchasePrice);
}

class Supplier {
  final int? id;
  final String name;
  final String phone;

  const Supplier({this.id, required this.name, this.phone = ''});

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'phone': phone};

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as int?,
        name: (m['name'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
      );
}

class StockMovement {
  final int? id;
  final int medicineId;
  final String medicineName;
  final String type; // 'IN' or 'OUT'
  final int qty;
  final String reason;
  final String date; // ISO yyyy-MM-dd HH:mm

  const StockMovement({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.type,
    required this.qty,
    this.reason = '',
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'type': type,
        'qty': qty,
        'reason': reason,
        'date': date,
      };

  factory StockMovement.fromMap(Map<String, dynamic> m) => StockMovement(
        id: m['id'] as int?,
        medicineId: (m['medicineId'] as num? ?? 0).toInt(),
        medicineName: (m['medicineName'] ?? '') as String,
        type: (m['type'] ?? '') as String,
        qty: (m['qty'] as num? ?? 0).toInt(),
        reason: (m['reason'] ?? '') as String,
        date: (m['date'] ?? '') as String,
      );
}
