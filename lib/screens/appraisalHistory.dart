import 'package:ambulantcollector/screens/appraisalDetailsTap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final CollectionReference appraisalsRef = FirebaseFirestore.instance.collection('appraisals');
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<DocumentSnapshot> _filteredDocs = [];
  SharedPreferences? prefs;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
/*             Icon(Icons.history, color: Colors.white),
 */            SizedBox(width: 8),
            Text("History", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Filter ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton('All'),
                const SizedBox(width: 10),
                _buildFilterButton('Today'),
                const SizedBox(width: 10),
                _buildFilterButton('This Week'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter name, date or trans. id.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.green),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: appraisalsRef.orderBy('created_date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                _filteredDocs = _filterDocs(snapshot.data!.docs);

                if (_filteredDocs.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = _filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    var createdDate = (data['created_date'] as Timestamp).toDate();
                    var formattedDate = DateFormat('MM/dd/yyyy, h:mm a').format(createdDate);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 0.4),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _highlightMatch(
                                    data['appraisee_name'] ?? '',
                                    _searchQuery,
                                    const TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                  _highlightMatch(
                                    formattedDate,
                                    _searchQuery,
                                    const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data['goods_name']}',
                                style: const TextStyle(fontSize: 14/* , fontWeight: FontWeight.bold */),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Transaction Id: ',
                                        style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 104, 102, 102)),
                                      ),
                                      _highlightMatch(
                                        doc.id,
                                        _searchQuery,
                                        const TextStyle(fontSize: 10, color: Color.fromARGB(255, 104, 102, 102)),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppraisalDetailsTap(
                                  goodsName: data['goods_name'],
                                  appSize: data['app_size'],
                                  appRate: data['app_rate'].toString(),
                                  quantity: data['quantity'],
                                  unitMeasure: data['unit_measure'],
                                  totalAmount: data['total_amount'].toDouble(),
                                  createdDate: (data['created_date'] as Timestamp).toDate(),
                                  documentId: doc.id,
                                  appraiserAppraisal: data['appraisal'],
                                  appraiserEmail: data['appraiser_email'],
                                  appraisee: data ['appraisee_name'],
                                  appraisalAddress: data['Address_appraisal'],
                                  unitassign: data['appraisal_assign'],
                                  contactAppraisal: data['contact_appraisal'],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _selectedFilter == filter ? Colors.green : Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.transparent,
        minimumSize: const Size(2, 25),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Text(
        filter,
        style: TextStyle(
          color: _selectedFilter == filter ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  List<DocumentSnapshot> _filterDocs(List<DocumentSnapshot> docs) {
    List<DocumentSnapshot> filteredDocs = [];

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      var createdDate = (data['created_date'] as Timestamp).toDate();
      var formattedDate = DateFormat('MM/dd/yyyy, h:mm a').format(createdDate);
      var appraiseeName = data['appraisee_name']?.toLowerCase() ?? '';
      var transactionId = doc.id.toLowerCase();

      if (_searchQuery.isNotEmpty &&
          !appraiseeName.contains(_searchQuery) &&
          !formattedDate.toLowerCase().contains(_searchQuery) &&
          !transactionId.contains(_searchQuery)) {
        continue;
      }

      if (_selectedFilter == 'Today' && !_isToday(createdDate)) {
        continue;
      }

      if (_selectedFilter == 'This Week' && !_isThisWeek(createdDate)) {
        continue;
      }

      filteredDocs.add(doc);
    }

    return filteredDocs;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  Widget _highlightMatch(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    var matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: style.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextSpan(text: text.substring(matchIndex + query.length)),
        ],
      ),
    );
  }
}
