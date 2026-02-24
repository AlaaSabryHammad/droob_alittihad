import 'dart:io';

class InspectionReport {
  String? id;
  String? reportNumber;
  DateTime reportDate;
  String reportType;
  double? asphaltQuantity;
  DateTime closureDate;
  String? neighborhood;
  String dayName;
  String? notes;
  File? beforeImage;
  File? afterImage;
  String? beforeImagePath;
  String? afterImagePath;
  double? latitude;
  double? longitude;
  DateTime createdAt;

  InspectionReport({
    this.id,
    this.reportNumber,
    DateTime? reportDate,
    this.reportType = 'التشوه البصري',
    this.asphaltQuantity,
    DateTime? closureDate,
    this.neighborhood,
    String? dayName,
    this.notes,
    this.beforeImage,
    this.afterImage,
    this.beforeImagePath,
    this.afterImagePath,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  })  : reportDate = reportDate ?? DateTime.now(),
        closureDate = closureDate ?? DateTime.now(),
        dayName = dayName ?? getArabicDayName(DateTime.now().weekday),
        createdAt = createdAt ?? DateTime.now() {
    id ??= DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String getArabicDayName(int weekday) {
    const days = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return days[weekday] ?? '';
  }

  String get coordinatesString {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(5)}°N, ${longitude!.toStringAsFixed(6)}°E';
    }
    return '';
  }

  String get qrData {
    return 'geo:$latitude,$longitude';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportNumber': reportNumber,
      'reportDate': reportDate.toIso8601String(),
      'reportType': reportType,
      'asphaltQuantity': asphaltQuantity,
      'closureDate': closureDate.toIso8601String(),
      'neighborhood': neighborhood,
      'dayName': dayName,
      'notes': notes,
      'beforeImagePath': beforeImagePath,
      'afterImagePath': afterImagePath,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    return InspectionReport(
      id: json['id'],
      reportNumber: json['reportNumber'],
      reportDate: DateTime.parse(json['reportDate']),
      reportType: json['reportType'] ?? 'التشوه البصري',
      asphaltQuantity: json['asphaltQuantity']?.toDouble(),
      closureDate: DateTime.parse(json['closureDate']),
      neighborhood: json['neighborhood'],
      dayName: json['dayName'],
      notes: json['notes'],
      beforeImagePath: json['beforeImagePath'],
      afterImagePath: json['afterImagePath'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
