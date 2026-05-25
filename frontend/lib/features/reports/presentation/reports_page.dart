import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kpi_card.dart';
import 'reports_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kHPad = EdgeInsets.symmetric(horizontal: 20);
const _kTabCount = 4;

// Vivid accent palette used across the page
const _kSalesColor = Color(0xFF6C63FF); // purple
const _kFinanceColor = Color(0xFF00C9A7); // teal
const _kInventoryColor = Color(0xFFFF6B6B); // coral
const _kCustomerColor = Color(0xFFFFB347); // amber

// ─── Reports Page ─────────────────────────────────────────────────────────────
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTab = 0;

  static const _tabs = [
    (icon: Icons.receipt_long_rounded, label: 'Sales', color: _kSalesColor),
    (
      icon: Icons.account_balance_rounded,
      label: 'Financial',
      color: _kFinanceColor
    ),
    (icon: Icons.warehouse_rounded, label: 'Inventory', color: _kCustomerColor),
    (icon: Icons.people_rounded, label: 'Customers', color: _kInventoryColor),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabCount, vsync: this)
      ..addListener(() => setState(() => _activeTab = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    for (final p in [
      reportsDailySalesProvider,
      reportsMonthlyProfitProvider,
      reportsTopProductsProvider,
      reportsInventoryProvider,
      reportsCustomerBalancesProvider,
      reportsSupplierBalancesProvider,
      reportsCashFlowProvider,
    ]) {
      ref.invalidate(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _tabs[_activeTab].color;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradientHeader(onRefresh: _refresh, activeColor: activeColor),
          _KPIRow(),
          const SizedBox(height: 16),
          Padding(
            padding: _kHPad,
            child: _ColoredTabBar(
                controller: _tabController, tabs: _tabs, activeTab: _activeTab),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SalesReportTab(),
                _FinancialReportTab(),
                _InventoryReportTab(),
                _CustomerReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────
class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.onRefresh, required this.activeColor});
  final VoidCallback onRefresh;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activeColor, activeColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: activeColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reports',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              Text('Business Overview',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
class _KPIRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitAsync = ref.watch(reportsMonthlyProfitProvider);
    final cashFlowAsync = ref.watch(reportsCashFlowProvider);
    final customersAsync = ref.watch(reportsCustomerBalancesProvider);
    final suppliersAsync = ref.watch(reportsSupplierBalancesProvider);

    final cards = [
      (
        label: 'Revenue',
        icon: Icons.trending_up_rounded,
        color: _kSalesColor,
        value: profitAsync.when(
          data: (d) {
            final m = d['data'] as List? ?? [];
            return m.isNotEmpty ? _fmtAmount(m.last['revenue']) : '0';
          },
          loading: () => '…',
          error: (_, __) => 'N/A',
        ),
      ),
      (
        label: 'Cash',
        icon: Icons.account_balance_wallet_rounded,
        color: _kFinanceColor,
        value: cashFlowAsync.when(
          data: (d) => _fmtAmount(d['data']?['net_flow']),
          loading: () => '…',
          error: (_, __) => 'N/A',
        ),
      ),
      (
        label: 'Receivable',
        icon: Icons.call_received_rounded,
        color: _kCustomerColor,
        value: customersAsync.when(
          data: (d) => _fmtAmount(d['total_receivable']),
          loading: () => '…',
          error: (_, __) => 'N/A',
        ),
      ),
      (
        label: 'Payable',
        icon: Icons.call_made_rounded,
        color: _kInventoryColor,
        value: suppliersAsync.when(
          data: (d) => _fmtAmount(d['total_payable']),
          loading: () => '…',
          error: (_, __) => 'N/A',
        ),
      ),
    ];

    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: _kHPad,
        child: Row(
          children: cards.expand((c) sync* {
            yield Expanded(
                child: _KPITile(
                    label: c.label,
                    value: c.value,
                    icon: c.icon,
                    color: c.color));
            if (c != cards.last) yield const SizedBox(width: 10);
          }).toList(),
        ),
      ),
    );
  }
}

