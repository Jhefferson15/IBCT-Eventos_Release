import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../editor/domain/models/participant_model.dart';
import 'analytics_stat_card.dart';

class ParticipantsStatusChart extends StatelessWidget {
  final int confirmed;
  final int pending;
  final int total;

  const ParticipantsStatusChart({
    super.key,
    required this.confirmed,
    required this.pending,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];

    if (confirmed > 0) {
      final percent = (confirmed / total * 100).toStringAsFixed(0);
      sections.add(
        PieChartSectionData(
          value: confirmed.toDouble(),
          title: '$percent%',
          color: Colors.green,
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          titlePositionPercentageOffset: 0.55,
        ),
      );
    }

    if (pending > 0) {
      final percent = (pending / total * 100).toStringAsFixed(0);
      sections.add(
        PieChartSectionData(
          value: pending.toDouble(),
          title: '$percent%',
          color: Colors.orange,
          radius: 50,
          titleStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          titlePositionPercentageOffset: 0.55,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 100,
          title: '',
          color: Colors.grey.shade200,
          radius: 50,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Status Geral',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Gap(12),
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: sections.length > 1 ? 2 : 0,
                      centerSpaceRadius: 0,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChartIndicator(
                          color: Colors.green, text: 'Confirmados ($confirmed)'),
                      const Gap(8),
                      ChartIndicator(
                          color: Colors.orange, text: 'Pendentes ($pending)'),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CheckInProgressBar extends StatelessWidget {
  final int checkedIn;
  final int total;

  const CheckInProgressBar({
    super.key,
    required this.checkedIn,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (checkedIn / total * 100) : 0.0;
    final Color progressColor = percentage < 30
        ? Colors.red
        : percentage < 70
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Check-in',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? checkedIn / total : 0,
                minHeight: 8,
                backgroundColor: Colors.grey[100],
                color: progressColor,
              ),
            ),
            const Gap(8),
            Text(
              '$checkedIn de $total participantes presentes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketTypeDistributionChart extends StatelessWidget {
  final List<Participant> participants;

  const TicketTypeDistributionChart({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> ticketDistribution = {};
    for (final participant in participants) {
      final ticketType = participant.ticketType.isEmpty
          ? 'Sem categoria'
          : participant.ticketType;
      ticketDistribution[ticketType] =
          (ticketDistribution[ticketType] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];

    int colorIndex = 0;
    ticketDistribution.forEach((ticketType, count) {
      final percentage = (count / participants.length * 100).toStringAsFixed(0);
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$percentage%',
          color: colors[colorIndex % colors.length],
          radius: 40,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
      colorIndex++;
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
          value: 1, color: Colors.grey.shade200, radius: 40, title: ''));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ingressos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Gap(12),
            Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 0,
                      centerSpaceRadius: 20,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ticketDistribution.entries.take(4).map((entry) {
                      final index = ticketDistribution.keys
                          .toList()
                          .indexOf(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle)),
                            const Gap(6),
                            Expanded(
                                child: Text(entry.key,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis)),
                            Text('(${entry.value})',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CheckInTimelineChart extends StatelessWidget {
  final List<Participant> participants;

  const CheckInTimelineChart({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final Map<int, int> checkInsByHour = {};
    for (final participant in participants) {
      if (participant.isCheckedIn && participant.checkInTime != null) {
        final hour = participant.checkInTime!.hour;
        checkInsByHour[hour] = (checkInsByHour[hour] ?? 0) + 1;
      }
    }

    double maxY = 5;
    if (checkInsByHour.isNotEmpty) {
      maxY = checkInsByHour.values.reduce((a, b) => a > b ? a : b).toDouble();
      maxY = maxY == 0 ? 5 : maxY * 1.2;
    }

    final barGroups = List.generate(24, (index) {
      final count = checkInsByHour[index] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: count > 0 ? AppTheme.primaryRed : Colors.grey.shade200,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Linha do Tempo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Check-ins por hora',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          if (value % 4 == 0) {
                            return Text('${value.toInt()}h',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
