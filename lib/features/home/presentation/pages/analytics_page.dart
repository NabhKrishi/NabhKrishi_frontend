import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/farm_model.dart';
import '../../../../services/firestore_service.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  final bool isHindi;
  const AnalyticsPage({super.key, required this.isHindi});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String? _selectedFarmId;
  int _selectedFilterDays = 7; // 7, 30, or 0 (All)
  List<FarmModel> _farms = [];
  List<Map<String, dynamic>> _predictions = [];
  bool _loadingFarms = true;
  bool _loadingPredictions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _loadingFarms = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loadingFarms = false;
          _errorMessage = widget.isHindi ? 'कृपया पहले साइन इन करें।' : 'Please sign in first.';
        });
        return;
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      final farmsList = await firestoreService.getUserFarms(user.uid);

      setState(() {
        _farms = farmsList;
        _loadingFarms = false;
        if (farmsList.isNotEmpty) {
          _selectedFarmId = farmsList.first.farmId;
          _loadPredictionHistory();
        }
      });
    } catch (e) {
      setState(() {
        _loadingFarms = false;
        _errorMessage = widget.isHindi ? 'खेत लोड करने में विफल: $e' : 'Failed to load farms: $e';
      });
    }
  }

  Future<void> _loadPredictionHistory() async {
    if (_selectedFarmId == null) return;

    setState(() {
      _loadingPredictions = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestoreService = ref.read(firestoreServiceProvider);
      final predictionsList = await firestoreService.getPredictionHistory(
        user.uid,
        _selectedFarmId!,
        daysLimit: _selectedFilterDays > 0 ? _selectedFilterDays : null,
      );

      setState(() {
        _predictions = predictionsList;
        _loadingPredictions = false;
      });
    } catch (e) {
      setState(() {
        _loadingPredictions = false;
        _errorMessage = widget.isHindi ? 'पूर्वानुमान इतिहास लोड करने में विफल: $e' : 'Failed to load predictions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFarms) {
      return const Scaffold(
        backgroundColor: Color(0xFF031A22),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CE6B6)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF031A22),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_farms.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF031A22),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                Text(
                  widget.isHindi
                      ? "कोई विश्लेषिकी डेटा उपलब्ध नहीं है।\nट्रेंड देखने के लिए पहले होम स्क्रीन पर एक खेत सहेजें।"
                      : "No analytics data available yet.\nSave a farm on the home screen first to see your trends.",
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF031A22),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPredictionHistory,
          color: const Color(0xFF6CE6B6),
          backgroundColor: const Color(0xFF0C2A34),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // Farm Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2A34),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFarmId,
                    dropdownColor: const Color(0xFF0C2A34),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6CE6B6)),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    items: _farms.map((farm) {
                      final areaStr = farm.farmArea != null ? ' (${farm.farmArea!.toStringAsFixed(1)} ha)' : '';
                      return DropdownMenuItem<String>(
                        value: farm.farmId,
                        child: Text(
                          '${widget.isHindi ? "खेत" : "Farm"} ${farm.latitude.toStringAsFixed(3)}, ${farm.longitude.toStringAsFixed(3)}$areaStr',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFarmId = val;
                        });
                        _loadPredictionHistory();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Controls: 7 Days | 30 Days | All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [7, 30, 0].map((days) {
                  final selected = _selectedFilterDays == days;
                  String label = '';
                  if (days == 7) label = widget.isHindi ? '7 दिन' : '7 Days';
                  if (days == 30) label = widget.isHindi ? '30 दिन' : '30 Days';
                  if (days == 0) label = widget.isHindi ? 'सभी' : 'All';

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterDays = days;
                          });
                          _loadPredictionHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF6CE6B6) : const Color(0xFF0C2A34),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFF6CE6B6) : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                color: selected ? const Color(0xFF031A22) : Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              if (_loadingPredictions)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CE6B6)),
                    ),
                  ),
                )
              else if (_predictions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.show_chart_rounded, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          widget.isHindi
                              ? "इस समय अवधि के लिए कोई इतिहास नहीं है।\nसिफारिशें देखने के लिए पहले कुछ पूर्वानुमान लगाएं।"
                              : "No history found for this time period.\nMake a few predictions first to see recommendations.",
                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Summary Block
                _buildSummaryGrid(),

                const SizedBox(height: 24),

                // Charts
                _buildChartCard(
                  title: widget.isHindi ? 'सिंचाई की सिफारिश' : 'Irrigation Recommendation',
                  subtitle: widget.isHindi ? 'दैनिक जल आवश्यकता (मिमी)' : 'Daily water application target (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['irrigationAmount'] as double),
                  color: const Color(0xFF6CE6B6),
                ),

                const SizedBox(height: 20),

                _buildChartCard(
                  title: widget.isHindi ? 'वर्षा इतिहास' : 'Rainfall History',
                  subtitle: widget.isHindi ? 'पिछले 7 दिनों में वर्षा (मिमी)' : 'Rain accumulated in past 7 days (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['rainfall'] as double),
                  color: const Color(0xFF2CA9C9),
                ),

                const SizedBox(height: 20),

                _buildChartCard(
                  title: widget.isHindi ? 'तापमान का स्तर' : 'Temperature Levels',
                  subtitle: widget.isHindi ? 'दैनिक औसत तापमान (°C)' : 'Daily mean temperature (°C)',
                  unit: '°C',
                  spots: _generateSpots((data) => data['temperature'] as double),
                  color: const Color(0xFFFFB300),
                ),

                const SizedBox(height: 20),

                _buildChartCard(
                  title: widget.isHindi ? 'जल की कमी' : 'Water Deficit',
                  subtitle: widget.isHindi ? 'संभावित जल रिक्तीकरण (मिमी)' : 'Potential soil water depletion (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['deficit'] as double),
                  color: const Color(0xFFE57373),
                ),

                const SizedBox(height: 40),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    double totalIrrigation = 0;
    double maxTemp = -99;
    double avgDeficit = 0;
    double avgHumidity = 0;

    for (final p in _predictions) {
      totalIrrigation += p['irrigationAmount'] as double;
      final temp = p['temperature'] as double;
      if (temp > maxTemp) maxTemp = temp;
      avgDeficit += p['deficit'] as double;
      avgHumidity += p['humidity'] as double;
    }

    avgDeficit /= _predictions.length;
    avgHumidity /= _predictions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isHindi ? 'अवधि सारांश' : 'Period Summary',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem(
                label: widget.isHindi ? 'कुल सिंचाई' : 'Total Irrigation',
                val: '${totalIrrigation.toStringAsFixed(1)} mm',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF6CE6B6),
              ),
              _buildSummaryItem(
                label: widget.isHindi ? 'अधिकतम तापमान' : 'Peak Temp',
                val: '${maxTemp.toStringAsFixed(1)} °C',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFFFB300),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem(
                label: widget.isHindi ? 'औसत कमी' : 'Avg Deficit',
                val: '${avgDeficit.toStringAsFixed(1)} mm',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFFE57373),
              ),
              _buildSummaryItem(
                label: widget.isHindi ? 'औसत आर्द्रता' : 'Avg Humidity',
                val: '${avgHumidity.toStringAsFixed(0)}%',
                icon: Icons.cloud_queue_rounded,
                color: const Color(0xFF2CA9C9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String val,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(double Function(Map<String, dynamic>) getValue) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _predictions.length; i++) {
      spots.add(FlSpot(i.toDouble(), getValue(_predictions[i])));
    }
    return spots;
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String unit,
    required List<FlSpot> spots,
    required Color color,
  }) {
    // Generate dates list for labelling X-axis
    final List<String> dates = _predictions.map((p) {
      final dateObj = p['date'];
      if (dateObj is Timestamp) {
        final dt = dateObj.toDate();
        return '${dt.day}/${dt.month}';
      }
      return '';
    }).toList();

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (val) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                  getDrawingVerticalLine: (val) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toStringAsFixed(0)}$unit',
                          style: GoogleFonts.poppins(color: Colors.white24, fontSize: 8.5),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < dates.length) {
                          // Show max 4 dates on bottom axis to avoid overlap
                          final interval = (dates.length / 4).ceil();
                          if (idx == 0 || idx == dates.length - 1 || idx % interval == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                dates[idx],
                                style: GoogleFonts.poppins(color: Colors.white24, fontSize: 8.5),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 10,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeColor: const Color(0xFF0C2A34),
                        strokeWidth: 1,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
