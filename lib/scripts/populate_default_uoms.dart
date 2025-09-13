import 'package:cloud_firestore/cloud_firestore.dart';

// Script to populate Firebase with default UOMs
// Run this once to set up the default units

class DefaultUOMsPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'uoms';

  static final List<Map<String, String>> _defaultUOMs = [
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

      // Add all default UOMs
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final uom in _defaultUOMs) {
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
      print('Successfully populated ${_defaultUOMs.length} default UOMs');
    } catch (e) {
      print('Error populating default UOMs: $e');
    }
  }
}

// Uncomment the line below and run this file to populate default UOMs
// void main() async {
//   await DefaultUOMsPopulator.populateDefaultUOMs();
// }
