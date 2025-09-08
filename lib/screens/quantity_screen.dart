import 'package:core_pmc/core/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/element_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'stone_quantity_detail_screen.dart';

class QuantityScreen extends StatefulWidget {
  final SiteModel site;

  const QuantityScreen({super.key, required this.site});

  @override
  State<QuantityScreen> createState() => _QuantityScreenState();
}

class _QuantityScreenState extends State<QuantityScreen> {
  List<ElementModel> _elements = [];
  List<ElementModel> _filteredElements = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadElements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadElements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getElementList(
          apiToken: token,
          siteId: widget.site.id,
        );

        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'] ?? [];
          setState(() {
            _elements = data
                .map((json) => ElementModel.fromJson(json))
                .toList();
            _filteredElements = _elements;
          });
        } else {
          SnackBarUtils.showError(context, message: 'Failed to load elements');
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error loading elements: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshElements() async {
    await _loadElements();
  }

  void _filterElements(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredElements = _elements;
        } else {
          _filteredElements = _elements.where((element) {
            return element.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      });
    }
  }

  void _addElement() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside the dialog content
          FocusScope.of(context).unfocus();
        },
        child: AlertDialog(
          title: Text('Add New Element'),
          content: GestureDetector(
            onTap: () {
              // Prevent dialog from closing when tapping inside the content
            },
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Element Name',
                hintText: 'Enter element name (e.g., GROUND FLOOR)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus(); // Close keyboard first
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  FocusScope.of(context).unfocus(); // Close keyboard first
                  Navigator.of(context).pop();
                  _storeElement(name);
                } else {
                  SnackBarUtils.showError(
                    context,
                    message: 'Please enter element name',
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _storeElement(String name) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        SnackBarUtils.showError(
          context,
          message: 'Authentication token not found',
        );
        return;
      }

      final response = await ApiService.storeElement(
        apiToken: token,
        siteId: widget.site.id,
        name: name,
      );

      if (response != null && response['success'] == true) {
        SnackBarUtils.showSuccess(
          context,
          message: 'Element added successfully',
        );
        // Refresh the elements list
        await _loadElements();
      } else {
        SnackBarUtils.showError(
          context,
          message: response?['message'] ?? 'Failed to add element',
        );
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error adding element: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quantity - ${widget.site.name}',
        showDrawer: false,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Search Bar
            SizedBox(height: 8),
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: CustomSearchBar(
                hintText: 'Search elements...',
                onChanged: _filterElements,
                controller: _searchController,
              ),
            ),

            // Elements List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : _filteredElements.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshElements,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        padding: ResponsiveUtils.responsivePadding(context),
                        itemCount: _filteredElements.length,
                        itemBuilder: (context, index) {
                          final element = _filteredElements[index];
                          return _buildElementCard(element);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addElement,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Element'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          Text(
            _searchController.text.isNotEmpty
                ? 'No elements found'
                : 'No elements yet',
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Add your first element to get started',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addElement,
              icon: Icon(Icons.add),
              label: Text('Add Element'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildElementCard(ElementModel element) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();

          NavigationUtils.push(
            context,
            StoneQuantityDetailScreen(element: element, site: widget.site),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Element Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),

              SizedBox(width: 16),

              // Element Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      element.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Element ID: ${element.id}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Created: ${_formatDate(element.createdAt)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
