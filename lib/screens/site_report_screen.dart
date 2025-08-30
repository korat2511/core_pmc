import 'dart:async';

import 'package:fl_downloader/fl_downloader.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../widgets/custom_button.dart';
import '../models/site_model.dart';
import '../models/category_model.dart';
import '../models/site_user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../core/utils/snackbar_utils.dart';

class SiteReportScreen extends StatefulWidget {
  final SiteModel site;

  const SiteReportScreen({super.key, required this.site});

  @override
  State<SiteReportScreen> createState() => _SiteReportScreenState();
}

class _SiteReportScreenState extends State<SiteReportScreen> {
  String _selectedDuration = 'Today';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  int progress = 0;
  dynamic downloadId;
  String? status;
  late StreamSubscription progressStream;

  // Report sections with sub-parts
  final Map<String, bool> _reportSections = {
    'Progress': true,
    'Category': true,
    'Users': true,
    'Decision': true,
    'Drawing': true,
    'Quotation': true,
    'Selection': true,
    'Work Updates': true,
    'Material': true,
    'Survey': true,
    'Manpower': true,
    'Attachment': true,
  };

  // Expanded sections
  final Set<String> _expandedSections = {};

  // Sub-parts for each section
  final Map<String, List<String>> _subParts = {
    'Progress': ['Pending', 'Active', 'Complete', 'Overdue'],
    'Category': [], // Will be populated from API
    'Users': [], // Will be populated from API
    'Decision': ['PMC', 'Client', 'Architect', 'Vendor', 'Structure', 'Other'],
    'Drawing': ['Architect', 'Structure', 'Other'],
    'Quotation': ['Architect', 'Structure', 'Other'],
    'Selection': ['Architect', 'Client'],
    'Work Updates': [],
    'Material': [],
    'Survey': [],
    'Manpower': [],
    'Attachment': [],
  };

  // Store full objects for ID mapping
  List<CategoryModel> _categories = [];
  List<SiteUserModel> _users = [];

  // Selected sub-parts - initialize with all sub-parts selected
  final Map<String, Set<String>> _selectedSubParts = {};

  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingUsers = false;
  bool _isLoading = false;

  final List<String> _durationOptions = [
    'Today',
    'Yesterday',
    '7 Days',
    '15 Days',
    'Specific Date',
  ];

  @override
  void initState() {
    FlDownloader.initialize();
    progressStream = FlDownloader.progressStream.listen((event) {
      if (event.status == DownloadStatus.successful) {
        debugPrint('event.progress: ${event.progress}');
        setState(() {
          progress = event.progress;
          downloadId = event.downloadId;
          status = event.status.name;
        });
        // This is a way of auto-opening downloaded file right after a download is completed
        FlDownloader.openFile(filePath: event.filePath);
      } else if (event.status == DownloadStatus.running) {
        debugPrint('event.progress: ${event.progress}');
        setState(() {
          progress = event.progress;
          downloadId = event.downloadId;
          status = event.status.name;
        });
      } else if (event.status == DownloadStatus.failed) {
        debugPrint('event: $event');
        setState(() {
          progress = event.progress;
          downloadId = event.downloadId;
          status = event.status.name;
        });
      } else if (event.status == DownloadStatus.paused) {
        debugPrint('Download paused');
        setState(() {
          progress = event.progress;
          downloadId = event.downloadId;
          status = event.status.name;
        });

        Future.delayed(
          const Duration(milliseconds: 250),
          () => FlDownloader.attachDownloadProgress(event.downloadId),
        );
      } else if (event.status == DownloadStatus.pending) {
        debugPrint('Download pending');
        setState(() {
          progress = event.progress;
          downloadId = event.downloadId;
          status = event.status.name;
        });
      }
    });
    super.initState();
    _loadCategoriesAndUsers();
  }

  @override
  void dispose() {
    progressStream.cancel();
    super.dispose();
  }

