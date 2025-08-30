import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';

class StatePickerUtils {
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep',
    'Puducherry',
    'Andaman and Nicobar Islands',
  ];

  static Future<String?> showStatePicker({
    required BuildContext context,
    String? selectedState,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatePickerBottomSheet(
        selectedState: selectedState,
      ),
    );
  }
}

class StatePickerBottomSheet extends StatefulWidget {
  final String? selectedState;

  const StatePickerBottomSheet({
    super.key,
    this.selectedState,
  });

  @override
  State<StatePickerBottomSheet> createState() => _StatePickerBottomSheetState();
}

class _StatePickerBottomSheetState extends State<StatePickerBottomSheet> {
  String? _selectedState;
  List<String> _filteredStates = StatePickerUtils.indianStates;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.selectedState;
  }

  void _filterStates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStates = StatePickerUtils.indianStates;
      } else {
        _filteredStates = StatePickerUtils.indianStates
            .where((state) =>
                state.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select State',
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: _filterStates,
              decoration: InputDecoration(
                hintText: 'Search states...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),

          SizedBox(height: 16),

          // States list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStates.length,
              itemBuilder: (context, index) {
                final state = _filteredStates[index];
                final isSelected = _selectedState == state;
                
                return ListTile(
                  title: Text(state),
                  trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedState = state;
                    });
                    Navigator.of(context).pop(state);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
