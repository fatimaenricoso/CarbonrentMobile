import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductGraphScreen extends StatefulWidget {
  final String goodsName;

  const ProductGraphScreen({Key? key, required this.goodsName}) : super(key: key);

  @override
  _ProductGraphScreenState createState() => _ProductGraphScreenState();
}

class _ProductGraphScreenState extends State<ProductGraphScreen> {
  late String goodsName;
  Map<String, double> weeklyData = {};
  late String currentMonth;
  List<Map<String, dynamic>> productDetailsList = [];

  @override
  void initState() {
    super.initState();
    goodsName = widget.goodsName;
    _fetchWeeklyData();
    _fetchProductDetails();
  }

  Future<void> _fetchWeeklyData() async {
    final currentDate = DateTime.now();
    final firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);
    currentMonth = DateFormat('MMMM yyyy').format(firstDayOfMonth);

    Map<String, double> tempWeeklyData = {};

    // Iteratively calculate each week's range in the month
    DateTime startOfWeek = firstDayOfMonth;
    while (startOfWeek.isBefore(lastDayOfMonth)) {
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      if (endOfWeek.isAfter(lastDayOfMonth)) {
        endOfWeek = lastDayOfMonth; // Make sure the last week doesn't exceed the month's end
      }
      final weekRange = '${startOfWeek.day}-${endOfWeek.day}';
      tempWeeklyData[weekRange] = 0.0;
      startOfWeek = endOfWeek.add(const Duration(days: 1)); // Move to the next week
    }

    final appraisalsSnapshot = await FirebaseFirestore.instance
        .collection('appraisals')
        .where('goods_name', isEqualTo: goodsName)
        .where('created_date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('created_date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
        .get();

    for (var doc in appraisalsSnapshot.docs) {
      final createdDate = doc['created_date'].toDate();
      final weekRange = _getWeekRange(createdDate, tempWeeklyData.keys.toList());
      final totalAmount = (doc['total_amount'] as num?)?.toDouble() ?? 0.0;

      if (weekRange != null) {
        tempWeeklyData[weekRange] = (tempWeeklyData[weekRange] ?? 0) + totalAmount;
      }
    }

    setState(() {
      weeklyData = tempWeeklyData;
    });
  }

  Future<void> _fetchProductDetails() async {
    final currentDate = DateTime.now();
    final firstDayOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0);

    final appraisalsSnapshot = await FirebaseFirestore.instance
        .collection('appraisals')
        .where('goods_name', isEqualTo: goodsName)
        .where('created_date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .where('created_date', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
        .get();

    List<Map<String, dynamic>> tempProductDetailsList = [];

    for (var doc in appraisalsSnapshot.docs) {
      final createdDate = doc['created_date'].toDate();
      final formattedDate = DateFormat('MM/dd/yyyy').format(createdDate); // Changed date format
      final data = {
        'goods_name': doc['goods_name'],
        'created_date': formattedDate,
        'total_amount': (doc['total_amount'] as num).toDouble(),
        'quantity': (doc['quantity'] as num).toInt(),
      };
      tempProductDetailsList.add(data);
    }

    // Debugging: Print the fetched product details
    print('Fetched Product Details: $tempProductDetailsList');

    setState(() {
      productDetailsList = tempProductDetailsList;
    });
  }

  String? _getWeekRange(DateTime date, List<String> weekRanges) {
    for (String range in weekRanges) {
      final days = range.split('-').map(int.parse).toList();
      if (date.day >= days[0] && date.day <= days[1]) {
        return range;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
/*       appBar: AppBar(
        title: Text(
          '${widget.goodsName} Appraisals',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ), */
       appBar: AppBar(
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        }
        ),
        title: Text(
           '${widget.goodsName} Appraisals',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentMonth,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            weeklyData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 250, // Reduced height for the chart
                    child: _buildLineChart(weeklyData),
                  ),
            const SizedBox(height: 20),
            const Text(
              'Appraisal Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            productDetailsList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        itemCount: productDetailsList.length,
                        itemBuilder: (context, index) {
                          final detail = productDetailsList[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              side: const BorderSide(color: Colors.green, width: 0.5),
                            ),
                            color: Colors.white, // Added white background
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        detail['goods_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        ' ${detail['created_date']}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Total Amount: ₱${detail['total_amount'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Total Quantity: ${detail['quantity']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

  Widget _buildLineChart(Map<String, double> data) {
    List<FlSpot> spots = [];
    List<String> uniqueWeekRanges = [];

    data.forEach((weekRange, totalAmount) {
      spots.add(FlSpot(spots.length.toDouble(), totalAmount));
      uniqueWeekRanges.add(weekRange);
    });

    // Calculate the maximum value to determine the interval
    double maxValue = data.values.reduce((a, b) => a > b ? a : b);

    // Determine the interval based on the maximum value
    double interval;
    if (maxValue > 3000) {
      interval = 1000;
    } else if (maxValue > 1500) {
      interval = 500;
    } else {
      interval = 250;
    }

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, // Set to true to smooth the line
              color: Colors.green,
              barWidth: 2, // Increased barWidth to smooth the transitions
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < uniqueWeekRanges.length) {
                    final weekRange = uniqueWeekRanges[index];
                    final monthAbbreviation = DateFormat('MMM').format(DateTime.now()); // Get the current month abbreviation
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '$monthAbbreviation $weekRange',
                        style: const TextStyle(
                          color: Colors.black,
/*                           fontWeight: FontWeight.bold,
 */                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                  return Container(); // Empty container if out of bounds
                },
                interval: 1,
                reservedSize: 20, // Reduced reserved size to lessen the distance between dates
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval, // Set interval dynamically
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value % interval == 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${(value / interval * interval).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    );
                  }
                  return Container(); // Don't show titles that are not multiples of the interval
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
              bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (double value) {
              // Draw lines at each specific interval
              return FlLine(
                color: Colors.grey.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          maxY: (maxValue / interval).ceil() * interval, // Round up to the next interval
        ),
      ),
    );
  }
}
