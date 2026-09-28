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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _incomeController = TextEditingController();
  final _attendanceController = TextEditingController();
  final _departmentController = TextEditingController();
  final _projectScoreController = TextEditingController();

  String _scenario = 'scholarship';
  String _existingAid = 'no';
  Map<String, dynamic>? _result;
  bool _loading = false;
  late AnimationController _animController;

  final Map<String, Map<String, dynamic>> _scenarios = {
    'scholarship': {
      'icon': '🎓',
      'title': 'Scholarship',
      'color': const Color(0xFF6C63FF),
      'desc': 'Financial aid allocation'
    },
    'lab_access': {
      'icon': '🔬',
      'title': 'Lab Access',
      'color': const Color(0xFF00BCD4),
      'desc': 'Laboratory access request'
    },
    'project_funding': {
      'icon': '💡',
      'title': 'Project Fund',
      'color': const Color(0xFFFFB300),
      'desc': 'Project funding request'
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      _scenarios[_scenario]!['color'] as Color;

  Future<void> _evaluate() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    _animController.reset();

    try {
      final body = {
        'name': _nameController.text.isEmpty ? 'Student' : _nameController.text,
        'scenario': _scenario,
        'cgpa': double.tryParse(_cgpaController.text) ?? 0,
        'attendance': double.tryParse(_attendanceController.text) ?? 0,
      };

      if (_scenario == 'scholarship') {
        body['family_income'] = double.tryParse(_incomeController.text) ?? 0;
        body['existing_aid'] = _existingAid;
      }
      if (_scenario == 'lab_access') {
        body['department'] = _departmentController.text;
      }
      if (_scenario == 'project_funding') {
        body['project_score'] = double.tryParse(_projectScoreController.text) ?? 0;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      setState(() {
        _result = jsonDecode(response.body);
        _loading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Make sure backend is running! $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            _buildHeader(),
            const SizedBox(height: 32),
            _buildScenarioSelector(),
            const SizedBox(height: 32),
            _buildForm(),
            const SizedBox(height: 32),
            _buildEvaluateButton(),
            if (_result != null) ...[
              const SizedBox(height: 40),
              _buildResults(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, color: _accentColor),
            const SizedBox(width: 8),
            Text(
              'GLASSBOX AGENT · AUDITABLE AI DECISIONS',
              style: TextStyle(
                color: _accentColor,
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
      ],
    );
  }

  Widget _buildScenarioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT SCENARIO',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _scenarios.entries.map((entry) {
            final isSelected = _scenario == entry.key;
            final color = entry.value['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _scenario = entry.key;
                  _result = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : const Color(0xFF111111),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade800,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.value['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.value['title'],
                        style: TextStyle(
                          color: isSelected ? color : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value['desc'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('STUDENT NAME'),
        _buildInput(_nameController, 'e.g. Gitika Sanjay'),
        const SizedBox(height: 16),
        _buildLabel('CGPA (out of 10)'),
        _buildInput(_cgpaController, 'e.g. 8.5', isNumber: true),
        const SizedBox(height: 16),
        _buildLabel('ATTENDANCE (%)'),
        _buildInput(_attendanceController, 'e.g. 80', isNumber: true),
        const SizedBox(height: 16),

        // Scenario-specific fields
        if (_scenario == 'scholarship') ...[
          _buildLabel('FAMILY INCOME (₹ per year)'),
          _buildInput(_incomeController, 'e.g. 250000', isNumber: true),
          const SizedBox(height: 16),
          _buildLabel('EXISTING AID?'),
          Row(
            children: [
              _buildChip('No', 'no'),
              const SizedBox(width: 12),
              _buildChip('Yes', 'yes'),
            ],
          ),
        ],

        if (_scenario == 'lab_access') ...[
          _buildLabel('DEPARTMENT'),
          _buildInput(_departmentController, 'e.g. ECE, CS, Mechanical'),
        ],

        if (_scenario == 'project_funding') ...[
          _buildLabel('PROJECT SCORE (%)'),
          _buildInput(_projectScoreController, 'e.g. 75', isNumber: true),
        ],
      ],
    );
  }

  Widget _buildEvaluateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _evaluate,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          elevation: 0,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _scenarios[_scenario]!['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'EVALUATE APPLICATION',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResults() {
    final decision = _result!['decision'];
    final isApproved = decision == 'APPROVED';
    final steps = _result!['reasoning_steps'] as List;
    final scenarioTitle = _result!['scenario_title'] ?? '';
    final scenarioIcon = _result!['scenario_icon'] ?? '';

    return FadeTransition(
      opacity: _animController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFF00FF88).withOpacity(0.05)
                  : const Color(0xFFFF4444).withOpacity(0.05),
              border: Border.all(
                color: isApproved
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF4444),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$scenarioIcon $scenarioTitle',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        decision,
                        style: TextStyle(
                          color: isApproved
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFF4444),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        '${_result!['student_name']} · Confidence: ${_result!['confidence']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isApproved
                        ? const Color(0xFF00FF88).withOpacity(0.1)
                        : const Color(0xFFFF4444).withOpacity(0.1),
                    border: Border.all(
                      color: isApproved
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFF4444),
                    ),
                  ),
                  child: Icon(
                    isApproved ? Icons.check : Icons.close,
                    color: isApproved
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF4444),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Reasoning Trail Header
          Row(
            children: [
              Container(width: 3, height: 16, color: _accentColor),
              const SizedBox(width: 8),
              const Text(
                'REASONING TRANSCRIPT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: const Text(
                  'CHALLENGEABLE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reasoning Steps
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final passed = step['passed'] as bool;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (i * 150)),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
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
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                step['criterion'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                color: Colors.grey.shade900,
                                child: Text(
                                  step['label'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step['reason'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Value: ${step['value']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Required: ${step['threshold']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step['status'],
                      style: TextStyle(
                        color: passed
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!['summary'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildInput(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _accentColor),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _existingAid == value;
    return GestureDetector(
      onTap: () => setState(() => _existingAid = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accentColor : const Color(0xFF111111),
          border: Border.all(
            color: selected ? _accentColor : Colors.grey.shade800,
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
