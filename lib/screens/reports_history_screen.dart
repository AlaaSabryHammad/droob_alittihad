import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_report.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

class ReportsHistoryScreen extends StatefulWidget {
  const ReportsHistoryScreen({super.key});

  @override
  State<ReportsHistoryScreen> createState() => _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState extends State<ReportsHistoryScreen> {
  List<InspectionReport> _reports = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    final reports = await StorageService.getReports();

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _reports.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds = _reports.map((r) => r.id!).toSet();
      }
    });
  }

  Future<void> _shareSelectedReports() async {
    if (_selectedIds.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final List<XFile> pdfFiles = [];

      for (final id in _selectedIds) {
        final report = _reports.firstWhere((r) => r.id == id);
        final pdfFile = await PdfService.generatePdf(report);
        pdfFiles.add(XFile(pdfFile.path));
      }

      await Share.shareXFiles(
        pdfFiles,
        text: 'تقارير المعاينة - عدد: ${pdfFiles.length}',
      );

      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _deleteSelectedReports() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف ${_selectedIds.length} تقرير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteReports(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? 'تم تحديد ${_selectedIds.length}' : 'التقارير السابقة',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _selectedIds.clear();
                    _isSelectionMode = false;
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedIds.length == _reports.length
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
              ),
              onPressed: _selectAll,
              tooltip: _selectedIds.length == _reports.length ? 'إلغاء تحديد الكل' : 'تحديد الكل',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadReports,
              tooltip: 'تحديث',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            )
          : _reports.isEmpty
              ? _buildEmptyState()
              : _buildReportsList(),
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? _buildSelectionActions()
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد تقارير سابقة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإنشاء تقرير جديد ليظهر هنا',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xFF1A237E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final isSelected = _selectedIds.contains(report.id);

          return GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(report.id!);
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(report.id!);
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A237E).withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Checkbox or Image
                    if (_isSelectionMode)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A237E)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? Icons.check_rounded : Icons.check_box_outline_blank_rounded,
                          color: isSelected ? Colors.white : Colors.grey[400],
                          size: 28,
                        ),
                      )
                    else
                      _buildReportThumbnail(report),
                    const SizedBox(width: 16),
                    // Report Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '# ${report.reportNumber ?? 'بدون رقم'}',
                                  style: const TextStyle(
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                dateFormat.format(report.reportDate),
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.neighborhood ?? 'بدون حي',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category_rounded, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                report.reportType,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              if (report.asphaltQuantity != null) ...[
                                Icon(Icons.square_foot_rounded, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text(
                                  '${report.asphaltQuantity!.toStringAsFixed(1)} M²',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Color(0xFF1A237E)),
                        onPressed: () => _shareReport(report),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportThumbnail(InspectionReport report) {
    final hasImage = report.beforeImage != null || report.afterImage != null;
    final imageFile = report.beforeImage ?? report.afterImage;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: hasImage ? null : const Color(0xFF1A237E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        image: hasImage && imageFile != null
            ? DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? const Icon(Icons.description_rounded, color: Color(0xFF1A237E))
          : null,
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _shareSelectedReports,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_isGenerating ? 'جاري التحضير...' : 'مشاركة (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _deleteSelectedReports,
              icon: const Icon(Icons.delete_rounded),
              label: const Text('حذف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReport(InspectionReport report) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfFile = await PdfService.generatePdf(report);
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'نموذج معاينة - رقم البلاغ: ${report.reportNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}
