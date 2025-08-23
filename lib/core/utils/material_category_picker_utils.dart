import 'package:flutter/material.dart';
import '../../models/material_category_model.dart';
import '../../services/api_service.dart';
import 'snackbar_utils.dart';

class MaterialCategoryPickerUtils {
  static Future<MaterialCategoryModel?> showMaterialCategoryPicker({
    required BuildContext context,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load categories
      final response = await ApiService.getMaterialCategories(page: 1);

      // Close loading dialog
      Navigator.pop(context);

      if (response == null || response.status != 1) {
        SnackBarUtils.showError(
          context,
          message: 'Failed to load material categories',
        );
        return null;
      }

      if (response.data.isEmpty) {
        SnackBarUtils.showInfo(
          context,
          message: 'No material categories available',
        );
        return null;
      }

      // Show the modal and return selected category
      final selectedCategory = await showModalBottomSheet<MaterialCategoryModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) => GestureDetector(
          onTap: () {
            // Close keyboard and modal when tapping outside
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
                              child: DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  minChildSize: 0.4,
                  maxChildSize: 0.7,
                builder: (context, scrollController) => _MaterialCategoryPickerModal(
                  categories: response.data,
                ),
              ),
            ),
          ),
        ),
      );

      return selectedCategory;
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      SnackBarUtils.showError(
        context,
        message: 'Error loading material categories: ${e.toString()}',
      );
      return null;
    }
  }
}

class _MaterialCategoryPickerModal extends StatefulWidget {
  final List<MaterialCategoryModel> categories;

  const _MaterialCategoryPickerModal({
    required this.categories,
  });

  @override
  State<_MaterialCategoryPickerModal> createState() => _MaterialCategoryPickerModalState();
}

class _MaterialCategoryPickerModalState extends State<_MaterialCategoryPickerModal> {
  final _searchController = TextEditingController();
  List<MaterialCategoryModel> _filteredCategories = [];
  bool _isLoading = false;
  bool _showAddForm = false;
  final _addCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addCategoryController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where((category) => 
                category.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _addNewCategory() async {
    if (_addCategoryController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, message: 'Please enter category name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.storeMaterialCategory(
        name: _addCategoryController.text.trim(),
      );

      if (response != null && response.status == 1) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Category added successfully',
        );
        
        // Return the newly created category
        Navigator.of(context).pop(response.data);
      } else {
        SnackBarUtils.showError(
          context,
          message: 'Failed to add category',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        message: 'Error adding category: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Material Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            if (!_showAddForm) ...[
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _filterCategories,
                ),
              ),
              SizedBox(height: 16),

              // Add Category Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddForm = true;
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add New Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ] else ...[
              // Add Category Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                      controller: _addCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Enter category name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addNewCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading 
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text('Add Category'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showAddForm = false;
                                _addCategoryController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Categories List
            Expanded(
              child: _filteredCategories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        return ListTile(
                          title: Text(category.name),
                          subtitle: Text('ID: ${category.id}'),
                          onTap: () => Navigator.of(context).pop(category),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
