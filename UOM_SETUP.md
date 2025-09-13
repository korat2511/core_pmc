# UOM (Unit of Measurement) System Setup

## Overview
The UOM system now uses Firebase to store and manage units of measurement. Users can view default units and add their own custom units.

## Features

### 1. Default Units
- Pre-populated with common units across categories:
  - **Number**: bags, nos, box, ct, each, pk, doz
  - **Length**: m, mm, cm, ft, rft, in, yd, km
  - **Area**: sqm, sqmm, sqcm, sqft, sqin, sqyd
  - **Mass**: T, kg, g, mg, lb, oz
  - **Volume**: gal, KL, L, q., cum, cucm, cft

### 2. Custom Units
- Users can add their own units via the "+" button
- **All user-added units automatically go to "Your Units" category**
- **"Your Units" is user-specific** - each user sees only their own custom units
- **No category selection needed** - simplified add dialog with just abbreviation and full name

### 3. Firebase Structure
```json
{
  "uoms": {
    "unitId": {
      "abbreviation": "kg",
      "fullName": "kilogram",
      "category": "Mass",
      "userId": null, // null for default units, userId for custom units
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

## Setup Instructions

### 1. Firebase Rules
Add these rules to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /uoms/{document} {
      allow read, write: if true;
    }
  }
}
```

### 2. Automatic Population
The system automatically populates default UOMs on first load. No manual setup required.

### 3. Usage
1. Open "Add New Material" screen
2. Tap on "Select UOM" field
3. Choose from existing units or tap "+" to add new unit
4. **Add New Unit Dialog**: Only requires abbreviation and full name (no category selection)
5. **Custom units automatically appear in "Your Units" category**
6. **"Your Units" shows only your custom units** (user-specific)

## Files Created/Modified

### New Files:
- `lib/models/uom_model.dart` - UOM data model
- `lib/services/uom_service.dart` - Firebase service for UOM operations
- `lib/scripts/populate_default_uoms.dart` - Script to populate default UOMs

### Modified Files:
- `lib/screens/add_material_screen.dart` - Updated to use Firebase UOMs

## API Methods

### UOMService Methods:
- `getAllUOMs()` - Get all UOMs (default + user's custom)
- `addUOM(abbreviation, fullName, category)` - Add new UOM
- `deleteUOM(uomId)` - Delete user's custom UOM
- `getUOMsByCategory(category)` - Get UOMs by category
- `populateDefaultUOMs()` - Populate default UOMs (auto-called)

## Testing
1. Run the app
2. Navigate to "Add New Material"
3. Tap "Select UOM" - should show default units
4. Tap "+" button to add custom unit
5. Verify custom unit appears in "Your Units" category
6. Test search functionality

## Notes
- Default UOMs are populated automatically on first load
- Custom units are user-specific and isolated
- The system maintains the same UI design as before
- All existing functionality is preserved
