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
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
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
              child: _currentChartType == ChartType.bar ? _buildBarChart() : _buildPieChart(),
            ),
          ),
      ],
    );
  }

  Widget _buildBarChart() {
    final maxVotes = widget.options.isNotEmpty ? widget.options.map((e) => e.votes).reduce((a, b) => a > b ? a : b) : 1;

    return BarChart(
      BarChartData(
        maxY: maxVotes.toDouble() * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final option = widget.options[group.x.toInt()];
              return BarTooltipItem(
                '${option.text}\n${option.votes} Stimmen',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                if (value.toInt() >= widget.options.length) return const Text('');
                final option = widget.options[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    option.text.length > 10 ? '${option.text.substring(0, 10)}...' : option.text,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxVotes > 10 ? (maxVotes / 5).ceilToDouble() : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 30,
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
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxVotes > 10 ? (maxVotes / 5).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final totalVotes = widget.options.fold<int>(0, (sum, option) => sum + option.votes);

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: widget.options.asMap().entries.map((entry) {
                final option = entry.value;
                final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;

                return PieChartSectionData(
                  color: option.color,
                  value: option.votes.toDouble(),
                  title: '${percentage.round()}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Optional: Handle touch events
                },
              ),
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.options.map((option) {
              final percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.text.length > 15 ? '${option.text.substring(0, 15)}...' : option.text,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${option.votes} (${percentage.round()}%)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
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
