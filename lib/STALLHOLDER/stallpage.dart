import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registration_page.dart'; // Import the registration page

class StallPage extends StatefulWidget {
  @override
  _StallPageState createState() => _StallPageState();
}

class _StallPageState extends State<StallPage> {
  final CollectionReference stallsRef =
      FirebaseFirestore.instance.collection('Stall');

  String selectedStatus = 'All';
  String selectedLocation = 'All';

  List<String> statusOptions = ['All', 'Vacant', 'Occupied'];
  List<String> locationOptions = [
    'All',
    'Unit 1',
    'Unit 2',
    'Unit 3',
    'Barracks',
    'Freedom'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Center(
          child: Text(
            'Stalls',
            style: GoogleFonts.kanit(
              color: const Color.fromARGB(255, 41, 25, 25),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Dropdown filters for Status and Location
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Status Dropdown
                Text('Status:'),
                DropdownButton<String>(
                  value: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                ),
                // Location Dropdown
                Text('Location:'),
                DropdownButton<String>(
                  value: selectedLocation,
                  onChanged: (value) {
                    setState(() {
                      selectedLocation = value!;
                    });
                  },
                  items: locationOptions.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Display the filtered stalls
          Expanded(
            child: StreamBuilder(
              stream: stallsRef.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No stalls available'));
                }

                // Filter the stalls based on selected status and location
                var filteredStalls = snapshot.data!.docs.where((doc) {
                  var stall = doc.data() as Map<String, dynamic>;

                  // Filter by status
                  if (selectedStatus != 'All') {
                    if (selectedStatus == 'Vacant' &&
                        stall['status'] != 'Available') {
                      return false;
                    } else if (selectedStatus == 'Occupied' &&
                        stall['status'] == 'Available') {
                      return false;
                    }
                  }

                  // Filter by location
                  if (selectedLocation != 'All' &&
                      stall['location'] != selectedLocation) {
                    return false;
                  }

                  return true;
                }).toList();

// Sort the stalls so that vacant ones appear first
                filteredStalls.sort((a, b) {
                  var stallA = a.data() as Map<String, dynamic>;
                  var stallB = b.data() as Map<String, dynamic>;

                  bool isVacantA = stallA['status'] == 'Available';
                  bool isVacantB = stallB['status'] == 'Available';

                  // Vacant (Available) stalls should come before Occupied stalls
                  return isVacantA ? -1 : (isVacantB ? 1 : 0);
                });

                return ListView.builder(
                  itemCount: filteredStalls.length,
                  itemBuilder: (context, index) {
                    var stall =
                        filteredStalls[index].data() as Map<String, dynamic>;
                    bool isVacant = stall['status'] == 'Available';

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Stall No.: ${stall['stallNumber'] ?? ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size: ${stall['stallSize'] ?? ''}'),
                            Text('Location: ${stall['location'] ?? ''}'),
                            Text(
                                'Rate: ${stall['ratePerMeter']?.toString() ?? ''} per meter'),
                          ],
                        ),
                        trailing: isVacant
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterPage(
                                          stallId: filteredStalls[index].id,
                                          stallData: stall),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                child: Text(
                                  'Vacant',
                                  style:
                                      GoogleFonts.manrope(color: Colors.white),
                                ),
                              )
                            : Text(
                                'Occupied',
                                style: GoogleFonts.manrope(color: Colors.red),
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
}
