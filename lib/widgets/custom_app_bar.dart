import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button for navigation stack
  withBackButton,

  /// App bar with search functionality
  withSearch,

  /// App bar with profile avatar and actions
  withProfile,

  /// Transparent app bar for overlaying content
  transparent,
}

/// A custom app bar widget for HOA community management app
///
/// Features:
/// - Multiple variants for different contexts
/// - Clean professional styling
/// - Smooth transitions and animations
/// - Platform-aware back button behavior
/// - Optional search integration
/// - Profile avatar support
///
/// Usage:
/// ```dart
/// CustomAppBar(
///   title: 'Dashboard',
///   variant: CustomAppBarVariant.standard,
///   actions: [
///     IconButton(
///       icon: Icon(Icons.settings),
///       onPressed: () {},
///     ),
///   ],
/// )
/// ```
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a custom app bar
  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.onBackPressed,
    this.onSearchPressed,
    this.onProfilePressed,
    this.profileImageUrl,
    this.showElevation = false,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.searchHint = 'Search community...',
    this.leading,
  });

  /// Title text to display
  final String? title;

  /// App bar variant type
  final CustomAppBarVariant variant;

  /// Action buttons to display on the right
  final List<Widget>? actions;

  /// Callback when back button is pressed
  final VoidCallback? onBackPressed;

  /// Callback when search button is pressed
  final VoidCallback? onSearchPressed;

  /// Callback when profile avatar is pressed
  final VoidCallback? onProfilePressed;

  /// Profile image URL for profile variant
  final String? profileImageUrl;

  /// Whether to show elevation shadow
  final bool showElevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom foreground color
  final Color? foregroundColor;

  /// Search hint text
  final String searchHint;

  /// Custom leading widget (overrides back button)
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;

    final effectiveBackgroundColor =
        backgroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? Colors.transparent
            : appBarTheme.backgroundColor ?? colorScheme.surface);

    final effectiveForegroundColor =
        foregroundColor ?? appBarTheme.foregroundColor ?? colorScheme.onSurface;

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: showElevation ? (appBarTheme.elevation ?? 0) : 0,
      centerTitle: centerTitle,
      systemOverlayStyle: _getSystemOverlayStyle(context),
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
      bottom: variant == CustomAppBarVariant.withSearch
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64.0),
              child: _buildSearchBar(context),
            )
          : null,
    );
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isTransparent = variant == CustomAppBarVariant.transparent;

    if (isTransparent) {
      return brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light;
    }

    return brightness == Brightness.light
        ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (variant == CustomAppBarVariant.withBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      );
    }

    if (variant == CustomAppBarVariant.withProfile && profileImageUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onProfilePressed?.call();
          },
          child: CircleAvatar(
            backgroundImage: NetworkImage(profileImageUrl!),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      );
    }

    return null;
  }

  Widget? _buildTitle(BuildContext context) {
    if (title == null) return null;

    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    return Text(
      title!,
      style:
          appBarTheme.titleTextStyle ??
          theme.textTheme.titleLarge?.copyWith(
            color: foregroundColor ?? appBarTheme.foregroundColor,
          ),
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> actionWidgets = [];

    // Add search button for search variant
    if (variant == CustomAppBarVariant.withSearch) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            HapticFeedback.lightImpact();
            onSearchPressed?.call();
          },
          tooltip: 'Search',
        ),
      );
    }

    // Add custom actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    // Add notification indicator for profile variant
    if (variant == CustomAppBarVariant.withProfile) {
      actionWidgets.add(
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/onboarding-flow');
              },
              tooltip: 'Notifications',
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Clear search
            },
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: colorScheme.outline, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: colorScheme.outline, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          // Handle search
        },
      ),
    );
  }
}

/// A sliver version of CustomAppBar for use in CustomScrollView
class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.onBackPressed,
    this.onSearchPressed,
    this.onProfilePressed,
    this.profileImageUrl,
    this.expandedHeight = 200.0,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.flexibleSpace,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final String? profileImageUrl;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final Widget? flexibleSpace;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      flexibleSpace: flexibleSpace,
      leading: _buildLeading(context),
      title: title != null ? Text(title!) : null,
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (variant == CustomAppBarVariant.withBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    }
    return null;
  }
}