  Future<void> _loadCategoriesAndUsers() async {
    // Get API token
    final token = await AuthService.currentToken;
    if (token == null) {
      print('No API token available');
      return;
    }

    // Initialize all sub-parts as selected
    _initializeDefaultSelections();

    // Load categories
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await ApiService.getCategoriesBySite(
        apiToken: token,
        siteId: widget.site.id,
      );
      if (categories.status == 1 && categories.categories.isNotEmpty) {
        setState(() {
          _categories = categories.categories;
          _subParts['Category'] = categories.categories
              .map((cat) => cat.name)
              .toList();
          // Select all categories by default
          _selectedSubParts['Category'] = Set<String>.from(
            _subParts['Category']!,
          );
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }

    // Load users
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await ApiService.getUsersBySite(
        apiToken: token,
        siteId: widget.site.id,
      );
      if (users.status == 1 && users.users.isNotEmpty) {
        setState(() {
          _users = users.users;
          _subParts['Users'] = users.users
              .map((user) => user.fullName)
              .toList();
          // Select all users by default
          _selectedSubParts['Users'] = Set<String>.from(_subParts['Users']!);
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  void _initializeDefaultSelections() {
    // Initialize all predefined sub-parts as selected
    _subParts.forEach((section, subPartsList) {
      if (subPartsList.isNotEmpty) {
        _selectedSubParts[section] = Set<String>.from(subPartsList);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: ResponsiveUtils.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration Selection
                Text(
                  'Select duration',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),

                // Duration Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _durationOptions.map((duration) {
                    final isSelected = _selectedDuration == duration;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDuration = duration;
                          _updateDateRange(duration);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              duration,
                              style: AppTypography.bodySmall.copyWith(
                                                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            if (isSelected) ...[
                              SizedBox(width: 8),
                              Icon(Icons.check, color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 16),

                // Date Range Pickers
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'FROM',
                        date: _fromDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDuration = 'Specific Date';
                            _fromDate = date;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker(
                        label: 'TO',
                        date: _toDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDuration = 'Specific Date';
                            _toDate = date;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Report Sections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Parts in the Report',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _areAllSectionsSelected(),
                          onChanged: (value) {
                            setState(() {
                              final newValue = value ?? false;
                              _reportSections.forEach((key, _) {
                                _reportSections[key] = newValue;
                                // Handle sub-parts selection
                                final sectionSubParts = _subParts[key] ?? [];
                                if (sectionSubParts.isNotEmpty) {
                                  if (newValue) {
                                    // Select all sub-parts
                                    _selectedSubParts[key] = Set<String>.from(
                                      sectionSubParts,
                                    );
                                  } else {
                                    // Deselect all sub-parts
                                    _selectedSubParts[key] = <String>{};
                                  }
                                }
                              });
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          'Select All',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Report Sections List
                ..._reportSections.entries.map((entry) {
                  return _buildReportSectionItem(
                    title: entry.key,
                    description: _getSectionDescription(entry.key),
                    isSelected: entry.value,
                    subParts: _subParts[entry.key] ?? [],
                    isExpanded: _expandedSections.contains(entry.key),
                    selectedSubParts:
                        _selectedSubParts[entry.key] ?? <String>{},
                    onChanged: (value) {
                      setState(() {
                        final newValue = value ?? false;
                        _reportSections[entry.key] = newValue;

                        // Handle sub-parts selection
                        final sectionSubParts = _subParts[entry.key] ?? [];
                        if (sectionSubParts.isNotEmpty) {
                          if (newValue) {
                            // Select all sub-parts
                            _selectedSubParts[entry.key] = Set<String>.from(
                              sectionSubParts,
                            );
                          } else {
                            // Deselect all sub-parts
                            _selectedSubParts[entry.key] = <String>{};
                          }
                        }
                      });
                    },
                    onExpanded: (expanded) {
                      setState(() {
                        if (expanded) {
                          _expandedSections.add(entry.key);
                        } else {
                          _expandedSections.remove(entry.key);
                        }
                      });
                    },
                    onSubPartChanged: (subPart, selected) {
                      setState(() {
                        _selectedSubParts.putIfAbsent(
                          entry.key,
                          () => <String>{},
                        );
                        if (selected) {
                          _selectedSubParts[entry.key]!.add(subPart);
                        } else {
                          _selectedSubParts[entry.key]!.remove(subPart);
                        }

                        // Update main checkbox state based on sub-parts
                        final sectionSubParts = _subParts[entry.key] ?? [];
                        if (sectionSubParts.isNotEmpty) {
                          final selectedSubParts =
                              _selectedSubParts[entry.key] ?? <String>{};
                          if (selectedSubParts.length ==
                              sectionSubParts.length) {
                            // All sub-parts selected
                            _reportSections[entry.key] = true;
                          } else if (selectedSubParts.isEmpty) {
                            // No sub-parts selected
                            _reportSections[entry.key] = false;
                          }
                        }
                      });
                    },
                  );
                }),

                SizedBox(height: 50),
              ],
            ),
          ),
          // Generate Report Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: ResponsiveUtils.responsivePadding(context),
              width: double.infinity,
              child: CustomButton(
                text: 'Generate Report',
                onPressed: _isLoading ? null : _generateReport,
                isLoading: _isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (selectedDate != null) {
              onDateSelected(selectedDate);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                                  child: Text(
                  _formatDate(date),
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportSectionItem({
    required String title,
    required String description,
    required bool isSelected,
    required List<String> subParts,
    required bool isExpanded,
    required Set<String> selectedSubParts,
    required ValueChanged<bool?> onChanged,
    required ValueChanged<bool> onExpanded,
    required Function(String, bool) onSubPartChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          // Main row - entire area clickable
          GestureDetector(
            onTap: () {
              if (subParts.isNotEmpty) {
                onExpanded(!isExpanded);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                if (subParts.isNotEmpty) ...[
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                ],
                // Checkbox with separate tap handling
                GestureDetector(
                  onTap: () {
                    onChanged(!isSelected);
                  },
                  child: Checkbox(
                    value: isSelected,
                    onChanged: onChanged,
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sub-parts (expandable)
          if (isExpanded && subParts.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              margin: EdgeInsets.only(left: 16),
              child: Column(
                children: subParts.map((subPart) {
                  final isSubPartSelected = selectedSubParts.contains(subPart);
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subPart,
                            style: AppTypography.bodySmall.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isSubPartSelected,
                          onChanged: (value) =>
                              onSubPartChanged(subPart, value ?? false),
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSectionDescription(String section) {
    switch (section) {
      case 'Progress':
        return 'Includes task progress';
      case 'Category':
        return 'Includes task categories';
      case 'Users':
        return 'Includes assign users';
      case 'Decision':
        return 'Includes all decisions';
      case 'Drawing':
        return 'Includes all drawings';
      case 'Quotation':
        return 'Includes all quotation';
      case 'Selection':
        return 'Includes all selections';
      case 'Work Updates':
        return 'Includes all work updates';
      case 'Material':
        return 'Includes material requirements';
      case 'Survey':
        return 'Includes site survey';
      case 'Manpower':
        return 'Includes all manpower';
      case 'Attachment':
        return 'Includes all attachment';
      default:
        return 'Includes $section data';
    }
  }

  void _updateDateRange(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case 'Today':
        _fromDate = now;
        _toDate = now;
        break;
      case 'Yesterday':
        _fromDate = now.subtract(Duration(days: 1));
        _toDate = now.subtract(Duration(days: 1));
        break;
      case '7 Days':
        _fromDate = now.subtract(Duration(days: 7));
        _toDate = now;
        break;
      case '15 Days':
        _fromDate = now.subtract(Duration(days: 15));
        _toDate = now;
        break;
      case 'Specific Date':
        // Keep current dates for manual selection
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _generateReport() async {
    // Get API token
    final token = await AuthService.currentToken;
    if (token == null) {
      print('No API token available');
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare parameters
      final params = _prepareReportParameters(token);

      // Determine API endpoint based on date range
      final isSameDate =
          _fromDate.year == _toDate.year &&
          _fromDate.month == _toDate.month &&
          _fromDate.day == _toDate.day;

      Map<String, dynamic>? response;

      if (isSameDate) {
        // Daily report
        final dateStr = _formatDateForAPI(_fromDate);
        response = await ApiService.generateDailyReport(
          apiToken: token,
          siteId: widget.site.id,
          date: dateStr,
          categoryId: params['categoryId'] ?? '',
          photos: params['photos'] ?? '',
          material: params['material'] ?? '',
          manpower: params['manpower'] ?? '',
          survey: params['survey'] ?? '',
          userId: params['userId'] ?? '',
          task: params['task'] ?? '',
          decision: params['decision'] ?? '',
          decisionByAgency: params['decisionByAgency'] ?? '',
          drawing: params['drawing'] ?? '',
          drawingByAgency: params['drawingByAgency'] ?? '',
          quotation: params['quotation'] ?? '',
          quotationByAgency: params['quotationByAgency'] ?? '',
          selection: params['selection'] ?? '',
          selectionByAgency: params['selectionByAgency'] ?? '',
          workUpdate: params['workUpdate'] ?? '',
        );
      } else {
        // Weekly report
        final startDateStr = _formatDateForAPI(_fromDate);
        final endDateStr = _formatDateForAPI(_toDate);
        response = await ApiService.generateWeeklyReport(
          apiToken: token,
          siteId: widget.site.id,
          startDate: startDateStr,
          endDate: endDateStr,
          categoryId: params['categoryId'] ?? '',
          photos: params['photos'] ?? '',
          material: params['material'] ?? '',
          manpower: params['manpower'] ?? '',
          survey: params['survey'] ?? '',
          userId: params['userId'] ?? '',
          task: params['task'] ?? '',
          decision: params['decision'] ?? '',
          decisionByAgency: params['decisionByAgency'] ?? '',
          drawing: params['drawing'] ?? '',
          drawingByAgency: params['drawingByAgency'] ?? '',
          quotation: params['quotation'] ?? '',
          quotationByAgency: params['quotationByAgency'] ?? '',
          selection: params['selection'] ?? '',
          selectionByAgency: params['selectionByAgency'] ?? '',
          workUpdate: params['workUpdate'] ?? '',
        );
      }

      if (response != null) {
        final status = response['status'] ?? 0;
        final message = response['message'] ?? 'Report generated successfully';

        if (status == 1) {
          print('Report generated successfully: $message');

          // Handle PDF response
          final pdfUrl = response['pdfurl'];
          final pdfName = response['pdf_name'];

          if (pdfUrl != null && pdfName != null) {
            print('PDF URL: $pdfUrl');
            print('PDF Name: $pdfName');

            // Show success message
            SnackBarUtils.showSuccess(
              context,
              message: 'Report generated successfully! Opening PDF...',
            );

            final permission = await FlDownloader.requestPermission();
            if (permission == StoragePermissionStatus.granted) {
              var success = await FlDownloader.download(
                pdfUrl,
                fileName: "$pdfName.pdf",
              );

              if (success) {
                SnackBarUtils.showSuccess(
                  context,
                  message: 'PDF opened successfully!',
                );
              } else {
                SnackBarUtils.showError(
                  context,
                  message: 'Failed to open PDF. Please try again.',
                );
              }
            }
          } else {
            SnackBarUtils.showError(
              context,
              message: 'Invalid PDF response from server.',
            );
          }
        } else {
          print('Report generation failed: $message');
          SnackBarUtils.showError(context, message: message);
        }
      } else {
        print('Failed to generate report');
        SnackBarUtils.showError(
          context,
          message: 'Failed to generate report. Please try again.',
        );
      }
    } catch (e) {
      print('Error generating report: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, String> _prepareReportParameters(String token) {
    final params = <String, String>{};

    // Category IDs
    final selectedCategories = _selectedSubParts['Category'] ?? <String>{};
    final allCategories = _subParts['Category'] ?? [];

    if (selectedCategories.length == allCategories.length) {
      params['categoryId'] = ''; // All selected
    } else {
      // Map category names to IDs
      final selectedCategoryIds = <String>[];
      for (final categoryName in selectedCategories) {
        final category = _categories.firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => CategoryModel(
            id: 0,
            name: '',
            catSubId: 0,
            siteId: widget.site.id,
            createdAt: '',
            updatedAt: '',
          ),
        );
        if (category.id > 0) {
          selectedCategoryIds.add(category.id.toString());
        }
      }
      params['categoryId'] = selectedCategoryIds.join(',');
    }

    // User IDs
    final selectedUsers = _selectedSubParts['Users'] ?? <String>{};
    final allUsers = _subParts['Users'] ?? [];

    if (selectedUsers.length == allUsers.length) {
      params['userId'] = ''; // All selected
    } else {
      // Map user names to IDs
      final selectedUserIds = <String>[];
      for (final userName in selectedUsers) {
        final user = _users.firstWhere(
          (user) => user.fullName == userName,
          orElse: () => SiteUserModel(
            id: 0,
            firstName: '',
            lastName: '',
            mobile: '',
            email: '',
            userType: 0,
            status: '',
            createdAt: '',
            updatedAt: '',
            siteId: '',
          ),
        );
        if (user.id > 0) {
          selectedUserIds.add(user.id.toString());
        }
      }
      params['userId'] = selectedUserIds.join(',');
    }

    // Task Statuses (Progress)
    final selectedProgress = _selectedSubParts['Progress'] ?? <String>{};
    final allProgress = _subParts['Progress'] ?? [];

    if (selectedProgress.length == allProgress.length) {
      params['task'] = ''; // All selected
    } else {
      params['task'] = selectedProgress.join(',');
    }

    // Work Updates
    params['workUpdate'] = _reportSections['Work Updates'] == true ? '1' : '0';

    // Material
    params['material'] = _reportSections['Material'] == true ? '1' : '0';

    // Manpower
    params['manpower'] = _reportSections['Manpower'] == true ? '1' : '0';

    // Photos (Attachment)
    params['photos'] = _reportSections['Attachment'] == true ? '1' : '0';

    // Survey
    params['survey'] = _reportSections['Survey'] == true ? '1' : '0';

    // Decision
    final selectedDecision = _selectedSubParts['Decision'] ?? <String>{};
    if (selectedDecision.isNotEmpty) {
      params['decision'] = '1';
      if (selectedDecision.length == _subParts['Decision']!.length) {
        params['decisionByAgency'] = ''; // All selected
      } else {
        params['decisionByAgency'] = selectedDecision.join(',');
      }
    } else {
      params['decision'] = '0';
      params['decisionByAgency'] = '';
    }

    // Drawing
    final selectedDrawing = _selectedSubParts['Drawing'] ?? <String>{};
    if (selectedDrawing.isNotEmpty) {
      params['drawing'] = '1';
      if (selectedDrawing.length == _subParts['Drawing']!.length) {
        params['drawingByAgency'] = ''; // All selected
      } else {
        params['drawingByAgency'] = selectedDrawing.join(',');
      }
    } else {
      params['drawing'] = '0';
      params['drawingByAgency'] = '';
    }

    // Quotation
    final selectedQuotation = _selectedSubParts['Quotation'] ?? <String>{};
    if (selectedQuotation.isNotEmpty) {
      params['quotation'] = '1';
      if (selectedQuotation.length == _subParts['Quotation']!.length) {
        params['quotationByAgency'] = ''; // All selected
      } else {
        params['quotationByAgency'] = selectedQuotation.join(',');
      }
    } else {
      params['quotation'] = '0';
      params['quotationByAgency'] = '';
    }

    // Selection
    final selectedSelection = _selectedSubParts['Selection'] ?? <String>{};
    if (selectedSelection.isNotEmpty) {
      params['selection'] = '1';
      if (selectedSelection.length == _subParts['Selection']!.length) {
        params['selectionByAgency'] = ''; // All selected
      } else {
        params['selectionByAgency'] = selectedSelection.join(',');
      }
    } else {
      params['selection'] = '0';
      params['selectionByAgency'] = '';
    }

    return params;
  }

  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _areAllSectionsSelected() {
    return _reportSections.values.every((isSelected) => isSelected);
  }
}
