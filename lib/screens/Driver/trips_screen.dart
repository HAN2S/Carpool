import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'suggestion_screen.dart';

class TripsScreen extends StatefulWidget {
  @override
  _TripsScreenState createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _currentDayIndex = 0;
  final List<String> days = [
    'Monday 7 Apr',
    'Tuesday 8 Apr',
    'Wednesday 9 Apr',
    'Thursday 10 Apr',
    'Friday 11 Apr',
    'Saturday 12 Apr',
    'Sunday 13 Apr',
  ];

  final List<Map<String, dynamic>> trips = [
    {
      'time': '08:00',
      'startAddress': 'Stuttgart-Vaihingen',
      'endAddress': 'Andreas-Stihl-Str.',
      'riders': [
        {'name': 'Shayna S.', 'department': 'Finance', 'pickupTime': '8:07', 'detourTime': '6 mins'},
        {'name': 'Michael B.', 'department': 'IT', 'pickupTime': '8:15', 'detourTime': '7 mins'},
      ],
    },
    {
      'time': '17:00',
      'startAddress': 'Andreas-Stihl-Str.',
      'endAddress': 'Stuttgart-Vaihingen',
      'riders': [
        {'name': 'Alex A.', 'department': 'Marketing', 'pickupTime': '17:12', 'detourTime': '5 mins'},
        {'name': 'Michael B.', 'department': 'IT', 'pickupTime': '17:21', 'detourTime': '8 mins'},
      ],
    },
  ];

  void _previousDay() {
    setState(() {
      _currentDayIndex = (_currentDayIndex - 1 + days.length) % days.length;
    });
  }

  void _nextDay() {
    setState(() {
      _currentDayIndex = (_currentDayIndex + 1) % days.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Pendla',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Trips',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(width: 60), // Balances the layout
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_left, color: Colors.black),
                    onPressed: _previousDay,
                  ),
                  Text(
                    days[_currentDayIndex],
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right, color: Colors.black),
                    onPressed: _nextDay,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...trips.map((trip) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trip',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              trip['time'],
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.map,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    trip['startAddress'],
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                Expanded(
                                  child: Text(
                                    trip['endAddress'],
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ...trip['riders'].map<Widget>((rider) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SuggestionScreen(
                                    riderName: rider['name'],
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.green[100],
                                      child: Text(
                                        rider['name'][0],
                                        style: GoogleFonts.roboto(
                                          fontSize: 16,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rider['name'],
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            rider['department'],
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Pick-up Time ${rider['pickupTime']}',
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      rider['detourTime'],
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}