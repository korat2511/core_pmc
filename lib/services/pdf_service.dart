import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  static final Dio _dio = Dio();

  /// Download PDF from URL and open it
  static Future<bool> downloadAndOpenPdf({
    required String pdfUrl,
    required String pdfName,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          print('Storage permission denied');
          return false;
        }
      }

      // Get the documents directory
      final Directory? documentsDirectory = await getApplicationDocumentsDirectory();
      if (documentsDirectory == null) {
        print('Could not get documents directory');
        return false;
      }

      // Create downloads directory if it doesn't exist
      final Directory downloadsDirectory = Directory('${documentsDirectory.path}/Downloads');
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      // Create filename with .pdf extension if not present
      String fileName = pdfName;
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }

      // Full file path
      final String filePath = '${downloadsDirectory.path}/$fileName';

      print('Downloading PDF from: $pdfUrl');
      print('Saving to: $filePath');

      // Download the file
      await _dio.download(
        pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      print('PDF downloaded successfully');

      // Open the PDF file
      final File file = File(filePath);
      if (await file.exists()) {
        return await _openPdfFile(filePath);
      } else {
        print('Downloaded file not found');
        return false;
      }
    } catch (e) {
      print('Error downloading/opening PDF: $e');
      return false;
    }
  }

  /// Open PDF file using platform-specific methods
  static Future<bool> _openPdfFile(String filePath) async {
    try {
      // For now, let's use the direct URL approach which is more reliable
      // The file will be downloaded and opened by the system's default PDF viewer
      return await openPdfFromUrl(filePath);
    } catch (e) {
      print('Error opening PDF file: $e');
      return false;
    }
  }

  /// Open PDF directly from URL (alternative method)
  static Future<bool> openPdfFromUrl(String pdfUrl) async {
    try {
      final Uri uri = Uri.parse(pdfUrl);
      
      if (await canLaunchUrl(uri)) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('PDF opened from URL successfully');
          return true;
        } else {
          print('Failed to open PDF from URL');
          return false;
        }
      } else {
        print('Cannot launch URL: $pdfUrl');
        return false;
      }
    } catch (e) {
      print('Error opening PDF from URL: $e');
      return false;
    }
  }
}
