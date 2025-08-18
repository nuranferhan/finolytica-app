import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool centerTitle;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.centerTitle = true,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        boxShadow: elevation > 0 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation),
          ),
        ] : null,
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        leading: leading ?? (showBackButton ? IconButton(
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: titleColor ?? Theme.of(context).textTheme.titleLarge?.color,
          ),
        ) : null),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: actions,
        iconTheme: IconThemeData(
          color: titleColor ?? Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Gradient App Bar variant
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final List<Color>? gradientColors;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: actions,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}