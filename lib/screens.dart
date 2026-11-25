// AH MEDICALS — all screens. Owner: Ashifa (shown on Dashboard + About).
import 'package:flutter/material.dart';
import 'db.dart';
import 'models.dart';
import 'scanner.dart';

const shopName = 'AH MEDICALS';
const ownerName = 'Ashifa';

void showMsg(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Color expiryColor(ExpiryStatus s) {
  switch (s) {
    case ExpiryStatus.expired:
      return Colors.red;
    case ExpiryStatus.near30:
      return Colors.deepOrange;
    case ExpiryStatus.near90:
      return Colors.amber.shade800;
    case ExpiryStatus.ok:
      return Colors.green;
  }
}

String expiryLabel(Medicine m, DateTime now) {
  final e = m.expiryDate;
  if (e == null) return 'No expiry';
  final d = daysToExpiry(e, now);
  if (d < 0) return 'EXPIRED ${-d}d ago';
  if (d == 0) return 'Expires TODAY';
  return 'Exp in $d days';
}

List<Medicine> applyFilter(
    List<Medicine> all, String filter, String query, String sort) {
  final now = DateTime.now();
  final q = query.trim().toLowerCase();
  var list = all.where((m) {
    if (q.isNotEmpty) {
      final hay = '${m.name} ${m.generic} ${m.company} ${m.batch} ${m.barcode}'
          .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    switch (filter) {
      case 'Low Stock':
        return m.lowStock;
      case 'Near Expiry':
        final s = m.statusAt(now);
        return s == ExpiryStatus.near30 || s == ExpiryStatus.near90;
      case 'Expired':
        return m.statusAt(now) == ExpiryStatus.expired;
      default:
        return true;
    }
  }).toList();
  if (sort == 'Expiry') {
    list.sort((a, b) => (a.expiryDate ?? DateTime(2100))
        .compareTo(b.expiryDate ?? DateTime(2100)));
  } else {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return list;
}

// ---------------- Dashboard ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Medicine> _meds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppDb.instance.seedIfEmpty();
    final meds = await AppDb.instance.allMedicines();
    if (!mounted) return;
    setState(() {
      _meds = meds;
      _loading = false;
    });
  }

  void _openList(String filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MedicinesScreen(initialFilter: filter)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalValue = _meds.fold<double>(0, (s, m) => s + m.value);
    final low = _meds.where((m) => m.lowStock).length;
    final near = _meds
        .where((m) =>
            m.statusAt(now) == ExpiryStatus.near30 ||
            m.statusAt(now) == ExpiryStatus.near90)
        .length;
    final expired =
        _meds.where((m) => m.statusAt(now) == ExpiryStatus.expired).length;
    final urgent = _meds
        .where((m) =>
            m.lowStock || m.statusAt(now) != ExpiryStatus.ok)
        .toList()
      ..sort((a, b) => (a.expiryDate ?? DateTime(2100))
          .compareTo(b.expiryDate ?? DateTime(2100)));

    return Scaffold(
      appBar: AppBar(title: const Text(shopName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Shop header — owner name
                  Card(
                    color: Colors.teal.shade700,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Owner: $ownerName',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Local inventory • Offline • No login',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard(context, 'Medicines', '${_meds.length}',
                          Icons.medication, Colors.teal, () => _openList('All')),
                      _statCard(
                          context,
                          'Stock Value',
                          fmtMoney(totalValue),
                          Icons.account_balance_wallet,
                          Colors.blue,
                          () => _openList('All')),
                      _statCard(context, 'Low Stock', '$low',
                          Icons.warning_amber, Colors.orange, () => _openList('Low Stock')),
                      _statCard(context, 'Near Expiry', '$near',
                          Icons.schedule, Colors.amber.shade800, () => _openList('Near Expiry')),
                      _statCard(context, 'Expired', '$expired',
                          Icons.dangerous, Colors.red, () => _openList('Expired')),
                      _statCard(
                          context,
                          'Reports',
                          'Value • Lists',
                          Icons.bar_chart,
                          Colors.purple,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportsScreen()))
                              .then((_) => _load())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Needs attention',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (urgent.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('All good — no low stock or expiry alerts.'),
                      ),
                    )
                  else
                    ...urgent
                        .take(8)
                        .map((m) => MedicineTile(
                              medicine: m,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MedicineDetailScreen(medicine: m)),
                              ).then((_) => _load()),
                            )),
                ],
              ),
            ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Medicines list ----------------
class MedicineTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  const MedicineTile({super.key, required this.medicine, this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final st = medicine.statusAt(now);
    final exp = medicine.expiryDate;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: expiryColor(st).withValues(alpha: 0.15),
          child: Icon(Icons.medication,
              color: expiryColor(st)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              medicine.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (medicine.isSample || medicine.rxRequired)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (medicine.isSample)
                      const Chip(
                        label: Text('SAMPLE', style: TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    if (medicine.rxRequired)
                      const Chip(
                        label: Text('Rx', style: TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${medicine.company} • Batch ${medicine.batch}\n'
          'Exp: ${exp == null ? medicine.expiry : fmtDate(exp)}'
          ' • Stock: ${medicine.stock} • MRP ${fmtMoney(medicine.mrp)}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expiryLabel(medicine, now),
              style: TextStyle(
                color: expiryColor(st),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (medicine.lowStock)
              const Text(
                'LOW STOCK',
                style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class MedicinesScreen extends StatefulWidget {
  final String initialFilter;
  const MedicinesScreen({super.key, this.initialFilter = 'All'});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  List<Medicine> _all = [];
  String _filter = 'All';
  String _query = '';
  String _sort = 'Name';
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final meds = await AppDb.instance.allMedicines();
    if (!mounted) return;
    setState(() {
      _all = meds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Low Stock', 'Near Expiry', 'Expired'];
    final shown = applyFilter(_all, _filter, _query, _sort);
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicineFormScreen()),
        ).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name, generic, company, batch, barcode',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final f in filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sort,
                        items: const [
                          DropdownMenuItem(value: 'Name', child: Text('Sort: Name')),
                          DropdownMenuItem(
                              value: 'Expiry', child: Text('Sort: Expiry')),
                        ],
                        onChanged: (v) =>
                            setState(() => _sort = v ?? 'Name'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${shown.length} medicine(s)',
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? const Center(child: Text('No medicines found.'))
                      : ListView.builder(
                          itemCount: shown.length,
                          itemBuilder: (_, i) => MedicineTile(
                            medicine: shown[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MedicineDetailScreen(
                                      medicine: shown[i])),
                            ).then((_) => _load()),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ---------------- Add / Edit medicine ----------------
class MedicineFormScreen extends StatefulWidget {
  final Medicine? existing;
  const MedicineFormScreen({super.key, this.existing});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _generic;
  late final TextEditingController _company;
  late final TextEditingController _batch;
  late final TextEditingController _mrp;
  late final TextEditingController _purchase;
  late final TextEditingController _selling;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;
  late final TextEditingController _hsn;
  late final TextEditingController _barcode;
  late final TextEditingController _rack;
  String _category = 'Tablet';
  double _gst = 12;
  String _supplier = '';
  bool _rx = false;
  DateTime? _expiry;
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _generic = TextEditingController(text: m?.generic ?? '');
    _company = TextEditingController(text: m?.company ?? '');
    _batch = TextEditingController(text: m?.batch ?? '');
    _mrp = TextEditingController(
        text: m == null ? '' : m.mrp.toStringAsFixed(2));
    _purchase = TextEditingController(
        text: m == null ? '' : m.purchasePrice.toStringAsFixed(2));
    _selling = TextEditingController(
        text: m == null ? '' : m.sellingPrice.toStringAsFixed(2));
    _stock = TextEditingController(text: m == null ? '' : '${m.stock}');
    _minStock = TextEditingController(text: m == null ? '10' : '${m.minStock}');
    _hsn = TextEditingController(text: m?.hsn ?? '');
    _barcode = TextEditingController(text: m?.barcode ?? '');
    _rack = TextEditingController(text: m?.rack ?? '');
    _category = m?.category ?? 'Tablet';
    _gst = m?.gst ?? 12;
    _supplier = m?.supplier ?? '';
    _rx = m?.rxRequired ?? false;
    _expiry = m?.expiryDate;
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final s = await AppDb.instance.allSuppliers();
    if (!mounted) return;
    setState(() => _suppliers = s);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _generic,
      _company,
      _batch,
      _mrp,
      _purchase,
      _selling,
      _stock,
      _minStock,
      _hsn,
      _barcode,
      _rack,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code != null && code.isNotEmpty) {
      setState(() => _barcode.text = code);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_expiry == null) {
      showMsg(context, 'Please pick an expiry date.');
      return;
    }
    final dup = await AppDb.instance.duplicateBatch(
        _name.text.trim(), _batch.text.trim(), widget.existing?.id);
    if (dup && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Same batch exists'),
          content: Text(
              'A medicine named "${_name.text.trim()}" with batch "${_batch.text.trim()}" already exists. Save anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save anyway')),
          ],
        ),
      );
      if (ok != true) return;
    }
    final m = Medicine(
      id: widget.existing?.id,
      name: _name.text.trim(),
      generic: _generic.text.trim(),
      company: _company.text.trim(),
      category: _category,
      batch: _batch.text.trim(),
      expiry: _iso(_expiry!),
      mrp: double.tryParse(_mrp.text.trim()) ?? 0,
      purchasePrice: double.tryParse(_purchase.text.trim()) ?? 0,
      sellingPrice: double.tryParse(_selling.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      minStock: int.tryParse(_minStock.text.trim()) ?? 10,
      gst: _gst,
      hsn: _hsn.text.trim(),
      barcode: _barcode.text.trim(),
      rack: _rack.text.trim(),
      supplier: _supplier,
      rxRequired: _rx,
      isSample: widget.existing?.isSample ?? false,
    );
    if (m.id == null) {
      await AppDb.instance.insertMedicine(m);
    } else {
      await AppDb.instance.updateMedicine(m);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    showMsg(context, 'Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit medicine' : 'Add medicine')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Medicine name *', required: true),
            _field(_generic, 'Generic name'),
            _field(_company, 'Manufacturer / Company'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Tablet'),
            ),
            const SizedBox(height: 12),
            _field(_batch, 'Batch no *', required: true),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_expiry == null
                  ? 'Expiry date * — tap to pick'
                  : 'Expiry: ${fmtDate(_expiry!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickExpiry,
            ),
            Row(
              children: [
                Expanded(child: _field(_mrp, 'MRP (₹) *', num: true, required: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_purchase, 'Purchase price (₹)', num: true)),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _field(_selling, 'Selling price (₹)', num: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_stock, 'Stock qty *', num: true, required: true, isInt: true)),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _field(_minStock, 'Min stock level', num: true, isInt: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: _gst,
                    decoration: const InputDecoration(labelText: 'GST %'),
                    items: [0.0, 5.0, 12.0, 18.0]
                        .map((g) => DropdownMenuItem(
                            value: g, child: Text('${g.toInt()}%')))
                        .toList(),
                    onChanged: (v) => setState(() => _gst = v ?? 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_hsn, 'HSN code'),
            Row(
              children: [
                Expanded(child: _field(_barcode, 'Barcode')),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan barcode',
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            _field(_rack, 'Rack / Location (e.g. A1)'),
            DropdownButtonFormField<String>(
              initialValue: _supplier.isEmpty ? null : _supplier,
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: _suppliers
                  .map((s) =>
                      DropdownMenuItem(value: s.name, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _supplier = v ?? ''),
            ),
            SwitchListTile(
              title: const Text('Prescription required (Rx)'),
              value: _rx,
              onChanged: (v) => setState(() => _rx = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? 'Save changes' : 'Add medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool num = false, bool required = false, bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType:
            num ? const TextInputType.numberWithOptions(decimal: true) : null,
        validator: (v) {
          final t = (v ?? '').trim();
          if (required && t.isEmpty) return 'Required';
          if (num && t.isNotEmpty) {
            if (isInt) {
              if (int.tryParse(t) == null || int.parse(t) < 0) {
                return 'Enter a valid number';
              }
            } else if (double.tryParse(t) == null ||
                double.parse(t) < 0) {
              return 'Enter a valid amount';
            }
          }
          return null;
        },
      ),
    );
  }
}

// ---------------- Medicine detail + Stock In/Out ----------------
class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Medicine _med;

  @override
  void initState() {
    super.initState();
    _med = widget.medicine;
  }

  Future<void> _reload() async {
    final all = await AppDb.instance.allMedicines();
    final found = all.where((m) => m.id == _med.id).toList();
    if (!mounted) return;
    if (found.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _med = found.first);
  }

  Future<void> _stockDialog(bool isIn) async {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String reason = isIn ? 'Purchase' : 'Sale';
    String supplier = _med.supplier;
    final suppliers = await AppDb.instance.allSuppliers();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isIn ? 'Stock In' : 'Stock Out'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: (isIn
                          ? ['Purchase', 'Return', 'Correction']
                          : ['Sale', 'Damage', 'Expired', 'Return', 'Other'])
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDlg(() => reason = v ?? reason),
                ),
                if (isIn) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: supplier.isEmpty ? null : supplier,
                    decoration:
                        const InputDecoration(labelText: 'Supplier'),
                    items: suppliers
                        .map((s) => DropdownMenuItem(
                            value: s.name, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setDlg(() => supplier = v ?? ''),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Purchase price (₹) — optional, updates item'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ] else
                  TextField(
                    controller: reasonCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Note (optional)'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (ok != true) return;
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      showMsg(context, 'Enter a quantity above zero.');
      return;
    }
    final expired = _med.statusAt(DateTime.now()) == ExpiryStatus.expired;
    if (!isIn && expired) {
      showMsg(context,
          'This medicine is EXPIRED — it is blocked from sale. Use Damage/Expired stock-out instead of Sale.');
      if (reason == 'Sale') return;
    }
    try {
      final note = reasonCtrl.text.trim();
      final fullReason =
          note.isEmpty ? reason : '$reason — $note';
      await AppDb.instance.addMovement(_med, isIn ? 'IN' : 'OUT', qty, fullReason);
      if (isIn) {
        final newPrice = double.tryParse(priceCtrl.text.trim());
        if (newPrice != null && newPrice > 0) {
          await AppDb.instance.updateMedicine(_med.copyWith(
            purchasePrice: newPrice,
            supplier: supplier,
          ));
        } else if (supplier != _med.supplier) {
          await AppDb.instance
              .updateMedicine(_med.copyWith(supplier: supplier));
        }
      }
      await _reload();
      if (mounted) showMsg(context, isIn ? 'Stock added.' : 'Stock removed.');
    } catch (e) {
      if (mounted) showMsg(context, 'Failed: $e');
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Delete "${_med.name}" (batch ${_med.batch})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.instance.deleteMedicine(_med.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final st = _med.statusAt(now);
    final exp = _med.expiryDate;
    return Scaffold(
      appBar: AppBar(
        title: Text(_med.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MedicineFormScreen(existing: _med)),
            ).then((_) => _reload()),
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (st == ExpiryStatus.expired)
            const Card(
              color: Colors.red,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'EXPIRED — do not sell this medicine.',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_med.lowStock)
            const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'LOW STOCK — reorder soon.',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Generic', _med.generic),
                  _row('Company', _med.company),
                  _row('Category', _med.category),
                  _row('Batch', _med.batch),
                  _row('Expiry',
                      '${exp == null ? _med.expiry : fmtDate(exp)} — ${expiryLabel(_med, now)}'),
                  _row('MRP', fmtMoney(_med.mrp)),
                  _row('Purchase price', fmtMoney(_med.purchasePrice)),
                  _row('Selling price', fmtMoney(_med.sellingPrice)),
                  _row('Stock', '${_med.stock} (min ${_med.minStock})'),
                  _row('Stock value', fmtMoney(_med.value)),
                  _row('GST', '${_med.gst.toInt()}%'),
                  _row('HSN', _med.hsn),
                  _row('Barcode', _med.barcode),
                  _row('Rack', _med.rack),
                  _row('Supplier', _med.supplier),
                  _row('Prescription', _med.rxRequired ? 'Yes (Rx)' : 'No'),
                  if (_med.isSample) _row('Note', 'SAMPLE entry'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Stock In'),
                  onPressed: () => _stockDialog(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.remove),
                  label: const Text('Stock Out'),
                  onPressed: () => _stockDialog(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(
                child: Text(v.isEmpty ? '—' : v,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}

// ---------------- Suppliers ----------------
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AppDb.instance.allSuppliers();
    if (!mounted) return;
    setState(() => _suppliers = s);
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *')),
            TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      if (nameCtrl.text.trim().isEmpty) {
        showMsg(context, 'Supplier name is required.');
        return;
      }
      await AppDb.instance.insertSupplier(Supplier(
          name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim()));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _suppliers.isEmpty
          ? const Center(child: Text('No suppliers yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: _suppliers.length,
              itemBuilder: (_, i) {
                final s = _suppliers[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: Text(s.name),
                    subtitle: Text(s.phone.isEmpty ? 'No phone' : s.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await AppDb.instance.deleteSupplier(s.id!);
                        _load();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- Stock history ----------------
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<StockMovement> _moves = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await AppDb.instance.allMovements();
    if (!mounted) return;
    setState(() => _moves = m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock History')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _moves.isEmpty
            ? const Center(
                child: Text('No stock movements yet.\nStock In / Out from a medicine to see them here.'))
            : ListView.builder(
                itemCount: _moves.length,
                itemBuilder: (_, i) {
                  final mv = _moves[i];
                  final isIn = mv.type == 'IN';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            (isIn ? Colors.green : Colors.red).withValues(alpha: 0.15),
                        child: Icon(isIn ? Icons.add : Icons.remove,
                            color: isIn ? Colors.green : Colors.red),
                      ),
                      title: Text(
                          '${mv.medicineName} — ${isIn ? '+' : '-'}${mv.qty}'),
                      subtitle: Text('${mv.reason} • ${mv.date}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ---------------- Reports ----------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Medicine> _meds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meds = await AppDb.instance.allMedicines();
    if (!mounted) return;
    setState(() => _meds = meds);
  }

  Future<void> _deleteSamples() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all SAMPLE medicines?'),
        content: const Text(
            'This removes every medicine marked SAMPLE. Your own added medicines stay.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete samples',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.instance.deleteAllSamples();
      _load();
      if (mounted) showMsg(context, 'Sample medicines deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalValue = _meds.fold<double>(0, (s, m) => s + m.value);
    final low = _meds.where((m) => m.lowStock).toList();
    final near = _meds
        .where((m) =>
            m.statusAt(now) == ExpiryStatus.near30 ||
            m.statusAt(now) == ExpiryStatus.near90)
        .toList();
    final expired =
        _meds.where((m) => m.statusAt(now) == ExpiryStatus.expired).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stock value summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Total medicines: ${_meds.length}'),
                  Text('Total stock value: ${fmtMoney(totalValue)}'),
                  Text('Low stock items: ${low.length}'),
                  Text('Near expiry (90 days): ${near.length}'),
                  Text('Expired items: ${expired.length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _reportSection('Low stock — reorder', low),
          _reportSection('Near expiry — within 90 days', near),
          _reportSection('Expired — do not sell', expired),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Delete all SAMPLE medicines'),
            onPressed: _deleteSamples,
          ),
        ],
      ),
    );
  }

  Widget _reportSection(String title, List<Medicine> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(12), child: Text('None.'))),
        for (final m in items)
          MedicineTile(
            medicine: m,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MedicineDetailScreen(medicine: m)),
            ).then((_) => _load()),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ---------------- About / Settings ----------------
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(ownerName, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 12),
                  Text('Version 1.0-phase1 (Flutter)'),
                  SizedBox(height: 8),
                  Text('Made by Avi'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
