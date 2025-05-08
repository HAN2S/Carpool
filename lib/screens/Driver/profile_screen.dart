import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rider Profile', style: Theme.of(context).textTheme.titleLarge),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Michael B.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '39 years old',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.message),
                      label: Text('Message'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.call),
                      label: Text('Call'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      _buildVerificationRow(context, 'Driver verified', Icons.check_circle),
                      _buildVerificationRow(context, 'Phone Number verified', Icons.check_circle),
                      _buildVerificationRow(context, 'Left one trip ago', Icons.timer),
                      _buildVerificationRow(context, '3rd trip completed', Icons.directions_car),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text('Prefers a quiet ride', style: Theme.of(context).textTheme.bodyMedium),
                      Text('Smoking bothers me', style: Theme.of(context).textTheme.bodyMedium),
                      Text('Pets OK', style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: 16),
                      Text(
                        'Languages',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text('German, English, French', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (_) => Icon(Icons.star, color: Colors.yellow, size: 20)),
                          SizedBox(width: 8),
                          Text('5.0', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      SizedBox(height: 8),
                      ReviewRow(name: 'Oscar M.', rating: '5.0'),
                      ReviewRow(name: 'Camilia O.', rating: '5.0'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationRow(BuildContext context, String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: icon == Icons.check_circle ? Theme.of(context).colorScheme.primary : Colors.grey),
          SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ReviewRow extends StatelessWidget {
  final String name;
  final String rating;

  ReviewRow({required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(name[0], style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                Text(rating, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}