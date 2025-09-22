import 'package:flutter/material.dart';
import 'constants/colors.dart';

class TestIconScreen extends StatelessWidget {
  const TestIconScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Icon Test'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Testing Person Icon',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Test the person icon
            Container(
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
              child: Column(
                children: [
                  const Text('Person Icon Test:'),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: () {
                      // Person icon tapped - Simple navigation test without ProfileScreen dependency
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Person icon works! Navigation successful.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the icon above'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Test other icons for comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    IconButton(
                      onPressed: () {}, // Home tapped
                      icon: Icon(Icons.home, color: AppColors.textSecondary),
                    ),
                    const Text('Home'),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {}, // Settings tapped
                      icon: Icon(Icons.settings, color: AppColors.textSecondary),
                    ),
                    const Text('Settings'),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {}, // Search tapped
                      icon: Icon(Icons.search, color: AppColors.textSecondary),
                    ),
                    const Text('Search'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}