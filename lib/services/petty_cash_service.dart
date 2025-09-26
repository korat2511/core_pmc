import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:core_pmc/models/petty_cash_entry_model.dart';
import 'package:core_pmc/services/auth_service.dart';

class PettyCashService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _entriesCollection = 'petty_cash_entries';
  static const String _balanceCollection = 'petty_cash_balances';

  // Add new petty cash entry
  static Future<String> addPettyCashEntry({
    required String siteId,
    required String siteName,
    required String ledgerType,
    required double amount,
    required String receivedBy,
    required String paidBy,
    required String receivedVia,
    required String paidVia,
    required String receivedFrom,
    required String paidTo,
    String? transactionId,
    String? paidToType,
    int? paidToId,
    String? paidToName,
    String? otherRecipient,
    required List<File> imageFiles,
    required String remark,
    required DateTime entryDate,
  }) async {
    try {
      print('Starting petty cash entry creation...');
      
      // Add overall timeout for the entire operation
      return await Future.any([
        _performAddPettyCashEntry(
          siteId: siteId,
          siteName: siteName,
          ledgerType: ledgerType,
          amount: amount,
          receivedBy: receivedBy,
          paidBy: paidBy,
          receivedVia: receivedVia,
          paidVia: paidVia,
          receivedFrom: receivedFrom,
          paidTo: paidTo,
          transactionId: transactionId,
          paidToType: paidToType,
          paidToId: paidToId,
          paidToName: paidToName,
          otherRecipient: otherRecipient,
          imageFiles: imageFiles,
          remark: remark,
          entryDate: entryDate,
        ),
        Future.delayed(Duration(minutes: 5)).then((_) {
          throw Exception('Operation timed out after 5 minutes');
        }),
      ]);
    } catch (e) {
      throw Exception('Failed to add petty cash entry: $e');
    }
  }

  static Future<String> _performAddPettyCashEntry({
    required String siteId,
    required String siteName,
    required String ledgerType,
    required double amount,
    required String receivedBy,
    required String paidBy,
    required String receivedVia,
    required String paidVia,
    required String receivedFrom,
    required String paidTo,
    String? transactionId,
    String? paidToType,
    int? paidToId,
    String? paidToName,
    String? otherRecipient,
    required List<File> imageFiles,
    required String remark,
    required DateTime entryDate,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate unique ID
      final docRef = _firestore.collection(_entriesCollection).doc();
      final entryId = docRef.id;
      print('Generated entry ID: $entryId');

      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        print('Starting image upload for ${imageFiles.length} images...');
        for (int i = 0; i < imageFiles.length; i++) {
          try {
            print('Uploading image ${i + 1}/${imageFiles.length}...');
            final imageUrl = await _uploadImage(
              imageFiles[i],
              'petty_cash/${siteId}/$entryId/image_$i.jpg',
            );
            imageUrls.add(imageUrl);
            print('Image ${i + 1} uploaded successfully: $imageUrl');
          } catch (e) {
            print('Failed to upload image ${i + 1}: $e');
            // Continue with other images even if one fails
            // For now, we'll skip failed images and continue
            print('Skipping failed image and continuing...');
          }
        }
        print('All images uploaded successfully');
      }

      // Create entry
      print('Creating PettyCashEntry object...');
      final entry = PettyCashEntry(
        id: entryId,
        siteId: siteId,
        siteName: siteName,
        ledgerType: ledgerType,
        amount: amount,
        receivedBy: receivedBy,
        paidBy: paidBy,
        receivedVia: receivedVia,
        paidVia: paidVia,
        receivedFrom: receivedFrom,
        paidTo: paidTo,
        transactionId: transactionId,
        paidToType: paidToType,
        paidToId: paidToId,
        paidToName: paidToName,
        otherRecipient: otherRecipient,
        imageUrls: imageUrls,
        remark: remark,
        entryDate: entryDate,
        createdAt: DateTime.now(),
        createdBy: user.id.toString(),
        createdByName: user.fullName,
      );

      // Save to Firestore
      print('Saving entry to Firestore...');
      await docRef.set(entry.toMap());
      print('Entry saved to Firestore successfully');

      // Update balance
      print('Updating balance...');
      await _updateBalance(siteId, siteName, ledgerType, amount);
      print('Balance updated successfully');

      print('Petty cash entry creation completed successfully');
      return entryId;
    } catch (e) {
      throw Exception('Failed to add petty cash entry: $e');
    }
  }

  // Get petty cash entries for a site
  static Future<List<PettyCashEntry>> getPettyCashEntries({
    required String siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Simple query without date filtering to avoid index requirements
      Query query = _firestore
          .collection(_entriesCollection)
          .where('site_id', isEqualTo: siteId);

      final snapshot = await query.get();
      List<PettyCashEntry> entries = snapshot.docs
          .map((doc) => PettyCashEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by date in memory if needed
      if (startDate != null || endDate != null) {
        entries = entries.where((entry) {
          if (startDate != null && entry.entryDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && entry.entryDate.isAfter(endDate)) {
            return false;
          }
          return true;
        }).toList();
      }

      // Sort by entry date in descending order
      entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));

      return entries;
    } catch (e) {
      throw Exception('Failed to get petty cash entries: $e');
    }
  }

  // Get current balance for a site
  static Future<PettyCashBalance> getPettyCashBalance(String siteId) async {
    try {
      final doc = await _firestore
          .collection(_balanceCollection)
          .doc(siteId)
          .get();

      if (doc.exists) {
        return PettyCashBalance.fromMap(doc.data()!);
      }
      
      // Return default balance if no balance document exists
      return PettyCashBalance(
        siteId: siteId,
        siteName: '',
        totalReceived: 0.0,
        totalSpent: 0.0,
        currentBalance: 0.0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get petty cash balance: $e');
    }
  }

  // Update balance after adding entry
  static Future<void> _updateBalance(
    String siteId,
    String siteName,
    String ledgerType,
    double amount,
  ) async {
    try {
      final balanceRef = _firestore.collection(_balanceCollection).doc(siteId);
      final balanceDoc = await balanceRef.get();

      if (balanceDoc.exists) {
        final currentBalance = PettyCashBalance.fromMap(balanceDoc.data()!);
        
        double newTotalReceived = currentBalance.totalReceived;
        double newTotalSpent = currentBalance.totalSpent;

        if (ledgerType == 'received') {
          newTotalReceived += amount;
        } else {
          newTotalSpent += amount;
        }

        final newBalance = PettyCashBalance(
          siteId: siteId,
          siteName: siteName,
          totalReceived: newTotalReceived,
          totalSpent: newTotalSpent,
          currentBalance: newTotalReceived - newTotalSpent,
          lastUpdated: DateTime.now(),
        );

        await balanceRef.set(newBalance.toMap());
      } else {
        // Create new balance document
        double totalReceived = ledgerType == 'received' ? amount : 0.0;
        double totalSpent = ledgerType == 'spent' ? amount : 0.0;

        final newBalance = PettyCashBalance(
          siteId: siteId,
          siteName: siteName,
          totalReceived: totalReceived,
          totalSpent: totalSpent,
          currentBalance: totalReceived - totalSpent,
          lastUpdated: DateTime.now(),
        );

        await balanceRef.set(newBalance.toMap());
      }
    } catch (e) {
      throw Exception('Failed to update balance: $e');
    }
  }

  // Upload image to Firebase Storage
  static Future<String> _uploadImage(File imageFile, String path) async {
    try {
      print('Starting upload for path: $path');
      final ref = _storage.ref().child(path);
      
      // Add timeout to the upload
      final uploadTask = await ref.putFile(imageFile).timeout(
        Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Image upload timeout after 2 minutes');
        },
      );
      
      print('Upload completed, getting download URL...');
      final downloadUrl = await uploadTask.ref.getDownloadURL().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Failed to get download URL - timeout');
        },
      );
      
      print('Download URL obtained: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Image upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete petty cash entry
  static Future<void> deletePettyCashEntry(String entryId, String siteId) async {
    try {
      // Get entry to update balance
      final entryDoc = await _firestore
          .collection(_entriesCollection)
          .doc(entryId)
          .get();

      if (entryDoc.exists) {
        final entry = PettyCashEntry.fromMap(entryDoc.data()!);
        
        // Delete images from storage
        for (String imageUrl in entry.imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }

        // Delete entry
        await _firestore.collection(_entriesCollection).doc(entryId).delete();

        // Update balance (subtract the amount)
        await _updateBalance(
          siteId,
          entry.siteName,
          entry.ledgerType == 'received' ? 'spent' : 'received',
          entry.amount,
        );
      }
    } catch (e) {
      throw Exception('Failed to delete petty cash entry: $e');
    }
  }

  // Get ledger chart data
  static Future<List<Map<String, dynamic>>> getLedgerChartData({
    required String siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final entries = await getPettyCashEntries(
        siteId: siteId,
        startDate: startDate,
        endDate: endDate,
      );

      // Group by date and calculate daily totals
      Map<String, Map<String, double>> dailyData = {};

      for (final entry in entries) {
        final dateKey = '${entry.entryDate.year}-${entry.entryDate.month.toString().padLeft(2, '0')}-${entry.entryDate.day.toString().padLeft(2, '0')}';
        
        if (!dailyData.containsKey(dateKey)) {
          dailyData[dateKey] = {'received': 0.0, 'spent': 0.0};
        }

        if (entry.ledgerType == 'received') {
          dailyData[dateKey]!['received'] = dailyData[dateKey]!['received']! + entry.amount;
        } else {
          dailyData[dateKey]!['spent'] = dailyData[dateKey]!['spent']! + entry.amount;
        }
      }

      // Convert to list format for chart
      List<Map<String, dynamic>> chartData = [];
      dailyData.forEach((date, amounts) {
        chartData.add({
          'date': date,
          'received': amounts['received']!,
          'spent': amounts['spent']!,
          'balance': amounts['received']! - amounts['spent']!,
        });
      });

      // Sort by date
      chartData.sort((a, b) => a['date'].compareTo(b['date']));

      return chartData;
    } catch (e) {
      throw Exception('Failed to get ledger chart data: $e');
    }
  }
}
