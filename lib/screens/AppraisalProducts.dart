import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppraisalCollectedScreen extends StatefulWidget {
  const AppraisalCollectedScreen({Key? key}) : super(key: key);

  @override
  _AppraisalCollectedScreenState createState() => _AppraisalCollectedScreenState();
}

class _AppraisalCollectedScreenState extends State<AppraisalCollectedScreen> {
  final CollectionReference appraisalRateRef = FirebaseFirestore.instance.collection('appraisal_rate');
  String? currentAppraiserEmail;
  String? appraisalAssign;
  List<DocumentSnapshot> products = [];
  Map<String, List<DocumentSnapshot>> groupedProducts = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentAppraiserDetails();
  }

  Future<void> _fetchCurrentAppraiserDetails() async {
    try {
      currentAppraiserEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentAppraiserEmail != null) {
        final appraiserDoc = await FirebaseFirestore.instance
            .collection('appraisal_user')
            .where('email', isEqualTo: currentAppraiserEmail)
            .get();

        if (appraiserDoc.docs.isNotEmpty) {
          final appraiserData = appraiserDoc.docs.first.data() as Map<String, dynamic>;
          appraisalAssign = appraiserData['appraisal_assign'];
          await _fetchProducts();
        }
      }
    } catch (e) {
      print('Error fetching appraiser details: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final querySnapshot = await appraisalRateRef
          .where('location', isEqualTo: appraisalAssign)
          .get();

      setState(() {
        products = querySnapshot.docs;
        _groupProductsByNames();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void _groupProductsByNames() {
    groupedProducts.clear();
    for (var doc in products) {
      final data = doc.data() as Map<String, dynamic>;
      final goodsName = data['goods_name'].toString();
      if (groupedProducts.containsKey(goodsName)) {
        groupedProducts[goodsName]!.add(doc);
      } else {
        groupedProducts[goodsName] = [doc];
      }
    }
  }

  void _showProductDetails(BuildContext context, List<DocumentSnapshot> productDocs) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 60, // Increased height
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                ),
                child: const Center(
                  child: Text(
                    'Product Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const SizedBox(height: 15),
                     ListView.separated(
                      shrinkWrap: true,
                      itemCount: productDocs.length,
                      separatorBuilder: (context, index) => const Divider(height: 15, color: Colors.grey),
                      itemBuilder: (context, index) {
                        final doc = productDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final sizesAndRates = _getSizesAndRates(data);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${data['goods_name']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  /* Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Product: ',
                                          style: const TextStyle(
                                            fontSize: 15,
                                          /*   fontWeight: FontWeight.bold,  */// Bold only "Product"
                                          ),
                                        ),
                                        TextSpan(
                                          text: data['goods_name'], // Regular font weight for goods_name
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
 */
                                Text(
                                  'Unit Measure: ${data['unit_measure'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...sizesAndRates.map((sizeRate) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Size:   ${sizeRate['size']}',
                                          style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 97, 91, 91)),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Rate:   ₱${sizeRate['rate'] != null ? sizeRate['rate'].toStringAsFixed(2) : 'N/A'}',
                                          style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 97, 91, 91)),
                                        ),
                                      ],
                                    ),
                                    const Divider(color: Colors.grey),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSizesAndRates(Map<String, dynamic> data) {
    final sizesAndRates = <Map<String, dynamic>>[];
    final rateSizePairs = data['rate_size_pairs'] as List<dynamic>;

    for (var pair in rateSizePairs) {
      final sizeKey = pair.keys.firstWhere((key) => key.toString().startsWith('size_'), orElse: () => '');
      final rateKey = pair.keys.firstWhere((key) => key.toString().startsWith('rate_'), orElse: () => '');

      if (sizeKey.isNotEmpty && rateKey.isNotEmpty) {
        final size = pair[sizeKey];
        final rate = pair[rateKey];
        sizesAndRates.add({'size': size, 'rate': rate});
      }
    }

    return sizesAndRates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Appraisal Products",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.green),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedProducts.length,
              itemBuilder: (context, index) {
                final key = groupedProducts.keys.elementAt(index);
                final productDocs = groupedProducts[key]!;

                if (!key.toLowerCase().contains(_searchQuery)) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () => _showProductDetails(context, productDocs),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Colors.green, width: 1), // Add green border here
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _highlightMatch(
                                key,
                                _searchQuery,
                                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                              Text(
                                'Unit: ${(productDocs.first.data() as Map<String, dynamic>)['unit_measure'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 97, 91, 91)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ...productDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final sizesAndRates = _getSizesAndRates(data);
                            return Column(
                              children: sizesAndRates.map((sizeRate) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${sizeRate['size']}',
                                            style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 97, 91, 91)),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '₱${sizeRate['rate'] != null ? sizeRate['rate'].toStringAsFixed(2) : 'N/A'}',
                                            style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 97, 91, 91)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightMatch(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style.copyWith(fontWeight: FontWeight.normal));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(lowerQuery, lastIndex);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(lastIndex), style: style.copyWith(fontWeight: FontWeight.normal)));
        break;
      }
      if (matchIndex > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, matchIndex), style: style.copyWith(fontWeight: FontWeight.normal)));
      }
      spans.add(TextSpan(text: text.substring(matchIndex, matchIndex + query.length), style: style));
      lastIndex = matchIndex + query.length;
    }

    return RichText(text: TextSpan(children: spans, style: style));
  }
}