class _KPITile extends StatelessWidget {
  const _KPITile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Colored Tab Bar ──────────────────────────────────────────────────────────
class _ColoredTabBar extends StatelessWidget {
  const _ColoredTabBar(
      {required this.controller, required this.tabs, required this.activeTab});
  final TabController controller;
  final List<({IconData icon, String label, Color color})> tabs;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.asMap().entries.map((e) {
        final isActive = e.key == activeTab;
        final t = e.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.animateTo(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(right: e.key < tabs.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? t.color : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: t.color.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4)
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon,
                      size: 18, color: isActive ? Colors.white : t.color),
                  const SizedBox(height: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : t.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Sales Tab ────────────────────────────────────────────────────────────────
class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(reportsDailySalesProvider);
    final topAsync = ref.watch(reportsTopProductsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Daily Sales', 'Last 30 Days', _kSalesColor,
              Icons.calendar_today_rounded),
          const SizedBox(height: 12),
          salesAsync.when(
            data: (data) {
              final days = data['data'] as List? ?? [];
              if (days.isEmpty)
                return const _EmptyState(message: 'No sales data');
              return _StyledTable(
                accentColor: _kSalesColor,
                columns: const [
                  'Date',
                  'Invoices',
                  'Total Sales',
                  'Cash',
                  'Credit'
                ],
                numericCols: const {1, 2, 3, 4},
                boldCols: const {2},
                rows: days
                    .map((d) => [
                          d['date'] ?? '',
                          '${d['invoice_count']}',
                          _fmtAmount(d['total_sales']),
                          _fmtAmount(d['cash_collected']),
                          _fmtAmount(d['credit_sales']),
                        ])
                    .toList(),
              );
            },
            loading: () => const _LoadingIndicator(color: _kSalesColor),
            error: (e, _) => _ErrorText(e),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
              'Top Products', 'Best Sellers', _kSalesColor, Icons.star_rounded),
          const SizedBox(height: 12),
          topAsync.when(
            data: (data) {
              final products = data['data'] as List? ?? [];
              if (products.isEmpty)
                return const _EmptyState(message: 'No product data');
              return _StyledTable(
                accentColor: _kSalesColor,
                columns: const ['#', 'Product', 'Qty', 'Revenue'],
                numericCols: const {2, 3},
                boldCols: const {3},
                rows: products
                    .asMap()
                    .entries
                    .map((e) => [
                          '${e.key + 1}',
                          e.value['product_name'] ?? '',
                          '${e.value['total_quantity']}',
                          _fmtAmount(e.value['total_revenue']),
                        ])
                    .toList(),
              );
            },
            loading: () => const _LoadingIndicator(color: _kSalesColor),
            error: (e, _) => _ErrorText(e),
          ),
        ],
      ),
    );
  }
}

// ─── Financial Tab ────────────────────────────────────────────────────────────
class _FinancialReportTab extends ConsumerWidget {
  const _FinancialReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitAsync = ref.watch(reportsMonthlyProfitProvider);
    final cashFlowAsync = ref.watch(reportsCashFlowProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Monthly P&L', 'Profit & Loss', _kFinanceColor,
              Icons.show_chart_rounded),
          const SizedBox(height: 12),
          profitAsync.when(
            data: (data) {
              final months = data['data'] as List? ?? [];
              if (months.isEmpty)
                return const _EmptyState(message: 'No profit data');
              return _StyledTable(
                accentColor: _kFinanceColor,
                columns: const [
                  'Month',
                  'Revenue',
                  'COGS',
                  'Gross',
                  'Expenses',
                  'Net',
                  'Margin'
                ],
                numericCols: const {1, 2, 3, 4, 5, 6},
                boldCols: const {3, 5},
                rows: months
                    .map((m) => [
                          m['month'] ?? '',
                          _fmtAmount(m['revenue']),
                          _fmtAmount(m['cogs']),
                          _fmtAmount(m['gross_profit']),
                          _fmtAmount(m['expenses']),
                          _fmtAmount(m['net_profit']),
                          '${m['gross_margin']}%',
                        ])
                    .toList(),
                colorResolver: (col, val) {
                  if (col == 3) return AppColors.success;
                  if (col == 5) return _profitColor(val);
                  return null;
                },
              );
            },
            loading: () => const _LoadingIndicator(color: _kFinanceColor),
            error: (e, _) => _ErrorText(e),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Cash Flow', 'Last 30 Days', _kFinanceColor,
              Icons.waterfall_chart_rounded),
          const SizedBox(height: 12),
          cashFlowAsync.when(
            data: (data) {
              final flowData = data['data'] as Map<String, dynamic>? ?? {};
              final days = flowData['days'] as List? ?? [];
              if (days.isEmpty)
                return const _EmptyState(message: 'No cash flow data');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _FlowBadge('In', flowData['total_in'], AppColors.success),
                    const SizedBox(width: 10),
                    _FlowBadge('Out', flowData['total_out'], _kInventoryColor),
                    const SizedBox(width: 10),
                    _FlowBadge('Net', flowData['net_flow'], _kFinanceColor),
                  ]),
                  const SizedBox(height: 14),
                  _StyledTable(
                    accentColor: _kFinanceColor,
                    columns: const ['Date', 'Cash In', 'Cash Out', 'Net'],
                    numericCols: const {1, 2, 3},
                    boldCols: const {3},
                    rows: days
                        .map((d) => [
                              d['date'] ?? '',
                              _fmtAmount(d['cash_in']),
                              _fmtAmount(d['cash_out']),
                              _fmtAmount(d['net']),
                            ])
                        .toList(),
                    colorResolver: (col, val) {
                      if (col == 1) return AppColors.success;
                      if (col == 2) return _kInventoryColor;
                      if (col == 3) return _profitColor(val);
                      return null;
                    },
                  ),
                ],
              );
            },
            loading: () => const _LoadingIndicator(color: _kFinanceColor),
            error: (e, _) => _ErrorText(e),
          ),
        ],
      ),
    );
  }
}

