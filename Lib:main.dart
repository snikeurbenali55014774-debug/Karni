// main.dart
// تطبيق إدارة الكريدي — نسخة Flutter حقيقية
// فيها فقط: دين + دفعة، رصيد يتحسب تلقائياً، وتاريخ كل المعاملات محفوظ

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const CreditApp());
}

// ---------- Data Models ----------
class Zone {
  final String id;
  final String name;
  final Color color;
  Zone({required this.id, required this.name, required this.color});
}

class Client {
  final String id;
  final String zoneId;
  final String name;
  final String store;
  Client({required this.id, required this.zoneId, required this.name, required this.store});
}

enum TxType { debt, payment }

class Transaction {
  final String id;
  final String clientId;
  final TxType type;
  final double amount;
  final DateTime date;
  final double balanceAfter;
  Transaction({
    required this.id,
    required this.clientId,
    required this.type,
    required this.amount,
    required this.date,
    required this.balanceAfter,
  });
}

// ---------- App Root ----------
class CreditApp extends StatefulWidget {
  const CreditApp({super.key});
  @override
  State<CreditApp> createState() => _CreditAppState();
}

class _CreditAppState extends State<CreditApp> {
  // بيانات تجريبية — لاحقاً تتبدل بقاعدة بيانات SQLite حقيقية
  final List<Zone> zones = [
    Zone(id: "z1", name: "منطقة أ - وسط المدينة", color: const Color(0xFFC1440E)),
    Zone(id: "z2", name: "منطقة ب - صفاقس الشمالية", color: const Color(0xFF1E7145)),
    Zone(id: "z3", name: "منطقة ج - طريق قابس", color: const Color(0xFF1D5B9E)),
  ];

  final List<Client> clients = [
    Client(id: "c1", zoneId: "z1", name: "أحمد بن صالح", store: "بقالة صالح"),
    Client(id: "c2", zoneId: "z1", name: "سليم الطرابلسي", store: "مواد غذائية سليم"),
    Client(id: "c3", zoneId: "z2", name: "كريم الجلاصي", store: "سوبيرات الجلاصي"),
    Client(id: "c4", zoneId: "z2", name: "فاطمة الغربي", store: "مخزن الغربي"),
    Client(id: "c5", zoneId: "z3", name: "وليد المنصوري", store: "ميني ماركي المنصوري"),
  ];

  List<Transaction> transactions = [];

  double balanceOf(String clientId) {
    final list = transactions.where((t) => t.clientId == clientId).toList();
    if (list.isEmpty) return 0;
    return list.last.balanceAfter;
  }

  void addTransaction(String clientId, TxType type, double amount) {
    final current = balanceOf(clientId);
    final newBalance = type == TxType.debt ? current + amount : current - amount;
    setState(() {
      transactions.add(Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientId: clientId,
        type: type,
        amount: amount,
        date: DateTime.now(),
        balanceAfter: newBalance,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة الكريدي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        fontFamily: 'Cairo', // تقدر تبدلها بأي خط عربي واضح
        scaffoldBackgroundColor: const Color(0xFFF4F2ED),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC1440E)),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl, // كل التطبيق من اليمين لليسار
        child: child!,
      ),
      home: DashboardScreen(
        zones: zones,
        clients: clients,
        balanceOf: balanceOf,
        onAddTransaction: addTransaction,
        transactionsOf: (id) => transactions.where((t) => t.clientId == id).toList().reversed.toList(),
      ),
    );
  }
}

// ---------- Dashboard Screen ----------
class DashboardScreen extends StatelessWidget {
  final List<Zone> zones;
  final List<Client> clients;
  final double Function(String) balanceOf;
  final void Function(String, TxType, double) onAddTransaction;
  final List<Transaction> Function(String) transactionsOf;

  const DashboardScreen({
    super.key,
    required this.zones,
    required this.clients,
    required this.balanceOf,
    required this.onAddTransaction,
    required this.transactionsOf,
  });

  String fmt(double n) => "${NumberFormat("#,##0", "en").format(n)} د.ت";

