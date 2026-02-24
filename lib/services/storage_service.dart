import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_report.dart';

class StorageService {
  static const String _reportsKey = 'saved_reports';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveReport(InspectionReport report) async {
    try {
      final prefs = await _getPrefs();
      final reports = await getReports();

      // Save images to app directory
      if (report.beforeImage != null) {
        report.beforeImagePath = await _saveImage(report.beforeImage!, 'before_${report.id}');
      }
      if (report.afterImage != null) {
        report.afterImagePath = await _saveImage(report.afterImage!, 'after_${report.id}');
      }

      // Check if report already exists
      final existingIndex = reports.indexWhere((r) => r.id == report.id);
      if (existingIndex != -1) {
        reports[existingIndex] = report;
      } else {
        reports.insert(0, report);
      }

      final jsonList = reports.map((r) => r.toJson()).toList();
      await prefs.setString(_reportsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving report: $e');
    }
  }

  static Future<List<InspectionReport>> getReports() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_reportsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final reports = <InspectionReport>[];

      for (final json in jsonList) {
        try {
          final report = InspectionReport.fromJson(json);
          // Load images from paths
          if (report.beforeImagePath != null) {
            final file = File(report.beforeImagePath!);
            if (file.existsSync()) {
              report.beforeImage = file;
            }
          }
          if (report.afterImagePath != null) {
            final file = File(report.afterImagePath!);
            if (file.existsSync()) {
              report.afterImage = file;
            }
          }
          reports.add(report);
        } catch (e) {
          print('Error parsing report: $e');
        }
      }

      return reports;
    } catch (e) {
      print('Error getting reports: $e');
      return [];
    }
  }

  static Future<void> deleteReport(String id) async {
    try {
      final prefs = await _getPrefs();
      final reports = await getReports();

      final reportIndex = reports.indexWhere((r) => r.id == id);
      if (reportIndex != -1) {
        final report = reports[reportIndex];

        // Delete images
        if (report.beforeImagePath != null) {
          final file = File(report.beforeImagePath!);
          if (file.existsSync()) {
            await file.delete();
          }
        }
        if (report.afterImagePath != null) {
          final file = File(report.afterImagePath!);
          if (file.existsSync()) {
            await file.delete();
          }
        }

        reports.removeAt(reportIndex);

        final jsonList = reports.map((r) => r.toJson()).toList();
        await prefs.setString(_reportsKey, jsonEncode(jsonList));
      }
    } catch (e) {
      print('Error deleting report: $e');
    }
  }

  static Future<void> deleteReports(List<String> ids) async {
    for (final id in ids) {
      await deleteReport(id);
    }
  }

  static Future<String> _saveImage(File image, String name) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/report_images');
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final extension = image.path.split('.').last;
    final newPath = '${imagesDir.path}/$name.$extension';
    final newFile = await image.copy(newPath);
    return newFile.path;
  }
}