// ─── Inventory Tab ────────────────────────────────────────────────────────────
class _InventoryReportTab extends ConsumerWidget {
  const _InventoryReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(reportsInventoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Inventory', 'Warehouse Valuation', _kInventoryColor,
              Icons.inventory_2_rounded),
          const SizedBox(height: 12),
          inventoryAsync.when(
            data: (data) {
              final valuation = data['data'] as Map<String, dynamic>? ?? {};
              final warehouses = valuation['warehouses'] as List? ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TotalBanner(
                      value: valuation['grand_total_value'],
                      color: _kInventoryColor),
                  const SizedBox(height: 16),
                  _StyledTable(
                    accentColor: _kInventoryColor,
                    columns: const [
                      'Warehouse',
                      'Products',
                      'Qty',
                      'Value (IQD)'
                    ],
                    numericCols: const {1, 2, 3},
                    boldCols: const {3},
                    rows: warehouses
                        .map((w) => [
                              w['warehouse_name'] ?? '',
                              '${w['product_count']}',
                              '${w['total_quantity']}',
                              _fmtAmount(w['total_value']),
                            ])
                        .toList(),
                  ),
                ],
              );
            },
            loading: () => const _LoadingIndicator(color: _kInventoryColor),
            error: (e, _) => _ErrorText(e),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Tab ─────────────────────────────────────────────────────────────
class _CustomerReportTab extends ConsumerWidget {
  const _CustomerReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(reportsCustomerBalancesProvider);
    final suppliersAsync = ref.watch(reportsSupplierBalancesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Customers', 'Receivables', _kCustomerColor,
              Icons.people_alt_rounded),
          const SizedBox(height: 12),
          customersAsync.when(
            data: (data) {
              final customers = data['data'] as List? ?? [];
              if (customers.isEmpty)
                return const _EmptyState(message: 'No receivables');
              return _StyledTableCustom(
                accentColor: _kCustomerColor,
                columns: const [
                  'Customer',
                  'Balance (IQD)',
                  'Credit Limit',
                  'Status'
                ],
                rows: customers
                    .map((c) => _CustomerRow(
                          name: c['customer_name'] ?? '',
                          balance: _fmtAmount(c['current_balance']),
                          limit: _fmtAmount(c['credit_limit']),
                          overLimit: c['over_limit'] == true,
                        ))
                    .toList(),
              );
            },
            loading: () => const _LoadingIndicator(color: _kCustomerColor),
            error: (e, _) => _ErrorText(e),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Suppliers', 'Payables', _kCustomerColor,
              Icons.local_shipping_rounded),
          const SizedBox(height: 12),
          suppliersAsync.when(
            data: (data) {
              final suppliers = data['data'] as List? ?? [];
              if (suppliers.isEmpty)
                return const _EmptyState(message: 'No payables');
              return _StyledTable(
                accentColor: _kCustomerColor,
                columns: const ['Supplier', 'Balance (IQD)', 'Terms (days)'],
                numericCols: const {1, 2},
                boldCols: const {1},
                rows: suppliers
                    .map((s) => [
                          s['supplier_name'] ?? '',
                          _fmtAmount(s['current_balance']),
                          '${s['payment_terms']}',
                        ])
                    .toList(),
              );
            },
            loading: () => const _LoadingIndicator(color: _kCustomerColor),
            error: (e, _) => _ErrorText(e),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.subtitle, this.color, this.icon);
  final String title, subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
      ]),
    ]);
  }
}

