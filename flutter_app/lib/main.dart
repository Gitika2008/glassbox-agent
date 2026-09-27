import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GlassBoxApp());
}

class GlassBoxApp extends StatelessWidget {
  const GlassBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlassBox Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00FF88),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _incomeController = TextEditingController();
  final _attendanceController = TextEditingController();
  String _existingAid = 'no';
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _evaluate() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'cgpa': double.parse(_cgpaController.text),
          'family_income': double.parse(_incomeController.text),
          'attendance': double.parse(_attendanceController.text),
          'existing_aid': _existingAid,
        }),
      );

      setState(() {
        _result = jsonDecode(response.body);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            // Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 8),
                const Text(
                  'GLASSBOX AGENT · SCHOLARSHIP ALLOCATION',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'The Glass Box\nAgent.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every decision comes with a visible reasoning trail.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Input Form
            _buildLabel('STUDENT NAME'),
            _buildInput(_nameController, 'e.g. Gitika Sanjay'),
            const SizedBox(height: 16),

            _buildLabel('CGPA (out of 10)'),
            _buildInput(_cgpaController, 'e.g. 8.5', isNumber: true),
            const SizedBox(height: 16),

            _buildLabel('FAMILY INCOME (₹ per year)'),
            _buildInput(_incomeController, 'e.g. 250000', isNumber: true),
            const SizedBox(height: 16),

            _buildLabel('ATTENDANCE (%)'),
            _buildInput(_attendanceController, 'e.g. 80', isNumber: true),
            const SizedBox(height: 16),

            _buildLabel('EXISTING AID?'),
            Row(
              children: [
                _buildChip('No', 'no'),
                const SizedBox(width: 12),
                _buildChip('Yes', 'yes'),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _evaluate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'EVALUATE APPLICATION',
                        style: TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 40),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final decision = _result!['decision'];
    final isApproved = decision == 'APPROVED';
    final steps = _result!['reasoning_steps'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decision Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: isApproved
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF4444),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                decision,
                style: TextStyle(
                  color: isApproved
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF4444),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'Confidence: ${_result!['confidence']}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Reasoning Trail
        const Text(
          'REASONING TRANSCRIPT',
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),

        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final passed = step['passed'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              border: Border(
                left: BorderSide(
                  color: passed
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFF4444),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0${i + 1}',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['criterion'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['reason'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  step['status'],
                  style: TextStyle(
                    color: passed
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF111111),
          child: Text(
            _result!['summary'],
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _existingAid == value;
    return GestureDetector(
      onTap: () => setState(() => _existingAid = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C63FF) : const Color(0xFF111111),
          border: Border.all(
            color: selected ? const Color(0xFF6C63FF) : Colors.grey.shade800,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
