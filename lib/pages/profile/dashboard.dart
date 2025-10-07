import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

// Para executar este código, adicione as seguintes dependências ao seu arquivo `pubspec.yaml`:
//
// dependencies:
//   flutter:
//     sdk: flutter
//   fl_chart: ^0.68.0
//   google_fonts: ^6.2.1
// teste
// Depois, execute `flutter pub get` no terminal.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard de Análise',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF6B7280)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cards de Análise Rápida
              _buildQuickStats(),
              const SizedBox(height: 24),

              // Gráfico de Ganhos x Serviços
              _buildChartCard(
                title: 'Ganhos por Serviço (Últimos 6 meses)',
                chart: const LineChartSample(),
              ),
              const SizedBox(height: 24),

              // Linha com os dois gráficos de barra
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildChartCard(
                      title: 'Serviços Mais Lucrativos',
                      chart: const BarChartSample(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildChartCard(
                      title: 'Trabalhos nos Últimos 30 Dias',
                      chart: const DailyJobsChartSample(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Métricas Detalhadas
              _buildDetailedMetrics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Serviços Realizados',
            value: '45',
            subtitle: 'Últimos 30 dias',
            valueColor: Colors.indigo.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Ganhos Totais',
            value: 'R\$ 2.500,00',
            subtitle: 'Últimos 30 dias',
            valueColor: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      height: 288,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas Detalhadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Taxa Média de Serviço:', 'R\$ 55,55'),
          const Divider(height: 24),
          _buildMetricRow('Serviços Concluídos (Este Mês):', '12'),
          const Divider(height: 24),
          _buildMetricRow('Último Serviço Realizado:', '18/09/2025'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// Gráfico de Linhas: Ganhos por Serviço
class LineChartSample extends StatelessWidget {
  const LineChartSample({super.key});
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5);
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 12);
                switch (value.toInt()) {
                  case 0: return const Text('Abr', style: style);
                  case 1: return const Text('Mai', style: style);
                  case 2: return const Text('Jun', style: style);
                  case 3: return const Text('Jul', style: style);
                  case 4: return const Text('Ago', style: style);
                  case 5: return const Text('Set', style: style);
                  default: return const Text('');
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 3000,
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 1200), FlSpot(1, 1500), FlSpot(2, 1400),
              FlSpot(3, 1800), FlSpot(4, 2100), FlSpot(5, 2500),
            ],
            isCurved: true, color: primaryColor, barWidth: 4, isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }
}

// Gráfico de Barras: Serviços Mais Lucrativos
class BarChartSample extends StatelessWidget {
  const BarChartSample({super.key});
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 1000,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 12);
                 switch (value.toInt()) {
                  case 0: return const Text('Elét', style: style);
                  case 1: return const Text('Hidr', style: style);
                  case 2: return const Text('Pint', style: style);
                  case 3: return const Text('Limp', style: style);
                  case 4: return const Text('Jard', style: style);
                  default: return const Text('');
                }
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 850), _makeGroupData(1, 600), _makeGroupData(2, 450),
          _makeGroupData(3, 300), _makeGroupData(4, 200),
        ],
      ),
    );
  }
  BarChartGroupData _makeGroupData(int x, double y) {
    const Color barColor = Color(0xFF4F46E5);
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y, color: barColor, width: 16,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
    );
  }
}

// NOVO GRÁFICO: Gráfico de Barras: Trabalhos nos Últimos 30 Dias
class DailyJobsChartSample extends StatelessWidget {
  const DailyJobsChartSample({super.key});
  @override
  Widget build(BuildContext context) {
    final List<double> dailyJobsData = [
      1, 2, 0, 3, 1, 4, 2, 1, 3, 0, 2, 2, 4, 1, 3, 2, 0, 1, 1, 2, 3, 5, 2, 1, 0, 2, 3, 1, 2, 1
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 6,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(color: Color(0xFF6B7280), fontSize: 10);
                int day = value.toInt() + 1;
                if (day == 1 || day % 5 == 0) {
                  return Text(day.toString(), style: style);
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyJobsData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailyJobsData[index],
                color: const Color(0xFF10b981), // green-500
                width: 5,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

