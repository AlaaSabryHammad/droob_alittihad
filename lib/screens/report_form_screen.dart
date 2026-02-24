import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/inspection_report.dart';
import '../services/location_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import 'reports_history_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportNumberController = TextEditingController();
  final _asphaltQuantityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  late InspectionReport _report;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _report = InspectionReport();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _report.latitude = position.latitude;
        _report.longitude = position.longitude;
      });
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _selectReportDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _report.reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _report.reportDate) {
      setState(() {
        _report.reportDate = picked;
      });
    }
  }

  Future<void> _selectClosureDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _report.closureDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _report.closureDate) {
      setState(() {
        _report.closureDate = picked;
        _report.dayName = InspectionReport.getArabicDayName(picked.weekday);
      });
    }
  }

  Future<void> _pickImage(bool isBefore) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اختر مصدر الصورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'الكاميرا',
                      color: const Color(0xFF1A237E),
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.camera, isBefore);
                      },
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'المعرض',
                      color: const Color(0xFF00897B),
                      onTap: () {
                        Navigator.pop(context);
                        _getImage(ImageSource.gallery, isBefore);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source, bool isBefore) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (isBefore) {
          _report.beforeImage = File(image.path);
        } else {
          _report.afterImage = File(image.path);
        }
      });
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _report.reportNumber = _reportNumberController.text;
      _report.asphaltQuantity = double.tryParse(_asphaltQuantityController.text);
      _report.neighborhood = _neighborhoodController.text;
      _report.notes = _notesController.text;

      // Save report to storage
      await StorageService.saveReport(_report);

      final pdfFile = await PdfService.generatePdf(_report);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تم إنشاء التقرير بنجاح',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        label: 'مشاركة',
                        color: const Color(0xFF1A237E),
                        onTap: () async {
                          Navigator.pop(context);
                          await Share.shareXFiles(
                            [XFile(pdfFile.path)],
                            text: 'نموذج معاينة - رقم البلاغ: ${_report.reportNumber}',
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.print_rounded,
                        label: 'طباعة',
                        color: const Color(0xFF00897B),
                        onTap: () async {
                          Navigator.pop(context);
                          await Printing.layoutPdf(
                            onLayout: (_) => pdfFile.readAsBytes(),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'معاينة',
                        color: const Color(0xFFE65100),
                        onTap: () async {
                          Navigator.pop(context);
                          await Printing.layoutPdf(
                            onLayout: (_) => pdfFile.readAsBytes(),
                            name: 'inspection_report.pdf',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      );

      // Reset form for new report
      _resetForm();
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
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _report = InspectionReport();
      _reportNumberController.clear();
      _asphaltQuantityController.clear();
      _neighborhoodController.clear();
      _notesController.clear();
    });
    _getLocation();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('نموذج معاينة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsHistoryScreen()),
              );
            },
            tooltip: 'التقارير السابقة',
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _getLocation,
            tooltip: 'تحديث الموقع',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1A237E)),
                  const SizedBox(height: 16),
                  Text('جاري إنشاء التقرير...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 16),

                    // Images Section
                    _buildImagesSection(),
                    const SizedBox(height: 16),

                    // Form Fields Card
                    _buildFormCard(dateFormat),
                    const SizedBox(height: 16),

                    // Location Card
                    _buildLocationCard(),
                    const SizedBox(height: 24),

                    // Generate Button
                    _buildGenerateButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_city, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'امانة حفر الباطن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ادارة صيانة الطرق',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/dac_logo.png',
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.business, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 12),
              const Text(
                'الصور',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildModernImagePicker(label: 'قبل', image: _report.beforeImage, onTap: () => _pickImage(true))),
              const SizedBox(width: 12),
              Expanded(child: _buildModernImagePicker(label: 'بعد', image: _report.afterImage, onTap: () => _pickImage(false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernImagePicker({
    required String label,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: image != null ? null : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: image != null ? Colors.transparent : Colors.grey.shade300,
            width: 2,
            style: image != null ? BorderStyle.none : BorderStyle.solid,
          ),
          image: image != null
              ? DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text('اضغط للإضافة', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormCard(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_document, color: Color(0xFF00897B)),
              ),
              const SizedBox(width: 12),
              const Text(
                'بيانات التقرير',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // رقم البلاغ
          _buildLabeledTextField(
            controller: _reportNumberController,
            label: 'رقم البلاغ',
            hint: 'أدخل رقم البلاغ',
            icon: Icons.tag_rounded,
          ),
          const SizedBox(height: 20),

          // تاريخ البلاغ ونوع البلاغ
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  label: 'تاريخ البلاغ',
                  value: dateFormat.format(_report.reportDate),
                  icon: Icons.calendar_today_rounded,
                  onTap: _selectReportDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledReadOnlyField(
                  label: 'نوع البلاغ',
                  value: _report.reportType,
                  icon: Icons.category_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // كمية الأسفلت والحي
          Row(
            children: [
              Expanded(
                child: _buildLabeledTextField(
                  controller: _asphaltQuantityController,
                  label: 'كمية الأسفلت',
                  hint: 'M²',
                  icon: Icons.square_foot_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledTextField(
                  controller: _neighborhoodController,
                  label: 'الحي',
                  hint: 'اسم الحي',
                  icon: Icons.location_on_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // تاريخ الإقفال واليوم
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  label: 'تاريخ الإقفال',
                  value: dateFormat.format(_report.closureDate),
                  icon: Icons.event_available_rounded,
                  onTap: _selectClosureDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledReadOnlyField(
                  label: 'اليوم',
                  value: _report.dayName,
                  icon: Icons.today_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الملاحظات
          _buildLabeledTextField(
            controller: _notesController,
            label: 'الملاحظات',
            hint: 'أدخل أي ملاحظات إضافية...',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00897B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF00897B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.2)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF00897B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'احداثيات الموقع',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE65100)),
                  onPressed: _getLocation,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateChip(
                  label: 'N',
                  value: _report.latitude?.toStringAsFixed(5) ?? '---',
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCoordinateChip(
                  label: 'E',
                  value: _report.longitude?.toStringAsFixed(6) ?? '---',
                  color: const Color(0xFF00897B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$value°',
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateAndSharePdf,
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
        label: const Text(
          'إنشاء التقرير PDF',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reportNumberController.dispose();
    _asphaltQuantityController.dispose();
    _neighborhoodController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
