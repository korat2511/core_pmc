import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/uom_model.dart';
import 'auth_service.dart';

class UOMService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'uoms';

  // Get all UOMs (default + user's custom units)
  static Future<List<UOMModel>> getAllUOMs() async {
    try {
      final currentUser = AuthService.currentUser;
      
      // Get all UOMs without complex ordering to avoid index requirements
      final allQuery = await _firestore
          .collection(_collection)
          .get();

      List<UOMModel> allUOMs = allQuery.docs
          .map((doc) => UOMModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Filter and sort in memory
      List<UOMModel> result = [];
      
      // Add default UOMs (userId is null)
      final defaultUOMs = allUOMs.where((uom) => uom.userId == null).toList();
      result.addAll(defaultUOMs);
      
      // Add user's custom UOMs if authenticated
      if (currentUser != null) {
        final userUOMs = allUOMs.where((uom) => uom.userId == currentUser.id.toString()).toList();
        result.addAll(userUOMs);
      }

      // Sort by category, then by abbreviation
      result.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.abbreviation.compareTo(b.abbreviation);
      });

      return result;
    } catch (e) {
      print('Error getting UOMs: $e');
      return [];
    }
  }

  // Add new UOM
  static Future<bool> addUOM({
    required String abbreviation,
    required String fullName,
    required String category,
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      
      if (currentUser == null) {
        return false;
      }

      // Simple check - just try to add it
      final now = DateTime.now();
      final uomData = {
        'abbreviation': abbreviation.trim(),
        'fullName': fullName.trim(),
        'category': category.trim(),
        'userId': currentUser.id.toString(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _firestore.collection(_collection).add(uomData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete UOM (only user's custom units)
  static Future<bool> deleteUOM(String uomId) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return false;
      }

      // Check if UOM belongs to current user
      final doc = await _firestore.collection(_collection).doc(uomId).get();
      if (!doc.exists) {
        print('UOM not found');
        return false;
      }

      final data = doc.data()!;
      if (data['userId'] != currentUser.id.toString()) {
        print('User not authorized to delete this UOM');
        return false;
      }

      await _firestore.collection(_collection).doc(uomId).delete();
      return true;
    } catch (e) {
      print('Error deleting UOM: $e');
      return false;
    }
  }

  // Get UOMs by category
  static Future<List<UOMModel>> getUOMsByCategory(String category) async {
    try {
      final currentUser = AuthService.currentUser;
      
      // Get all UOMs and filter in memory to avoid index requirements
      final allQuery = await _firestore
          .collection(_collection)
          .get();

      List<UOMModel> allUOMs = allQuery.docs
          .map((doc) => UOMModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Filter by category and user
      List<UOMModel> result = [];
      
      // Add default UOMs for category
      final defaultUOMs = allUOMs.where((uom) => 
          uom.category == category && uom.userId == null).toList();
      result.addAll(defaultUOMs);
      
      // Add user's custom UOMs for category
      if (currentUser != null) {
        final userUOMs = allUOMs.where((uom) => 
            uom.category == category && uom.userId == currentUser.id.toString()).toList();
        result.addAll(userUOMs);
      }

      // Sort by abbreviation
      result.sort((a, b) => a.abbreviation.compareTo(b.abbreviation));

      return result;
    } catch (e) {
      print('Error getting UOMs by category: $e');
      return [];
    }
  }

  // Populate default UOMs (run this once to set up default units)
  static Future<void> populateDefaultUOMs() async {
    try {
      print('Starting to populate default UOMs...');
      
      // Check if default UOMs already exist
      final existingQuery = await _firestore
          .collection(_collection)
          .where('userId', isNull: true)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        print('Default UOMs already exist. Skipping population.');
        return;
      }

      // Default UOMs data
      final defaultUOMs = [
        // Number
        {'abbr': 'bags', 'name': 'bags', 'category': 'Number'},
        {'abbr': 'nos', 'name': 'numbers', 'category': 'Number'},
        {'abbr': 'box', 'name': 'box', 'category': 'Number'},
        {'abbr': 'ct', 'name': 'cartridge', 'category': 'Number'},
        {'abbr': 'each', 'name': 'each', 'category': 'Number'},
        {'abbr': 'pk', 'name': 'pack', 'category': 'Number'},
        {'abbr': 'doz', 'name': 'dozen', 'category': 'Number'},
        
        // Length
        {'abbr': 'm', 'name': 'meter', 'category': 'Length'},
        {'abbr': 'mm', 'name': 'millimeter', 'category': 'Length'},
        {'abbr': 'cm', 'name': 'centimeter', 'category': 'Length'},
        {'abbr': 'ft', 'name': 'feet', 'category': 'Length'},
        {'abbr': 'rft', 'name': 'running feet', 'category': 'Length'},
        {'abbr': 'in', 'name': 'inch', 'category': 'Length'},
        {'abbr': 'yd', 'name': 'yard', 'category': 'Length'},
        {'abbr': 'km', 'name': 'kilometer', 'category': 'Length'},
        
        // Area
        {'abbr': 'sqm', 'name': 'square meter', 'category': 'Area'},
        {'abbr': 'sqmm', 'name': 'square millimeter', 'category': 'Area'},
        {'abbr': 'sqcm', 'name': 'square centimeter', 'category': 'Area'},
        {'abbr': 'sqft', 'name': 'square feet', 'category': 'Area'},
        {'abbr': 'sqin', 'name': 'square inch', 'category': 'Area'},
        {'abbr': 'sqyd', 'name': 'square yard', 'category': 'Area'},
        
        // Mass
        {'abbr': 'T', 'name': 'tonne', 'category': 'Mass'},
        {'abbr': 'kg', 'name': 'kilogram', 'category': 'Mass'},
        {'abbr': 'g', 'name': 'gram', 'category': 'Mass'},
        {'abbr': 'mg', 'name': 'milligram', 'category': 'Mass'},
        {'abbr': 'lb', 'name': 'pound', 'category': 'Mass'},
        {'abbr': 'oz', 'name': 'ounce', 'category': 'Mass'},
        
        // Volume
        {'abbr': 'gal', 'name': 'gallon', 'category': 'Volume'},
        {'abbr': 'KL', 'name': 'kiloliter', 'category': 'Volume'},
        {'abbr': 'L', 'name': 'liter', 'category': 'Volume'},
        {'abbr': 'q.', 'name': 'quintal', 'category': 'Volume'},
        {'abbr': 'cum', 'name': 'cubic meter', 'category': 'Volume'},
        {'abbr': 'cucm', 'name': 'cubic centimeter', 'category': 'Volume'},
        {'abbr': 'cft', 'name': 'cubic feet', 'category': 'Volume'},
      ];

      // Add all default UOMs
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final uom in defaultUOMs) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, {
          'abbreviation': uom['abbr'],
          'fullName': uom['name'],
          'category': uom['category'],
          'userId': null, // null for default units
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
      }

      await batch.commit();
      print('Successfully populated ${defaultUOMs.length} default UOMs');
    } catch (e) {
      print('Error populating default UOMs: $e');
    }
  }
}
