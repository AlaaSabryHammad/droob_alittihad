import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inspection_report.dart';
import '../services/storage_service.dart';
import 'report_form_screen.dart';
import 'reports_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<InspectionReport> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await StorageService.getReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  // Statistics calculations
  int get totalReports => _reports.length;

  double get totalAsphalt => _reports.fold(0.0, (sum, r) => sum + (r.asphaltQuantity ?? 0));

  int get todayReports => _reports.where((r) =>
    DateUtils.isSameDay(r.reportDate, DateTime.now())).length;

  int get thisWeekReports {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _reports.where((r) => r.reportDate.isAfter(weekStart)).length;
  }

  int get thisMonthReports {
    final now = DateTime.now();
    return _reports.where((r) =>
      r.reportDate.month == now.month && r.reportDate.year == now.year).length;
  }

  Map<String, int> get neighborhoodStats {
    final stats = <String, int>{};
    for (final report in _reports) {
      final neighborhood = report.neighborhood ?? 'غير محدد';
      stats[neighborhood] = (stats[neighborhood] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        color: const Color(0xFF1A237E),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1A237E),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/municipality_logo.png',
                                width: 50,
                                height: 50,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.location_city, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'امانة حفر الباطن',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'ادارة صيانة الطرق',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/dac_logo.png',
                                width: 50,
                                height: 50,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.business, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'مرحباً بك',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'نظام إدارة تقارير صيانة الطرق',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions
                          _buildQuickActions(),
                          const SizedBox(height: 24),

                          // Main Statistics
                          _buildSectionTitle('الإحصائيات الرئيسية'),
                          const SizedBox(height: 12),
                          _buildMainStats(),
                          const SizedBox(height: 24),

                          // Time-based Statistics
                          _buildSectionTitle('إحصائيات زمنية'),
                          const SizedBox(height: 12),
                          _buildTimeStats(),
                          const SizedBox(height: 24),

                          // Recent Reports
                          if (_reports.isNotEmpty) ...[
                            _buildSectionTitle('أحدث التقارير'),
                            const SizedBox(height: 12),
                            _buildRecentReports(),
                            const SizedBox(height: 24),
                          ],

                          // Neighborhood Statistics
                          if (neighborhoodStats.isNotEmpty) ...[
                            _buildSectionTitle('إحصائيات الأحياء'),
                            const SizedBox(height: 12),
                            _buildNeighborhoodStats(),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportFormScreen()),
          );
          _loadReports();
        },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('تقرير جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_circle_rounded,
            label: 'تقرير جديد',
            color: const Color(0xFF1A237E),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportFormScreen()),
              );
              _loadReports();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.list_alt_rounded,
            label: 'جميع التقارير',
            color: const Color(0xFF00897B),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsHistoryScreen()),
              );
              _loadReports();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.description_rounded,
            label: 'إجمالي البلاغات',
            value: totalReports.toString(),
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.square_foot_rounded,
            label: 'كمية الأسفلت',
            value: '${totalAsphalt.toStringAsFixed(1)} M²',
            color: const Color(0xFF00897B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStats() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            label: 'اليوم',
            value: todayReports.toString(),
            icon: Icons.today_rounded,
            color: const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            label: 'هذا الأسبوع',
            value: thisWeekReports.toString(),
            icon: Icons.date_range_rounded,
            color: const Color(0xFF7B1FA2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            label: 'هذا الشهر',
            value: thisMonthReports.toString(),
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF0277BD),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    final recentReports = _reports.take(3).toList();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...recentReports.asMap().entries.map((entry) {
            final report = entry.value;
            final isLast = entry.key == recentReports.length - 1;

            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF1A237E)),
                  ),
                  title: Text(
                    '# ${report.reportNumber ?? 'بدون رقم'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${report.neighborhood ?? 'بدون حي'} • ${dateFormat.format(report.reportDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  trailing: Text(
                    '${report.asphaltQuantity?.toStringAsFixed(1) ?? '0'} M²',
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLast) Divider(height: 1, color: Colors.grey[200]),
              ],
            );
          }),
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsHistoryScreen()),
              );
              _loadReports();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'عرض جميع التقارير',
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF1A237E)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodStats() {
    final sortedStats = neighborhoodStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topNeighborhoods = sortedStats.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: topNeighborhoods.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final percentage = totalReports > 0 ? (item.value / totalReports * 100) : 0.0;
          final colors = [
            const Color(0xFF1A237E),
            const Color(0xFF00897B),
            const Color(0xFFE65100),
            const Color(0xFF7B1FA2),
            const Color(0xFF0277BD),
          ];

          return Padding(
            padding: EdgeInsets.only(bottom: index < topNeighborhoods.length - 1 ? 12 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${item.value} تقرير',
                      style: TextStyle(
                        color: colors[index % colors.length],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: colors[index % colors.length],
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