  @override
  Widget build(BuildContext context) {
    final total = clients.fold<double>(0, (sum, c) => sum + balanceOf(c.id));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // شريط علوي مع مجموع الديون
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFF1E2430), width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("إدارة الكريدي", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E2430))),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF1E2430), borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Text("مجموع كل الديون", style: TextStyle(fontSize: 18, color: Color(0xFFB8BEC9))),
                  const SizedBox(height: 8),
                  Text(fmt(total), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("اختر المنطقة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B6558))),
                  ),
                  ...zones.map((z) {
                    final zoneClients = clients.where((c) => c.zoneId == z.id).toList();
                    final zoneBalance = zoneClients.fold<double>(0, (sum, c) => sum + balanceOf(c.id));
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFDAD5C8), width: 2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: z.color.withOpacity(0.15),
                          child: Icon(Icons.location_on, color: z.color),
                        ),
                        title: Text(z.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: Text("${zoneClients.length} حرفاء", style: const TextStyle(fontSize: 15)),
                        trailing: Text(fmt(zoneBalance), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ZoneScreen(
                              zone: z,
                              clients: zoneClients,
                              balanceOf: balanceOf,
                              onAddTransaction: onAddTransaction,
                              transactionsOf: transactionsOf,
                            ),
                          ));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Zone Screen (list of clients) ----------
class ZoneScreen extends StatelessWidget {
  final Zone zone;
  final List<Client> clients;
  final double Function(String) balanceOf;
  final void Function(String, TxType, double) onAddTransaction;
  final List<Transaction> Function(String) transactionsOf;

  const ZoneScreen({
    super.key,
    required this.zone,
    required this.clients,
    required this.balanceOf,
    required this.onAddTransaction,
    required this.transactionsOf,
  });

  String fmt(double n) => "${NumberFormat("#,##0", "en").format(n)} د.ت";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(zone.name), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E2430), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clients.length,
        itemBuilder: (context, i) {
          final c = clients[i];
          final balance = balanceOf(c.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFDAD5C8), width: 2)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(c.store),
              trailing: Text(
                fmt(balance),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: balance > 0 ? const Color(0xFFC1440E) : const Color(0xFF1E7145)),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ClientLedgerScreen(
                    client: c,
                    balance: balanceOf(c.id),
                    transactions: transactionsOf(c.id),
                    onAddTransaction: onAddTransaction,
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------- Client Ledger Screen ----------
class ClientLedgerScreen extends StatefulWidget {
  final Client client;
  final double balance;
  final List<Transaction> transactions;
  final void Function(String, TxType, double) onAddTransaction;

  const ClientLedgerScreen({
    super.key,
    required this.client,
    required this.balance,
    required this.transactions,
    required this.onAddTransaction,
  });

  @override
  State<ClientLedgerScreen> createState() => _ClientLedgerScreenState();
}

class _ClientLedgerScreenState extends State<ClientLedgerScreen> {
  String fmt(double n) => "${NumberFormat("#,##0", "en").format(n.abs())} د.ت";

  void _openAmountSheet(TxType type) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        final isDebt = type == TxType.debt;
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDebt ? "إضافة دين" : "تسجيل دفعة",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDebt ? const Color(0xFFC1440E) : const Color(0xFF1E7145)),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "0",
                  filled: true,
                  fillColor: const Color(0xFFF4F2ED),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDebt ? const Color(0xFFC1440E) : const Color(0xFF1E7145),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount <= 0) return;
                  widget.onAddTransaction(widget.client.id, type, amount);
                  Navigator.pop(context);
                  setState(() {}); // يحدث الشاشة فوراً بالرصيد الجديد
                },
                child: const Text("حفظ", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.client.name), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E2430), elevation: 0),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF1E2430), borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                Text(widget.client.store, style: const TextStyle(fontSize: 16, color: Color(0xFFB8BEC9))),
                const SizedBox(height: 4),
                const Text("الرصيد الحالي", style: TextStyle(fontSize: 16, color: Color(0xFFB8BEC9))),
                const SizedBox(height: 4),
                Text(
                  widget.balance == 0 ? "0 د.ت — لا يوجد دين" : fmt(widget.balance),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: widget.balance > 0 ? const Color(0xFFF0A93D) : const Color(0xFF5BD69C)),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.transactions.isEmpty
                ? const Center(child: Text("لا توجد معاملات بعد", style: TextStyle(fontSize: 16, color: Color(0xFF9B9585))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, i) {
                      final t = widget.transactions[i];
                      final isDebt = t.type == TxType.debt;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(right: BorderSide(color: isDebt ? const Color(0xFFF0A93D) : const Color(0xFF1E7145), width: 6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat("dd/MM/yyyy").format(t.date), style: const TextStyle(fontSize: 13, color: Color(0xFF6B6558))),
                                Text(isDebt ? "دين جديد" : "دفعة", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isDebt ? '+' : '-'}${fmt(t.amount)}",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDebt ? const Color(0xFFC1440E) : const Color(0xFF1E7145)),
                                ),
                                Text("الرصيد بعدها: ${fmt(t.balanceAfter)}", style: const TextStyle(fontSize: 12, color: Color(0xFF9B9585))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFF1E2430), width: 4))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAmountSheet(TxType.payment),
                  icon: const Icon(Icons.remove, color: Colors.white),
                  label: const Text("تسجيل دفعة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E7145), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAmountSheet(TxType.debt),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("إضافة دين", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC1440E), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