class _FlowBadge extends StatelessWidget {
  const _FlowBadge(this.label, this.value, this.color);
  final String label;
  final dynamic value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text('${_fmtAmount(value)} IQD',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.value, required this.color});
  final dynamic value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.inventory_2_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Inventory Value',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          Text('${_fmtAmount(value)} IQD',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ]),
      ]),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: color, strokeWidth: 3),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            Icon(Icons.inbox_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ]),
        ),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.error);
  final Object error;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kInventoryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kInventoryColor.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, color: _kInventoryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Error: $error',
                  style:
                      const TextStyle(color: _kInventoryColor, fontSize: 13))),
        ]),
      );
}

// ─── Styled Table (generic) ───────────────────────────────────────────────────
class _StyledTable extends StatelessWidget {
  const _StyledTable({
    required this.accentColor,
    required this.columns,
    required this.rows,
    this.numericCols = const {},
    this.boldCols = const {},
    this.colorResolver,
  });

  final Color accentColor;
  final List<String> columns;
  final List<List<dynamic>> rows;
  final Set<int> numericCols;
  final Set<int> boldCols;
  final Color? Function(int col, String val)? colorResolver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(accentColor.withOpacity(0.08)),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected))
                return accentColor.withOpacity(0.05);
              return null;
            }),
            dividerThickness: 0.5,
            columns: columns
                .asMap()
                .entries
                .map((e) => DataColumn(
                      label: Text(e.value,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: accentColor)),
                      numeric: numericCols.contains(e.key),
                    ))
                .toList(),
            rows: rows
                .map((row) => DataRow(
                      cells: row.asMap().entries.map((e) {
                        final str = e.value?.toString() ?? '';
                        final color = colorResolver?.call(e.key, str);
                        return DataCell(Text(str,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: boldCols.contains(e.key)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: color ?? const Color(0xFF333333),
                            )));
                      }).toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Customers Table (custom — has status badge) ──────────────────────────────
class _CustomerRow {
  const _CustomerRow(
      {required this.name,
      required this.balance,
      required this.limit,
      required this.overLimit});
  final String name, balance, limit;
  final bool overLimit;
}

class _StyledTableCustom extends StatelessWidget {
  const _StyledTableCustom(
      {required this.accentColor, required this.columns, required this.rows});
  final Color accentColor;
  final List<String> columns;
  final List<_CustomerRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(accentColor.withOpacity(0.08)),
            dividerThickness: 0.5,
            columns: columns
                .map((c) => DataColumn(
                      label: Text(c,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: accentColor)),
                    ))
                .toList(),
            rows: rows
                .map((r) => DataRow(cells: [
                      DataCell(Text(r.name,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF333333)))),
                      DataCell(Text(r.balance,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333)))),
                      DataCell(Text(r.limit,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF666666)))),
                      DataCell(_StatusChip(overLimit: r.overLimit)),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.overLimit});
  final bool overLimit;

  @override
  Widget build(BuildContext context) {
    final color = overLimit ? _kInventoryColor : _kFinanceColor;
    final label = overLimit ? '⚠ Over Limit' : '✓ OK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
double _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _formatNum(double n) {
  if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
  if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(0)}K';
  return n.toStringAsFixed(0);
}

String _fmtAmount(dynamic v) => _formatNum(_parseNum(v));

Color _profitColor(dynamic v) =>
    _parseNum(v) >= 0 ? AppColors.success : _kInventoryColor;
