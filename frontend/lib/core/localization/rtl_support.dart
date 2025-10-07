import 'package:flutter/material.dart';
import 'package:pollino/core/localization/i18n_service.dart';

/// Widget das RTL-Layout basierend auf der aktuellen Sprache anwendet
class RTLDirectionalityWrapper extends StatelessWidget {
  final Widget child;

  const RTLDirectionalityWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: I18nService.instance.textDirection,
      child: child,
    );
  }
}

/// Mixin für RTL-bewusste Widgets
mixin RTLAware {
  /// Gibt die Textrichtung für die aktuelle Sprache zurück
  TextDirection get textDirection => I18nService.instance.textDirection;

  /// Prüft ob die aktuelle Sprache RTL ist
  bool get isRTL => I18nService.instance.isRTL;

  /// Gibt den Edge Insets mit korrekter RTL-Richtung zurück
  EdgeInsets rtlAwareEdgeInsets({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    if (isRTL) {
      return EdgeInsets.only(
        left: right,
        top: top,
        right: left,
        bottom: bottom,
      );
    }
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Gibt die Alignment mit korrekter RTL-Richtung zurück
  Alignment rtlAwareAlignment(Alignment ltrAlignment) {
    if (isRTL) {
      // Spiegle horizontale Alignments für RTL
      if (ltrAlignment == Alignment.centerLeft) {
        return Alignment.centerRight;
      } else if (ltrAlignment == Alignment.centerRight) {
        return Alignment.centerLeft;
      } else if (ltrAlignment == Alignment.topLeft) {
        return Alignment.topRight;
      } else if (ltrAlignment == Alignment.topRight) {
        return Alignment.topLeft;
      } else if (ltrAlignment == Alignment.bottomLeft) {
        return Alignment.bottomRight;
      } else if (ltrAlignment == Alignment.bottomRight) {
        return Alignment.bottomLeft;
      }
    }
    return ltrAlignment;
  }

  /// Cross-Axis Alignment für RTL
  CrossAxisAlignment rtlAwareCrossAxisAlignment(CrossAxisAlignment ltrAlignment) {
    if (isRTL) {
      if (ltrAlignment == CrossAxisAlignment.start) {
        return CrossAxisAlignment.end;
      } else if (ltrAlignment == CrossAxisAlignment.end) {
        return CrossAxisAlignment.start;
      }
    }
    return ltrAlignment;
  }

  /// Main-Axis Alignment für RTL
  MainAxisAlignment rtlAwareMainAxisAlignment(MainAxisAlignment ltrAlignment) {
    if (isRTL) {
      if (ltrAlignment == MainAxisAlignment.start) {
        return MainAxisAlignment.end;
      } else if (ltrAlignment == MainAxisAlignment.end) {
        return MainAxisAlignment.start;
      }
    }
    return ltrAlignment;
  }
}

/// RTL-bewusste Implementierung von Padding
class RTLPadding extends StatelessWidget with RTLAware {
  final EdgeInsets padding;
  final Widget child;

  const RTLPadding({
    Key? key,
    required this.padding,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    EdgeInsets rtlPadding;
    if (isRTL) {
      rtlPadding = EdgeInsets.only(
        left: padding.right,
        top: padding.top,
        right: padding.left,
        bottom: padding.bottom,
      );
    } else {
      rtlPadding = padding;
    }

    return Padding(
      padding: rtlPadding,
      child: child,
    );
  }
}

/// RTL-bewusste Row Implementation
class RTLRow extends StatelessWidget with RTLAware {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const RTLRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: rtlAwareMainAxisAlignment(mainAxisAlignment),
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      children: isRTL ? children.reversed.toList() : children,
    );
  }
}
