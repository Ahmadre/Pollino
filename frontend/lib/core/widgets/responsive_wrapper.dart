import 'package:flutter/material.dart';
import 'package:pollino/core/utils/responsive_helper.dart';

/// Responsive Layout Wrapper für optimale Desktop-UX
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool centerContent;
  final EdgeInsets? padding;
  final CrossAxisAlignment alignment;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.centerContent = true,
    this.padding,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getScreenPadding(context);

    return Container(
      width: double.infinity,
      padding: responsivePadding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth,
                ),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth,
              ),
              child: child,
            ),
    );
  }
}

/// Responsive Container für spezifische Content-Typen
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final ResponsiveContainerType type;
  final EdgeInsets? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    required this.type,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = _getMaxWidthForType(type);

    return ResponsiveWrapper(
      maxWidth: maxWidth,
      centerContent: centerContent,
      padding: padding,
      child: child,
    );
  }

  double _getMaxWidthForType(ResponsiveContainerType type) {
    switch (type) {
      case ResponsiveContainerType.content:
        return ResponsiveHelper.maxContentWidth;
      case ResponsiveContainerType.reading:
        return ResponsiveHelper.maxReadingWidth;
      case ResponsiveContainerType.form:
        return ResponsiveHelper.maxFormWidth;
      case ResponsiveContainerType.card:
        return ResponsiveHelper.maxCardWidth;
    }
  }
}

/// Grid Wrapper für responsive Spalten-Layouts
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? forceColumns;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.forceColumns,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = forceColumns ?? ResponsiveHelper.getGridColumns(context);
    final responsivePadding = padding ?? ResponsiveHelper.getScreenPadding(context);

    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: Einfache Liste
      return Padding(
        padding: responsivePadding,
        child: Column(
          children: children
              .map((child) => Padding(
                    padding: EdgeInsets.only(bottom: runSpacing),
                    child: child,
                  ))
              .toList(),
        ),
      );
    }

    // Desktop/Tablet: Einfaches Grid Layout
    return Padding(
      padding: responsivePadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cardWidth = (availableWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            alignment: WrapAlignment.start,
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              return SizedBox(
                width: cardWidth,
                child: child,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/// Two Column Layout für Desktop
class ResponsiveTwoColumn extends StatelessWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double leftFlex;
  final double rightFlex;
  final double spacing;
  final EdgeInsets? padding;

  const ResponsiveTwoColumn({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.leftFlex = 1.618, // Goldener Schnitt
    this.rightFlex = 1.0,
    this.spacing = 32.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveHelper.getScreenPadding(context);

    if (ResponsiveHelper.isMobile(context) || ResponsiveHelper.isTablet(context)) {
      // Mobile/Tablet: Vertikales Layout
      return Padding(
        padding: responsivePadding,
        child: Column(
          children: [
            leftChild,
            SizedBox(height: spacing),
            rightChild,
          ],
        ),
      );
    }

    // Desktop: Horizontales Layout
    return ResponsiveWrapper(
      padding: responsivePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: leftFlex.round(),
            child: leftChild,
          ),
          SizedBox(width: spacing),
          Expanded(
            flex: rightFlex.round(),
            child: rightChild,
          ),
        ],
      ),
    );
  }
}

/// Responsive Chart Container mit fester Desktop-Größe
class ResponsiveChartContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? chartHeight;

  const ResponsiveChartContainer({
    super.key,
    required this.child,
    this.padding,
    this.chartHeight = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: chartHeight,
      padding: padding,
      child: child,
    );
  }
}

/// Container-Type Enum
enum ResponsiveContainerType {
  content, // 1200px - Hauptinhalt
  reading, // 800px - Optimale Lesbreite
  form, // 600px - Formulare
  card, // 400px - Cards
}
