import '../models/uom_model.dart';
import 'api_service.dart';

class UOMService {
  // Get all UOMs (default + user's custom units)
  static Future<List<UOMModel>> getAllUOMs() async {
    try {
      final units = await ApiService.getMaterialUnits();
      if (units == null) {
        return [];
      }

      // Sort by category, then by abbreviation
      units.sort((a, b) {
        final categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.abbreviation.compareTo(b.abbreviation);
      });

      return units;
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
      final success = await ApiService.createMaterialUnit(
        abbreviation: abbreviation,
        fullName: fullName,
        category: category,
      );
      return success;
    } catch (e) {
      print('Error adding UOM: $e');
      return false;
    }
  }

  // Delete UOM (only user's custom units)
  static Future<bool> deleteUOM(String uomId) async {
    try {
      final success = await ApiService.deleteMaterialUnit(uomId);
      return success;
    } catch (e) {
      print('Error deleting UOM: $e');
      return false;
    }
  }

  // Get UOMs by category
  static Future<List<UOMModel>> getUOMsByCategory(String category) async {
    try {
      final allUOMs = await getAllUOMs();
      
      // Filter by category
      final filteredUOMs = allUOMs.where((uom) => uom.category == category).toList();
      
      // Sort by abbreviation
      filteredUOMs.sort((a, b) => a.abbreviation.compareTo(b.abbreviation));
      
      return filteredUOMs;
    } catch (e) {
      print('Error getting UOMs by category: $e');
      return [];
    }
  }

  // Populate default UOMs - No longer needed as they're in the database
  // This method is kept for backward compatibility but does nothing
  static Future<void> populateDefaultUOMs() async {
    // Default units are now populated via database migration
    // This method is kept for backward compatibility
    print('Default UOMs are managed via database. No action needed.');
  }
}
