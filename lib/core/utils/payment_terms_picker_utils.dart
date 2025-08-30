import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';

class PaymentTermsPickerUtils {
  static const List<String> paymentTerms = [
    'Net 7 days',
    'Net 15 days',
    'Net 30 days',
    'Net 45 days',
    'Net 60 days',
    'Net 90 days',
    'Due on Receipt',
    'Advance Payment',
    '50% Advance, 50% on Delivery',
    '30% Advance, 70% on Delivery',
    'Custom Terms',
  ];

  static Future<String?> showPaymentTermsPicker({
    required BuildContext context,
    String? selectedTerms,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentTermsPickerBottomSheet(
        selectedTerms: selectedTerms,
      ),
    );
  }
}

class PaymentTermsPickerBottomSheet extends StatefulWidget {
  final String? selectedTerms;

  const PaymentTermsPickerBottomSheet({
    super.key,
    this.selectedTerms,
  });

  @override
  State<PaymentTermsPickerBottomSheet> createState() => _PaymentTermsPickerBottomSheetState();
}

class _PaymentTermsPickerBottomSheetState extends State<PaymentTermsPickerBottomSheet> {
  String? _selectedTerms;

  @override
  void initState() {
    super.initState();
    _selectedTerms = widget.selectedTerms;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                  'Select Payment Terms',
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

          // Payment terms list
          Expanded(
            child: ListView.builder(
              itemCount: PaymentTermsPickerUtils.paymentTerms.length,
              itemBuilder: (context, index) {
                final terms = PaymentTermsPickerUtils.paymentTerms[index];
                final isSelected = _selectedTerms == terms;
                
                return ListTile(
                  title: Text(terms),
                  trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedTerms = terms;
                    });
                    Navigator.of(context).pop(terms);
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
