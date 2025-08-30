import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final TextEditingController? controller;
  final bool showClearButton;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? iconColor;

  const CustomSearchBar({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.showClearButton = true,
    this.padding,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.iconColor,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    }
  }

  void _clearText() {
    _controller.clear();
    if (mounted) {
      widget.onChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height ?? ResponsiveUtils.responsiveFontSize(
        context,
        mobile: 45,
        tablet: 50,
        desktop: 55,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? ResponsiveUtils.responsiveSpacing(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        border: Border.all(
          color: widget.borderColor ?? AppColors.borderColor,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: widget.textColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 14,
            tablet: 16,
            desktop: 18,
          ),
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: widget.hintColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
          suffixIcon: widget.showClearButton && _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                    size: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                  ),
                  onPressed: _clearText,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
