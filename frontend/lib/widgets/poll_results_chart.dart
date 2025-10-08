import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { bar, pie }

class PollResultsChart extends StatefulWidget {
  final List<PollOptionData> options;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const PollResultsChart({
    super.key,
    required this.options,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  State<PollResultsChart> createState() => _PollResultsChartState();
}

class _PollResultsChartState extends State<PollResultsChart> with SingleTickerProviderStateMixin {
  ChartType _currentChartType = ChartType.bar;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(PollResultsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChartType() {
    setState(() {
      _currentChartType = _currentChartType == ChartType.bar ? ChartType.pie : ChartType.bar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = widget.options.fold<int>(0, (sum, option) => sum + option.votes);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (totalVotes == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Chart Controls
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Ergebnisse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              // Chart Type Toggle
              if (widget.isVisible) ...[
                IconButton(
                  onPressed: _toggleChartType,
                  icon: Icon(
                    _currentChartType == ChartType.bar ? Icons.pie_chart : Icons.bar_chart,
                    size: 20,
                  ),
                  tooltip: _currentChartType == ChartType.bar ? 'Kuchendiagramm anzeigen' : 'Balkendiagramm anzeigen',
                ),
              ],
              // Visibility Toggle
              IconButton(
                onPressed: widget.onToggleVisibility,
                icon: Icon(
                  widget.isVisible ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                tooltip: widget.isVisible ? 'Diagramm ausblenden' : 'Diagramm anzeigen',
              ),
            ],
          ),
        ),

        // Chart Content
        if (widget.isVisible)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              // Dynamic height based on chart type and screen size
              height: _currentChartType == ChartType.pie ? (isMobile ? 280 : 320) : (isMobile ? 250 : 300),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _currentChartType == ChartType.bar
                  ? _buildResponsiveBarChart(isMobile)
                  : _buildResponsivePieChart(isMobile),
            ),
          ),
      ],
    );
  }

  Widget _buildResponsiveBarChart(bool isMobile) {
    final maxVotes = widget.options.isNotEmpty ? widget.options.map((e) => e.votes).reduce((a, b) => a > b ? a : b) : 1;
    final optionCount = widget.options.length;

    // Fixed sizing - no more shrinking
    final barWidth = isMobile ? 24.0 : 32.0;
    final fontSize = isMobile ? 10.0 : 11.0;
    final bottomReservedSize = 50.0;

    // Calculate required width for horizontal scrolling
    final minBarSpacing = 20.0;
    final requiredWidth = (optionCount * (barWidth + minBarSpacing)) + 60; // +60 for margins
    final screenWidth = MediaQuery.of(context).size.width - 32; // Account for container margins
    final shouldScroll = requiredWidth > screenWidth;

    final chartWidget = BarChart(
      BarChartData(
        maxY: maxVotes.toDouble() * 1.15,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            tooltipMargin: 8,
            maxContentWidth: isMobile ? 150 : 200,
            fitInsideHorizontally: true, // Keep tooltips inside chart bounds
            fitInsideVertically: true, // Keep tooltips inside chart bounds
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final option = widget.options[group.x.toInt()];
              final totalVotes = widget.options.fold<int>(0, (sum, opt) => sum + opt.votes);
              final percentage = totalVotes > 0 ? (option.votes / totalVotes * 100).round() : 0;
              return BarTooltipItem(
                '${option.text}\n${option.votes} Stimmen ($percentage%)',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= widget.options.length) return const SizedBox();
                final option = widget.options[value.toInt()];

                return Container(
                  width: barWidth + 10, // Fixed width to prevent overlap
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: bottomReservedSize,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxVotes > 10 ? (maxVotes / 4).ceilToDouble() : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                );
              },
              reservedSize: isMobile ? 25 : 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: option.votes.toDouble(),
                color: option.color,
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  colors: [
                    option.color.withOpacity(0.8),
                    option.color,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxVotes > 10 ? (maxVotes / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 0.8,
            );
          },
        ),
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: minBarSpacing,
      ),
    );

    // Wrap in ScrollView if needed
    if (shouldScroll) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // Allow tooltips to overflow
          child: SizedBox(
            width: requiredWidth,
            height: (isMobile ? 250 : 300) - 32,
            child: chartWidget,
          ),
        ),
      );
    }

    return chartWidget;
  }

  Widget _buildResponsivePieChart(bool isMobile) {
    final totalVotes = widget.options.fold<int>(0, (sum, option) => sum + option.votes);
    final hasMoreOptions = widget.options.length > 4;

    // For mobile with many options, use vertical layout
    if (isMobile && hasMoreOptions) {
      return Column(
        children: [
          // Pie Chart on top
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 1,
                centerSpaceRadius: isMobile ? 30 : 40,
                sections: widget.options.asMap().entries.map((entry) {
                  final option = entry.value;
                  final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;

                  return PieChartSectionData(
                    color: option.color,
                    value: option.votes.toDouble(),
                    title: percentage > 5 ? '${percentage.round()}%' : '',
                    radius: isMobile ? 45 : 55,
                    titleStyle: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 1,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Optional: Add haptic feedback or animations
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Legend at bottom
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.options.map((option) {
                  final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: (MediaQuery.of(context).size.width - 80) / 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${option.text.length > 12 ? '${option.text.substring(0, 12)}...' : option.text} (${percentage.round()}%)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    }

    // Default horizontal layout for desktop or few options
    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: isMobile ? 5 : 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 1.5,
              centerSpaceRadius: isMobile ? 35 : 45,
              sections: widget.options.asMap().entries.map((entry) {
                final option = entry.value;
                final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;

                return PieChartSectionData(
                  color: option.color,
                  value: option.votes.toDouble(),
                  title: percentage > 8 ? '${percentage.round()}%' : '',
                  radius: isMobile ? 50 : 60,
                  titleStyle: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                  gradient: RadialGradient(
                    colors: [
                      option.color.withOpacity(0.8),
                      option.color,
                    ],
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Optional: Add interactions
                },
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Legend
        Expanded(
          flex: isMobile ? 4 : 3,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 160 : 200,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.options.map((option) {
                  final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isMobile ? 10 : 12,
                          height: isMobile ? 10 : 12,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: option.color.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.text.length > (isMobile ? 18 : 20)
                                    ? '${option.text.substring(0, isMobile ? 18 : 20)}...'
                                    : option.text,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${option.votes} Stimmen (${percentage.round()}%)',
                                style: TextStyle(
                                  fontSize: isMobile ? 9 : 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PollOptionData {
  final String text;
  final int votes;
  final Color color;

  const PollOptionData({
    required this.text,
    required this.votes,
    required this.color,
  });
}
