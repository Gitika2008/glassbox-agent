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
  final _appealReasonController = TextEditingController();
  final _appealInfoController = TextEditingController();

  String _scenario = 'scholarship';
  String _existingAid = 'no';
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _showAppeal = false;
  bool _appealSubmitted = false;
  Map<String, dynamic>? _appealResult;
  Map<String, String> _challengeReasons = {};
  Map<String, dynamic?> _challengeResults = {};
  Map<String, dynamic?> _whatIfResults = {};
  late AnimationController _fadeController;

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Color get _accentColor => _scenarios[_scenario]!['color'] as Color;

  Map<String, dynamic> _buildBody() {
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
    return body;
  }

  Future<void> _evaluate() async {
    setState(() {
      _loading = true;
      _result = null;
      _showAppeal = false;
      _appealSubmitted = false;
      _challengeReasons = {};
      _challengeResults = {};
      _whatIfResults = {};
    });
    _fadeController.reset();
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildBody()),
      );
      setState(() {
        _result = jsonDecode(response.body);
        _loading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _challenge(String criterion) async {
    final reason = _challengeReasons[criterion] ?? '';
    if (reason.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/challenge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student': _buildBody(),
          'challenged_criterion': criterion,
          'challenge_reason': reason,
        }),
      );
      setState(() {
        _challengeResults[criterion] = jsonDecode(response.body);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge error: $e')),
        );
      }
    }
  }

  Future<void> _whatIf(String criterion) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/whatif'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student': _buildBody(),
          'target_criterion': criterion,
        }),
      );
      setState(() {
        _whatIfResults[criterion] = jsonDecode(response.body);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('What-if error: $e')),
        );
      }
    }
  }

  Future<void> _submitAppeal() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/appeal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student': _buildBody(),
          'appeal_reason': _appealReasonController.text,
          'supporting_info': _appealInfoController.text,
        }),
      );
      setState(() {
        _appealResult = jsonDecode(response.body);
        _appealSubmitted = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appeal error: $e')),
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
              FadeTransition(
                opacity: _fadeController,
                child: _buildResults(),
              ),
            ],
            const SizedBox(height: 60),
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
              style: TextStyle(color: _accentColor, fontSize: 11, letterSpacing: 2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'The Glass Box\nAgent.',
          style: TextStyle(
            color: Colors.white, fontSize: 40,
            fontWeight: FontWeight.bold, height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Every decision comes with a visible reasoning trail — challengeable, auditable, fair.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildScenarioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT SCENARIO',
          style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2)),
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
                  _showAppeal = false;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : const Color(0xFF111111),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade800,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(entry.value['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(entry.value['title'],
                        style: TextStyle(
                          color: isSelected ? color : Colors.grey,
                          fontWeight: FontWeight.bold, fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(entry.value['desc'],
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
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
        if (_scenario == 'scholarship') ...[
          _buildLabel('FAMILY INCOME (₹ per year)'),
          _buildInput(_incomeController, 'e.g. 250000', isNumber: true),
          const SizedBox(height: 16),
          _buildLabel('EXISTING AID?'),
          Row(children: [
            _buildChip('No', 'no'),
            const SizedBox(width: 12),
            _buildChip('Yes', 'yes'),
          ]),
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_scenarios[_scenario]!['icon'], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  const Text('EVALUATE APPLICATION',
                    style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold,
                      fontSize: 14, color: Colors.white)),
                ],
              ),
      ),
    );
  }

  Widget _buildResults() {
    final decision = _result!['decision'];
    final isApproved = decision == 'APPROVED';
    final steps = _result!['reasoning_steps'] as List;
    final confidence = (_result!['confidence_value'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decision Banner with Confidence Meter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isApproved
                ? const Color(0xFF00FF88).withOpacity(0.05)
                : const Color(0xFFFF4444).withOpacity(0.05),
            border: Border.all(
              color: isApproved ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
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
                      '${_result!['scenario_icon']} ${_result!['scenario_title']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      decision,
                      style: TextStyle(
                        color: isApproved ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                        fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 4,
                      ),
                    ),
                    Text(
                      _result!['student_name'],
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Circular Confidence Meter
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: confidence / 100),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade800,
                          color: isApproved ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                        );
                      },
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: confidence),
                      duration: const Duration(milliseconds: 1200),
                      builder: (context, value, _) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Reasoning Trail
        Row(
          children: [
            Container(width: 3, height: 16, color: _accentColor),
            const SizedBox(width: 8),
            const Text('REASONING TRANSCRIPT',
              style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade800)),
              child: const Text('CHALLENGEABLE',
                style: TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final passed = step['passed'] as bool;
          final criterion = step['criterion'] as String;
          final hasChallengeResult = _challengeResults.containsKey(criterion);
          final hasWhatIfResult = _whatIfResults.containsKey(criterion);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (i * 200)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border(
                  left: BorderSide(
                    color: passed ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('0${i + 1}',
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.bold, fontSize: 20,
                              )),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(criterion,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold, fontSize: 13,
                                        )),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: Colors.grey.shade900,
                                        child: Text(step['label'],
                                          style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(step['reason'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Value: ${step['value']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      const SizedBox(width: 12),
                                      Text('Required: ${step['threshold']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(step['status'],
                              style: TextStyle(
                                color: passed ? const Color(0xFF00FF88) : const Color(0xFFFF4444),
                                fontWeight: FontWeight.bold, fontSize: 12,
                              )),
                          ],
                        ),

                        // Failure Explanation
                        if (!passed && step['failure_explanation'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: const Color(0xFFFF4444).withOpacity(0.05),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFFF4444), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(step['failure_explanation'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Action Buttons for failed steps
                        if (!passed) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildActionButton(
                                '🔮 What If?',
                                const Color(0xFF6C63FF),
                                () => _whatIf(criterion),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                '💬 Challenge',
                                const Color(0xFFFFB300),
                                () => _showChallengeDialog(criterion),
                              ),
                            ],
                          ),
                        ],

                        // What If Result
                        if (hasWhatIfResult && _whatIfResults[criterion] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.05),
                              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Text('🔮 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    _whatIfResults[criterion]!['what_if_hint'] ?? '',
                                    style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Challenge Result
                        if (hasChallengeResult && _challengeResults[criterion] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withOpacity(0.05),
                              border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('💬 ', style: TextStyle(fontSize: 14)),
                                    Text(
                                      'Challenge ID: ${_challengeResults[criterion]!['challenge_id']}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontWeight: FontWeight.bold, fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      color: const Color(0xFFFFB300).withOpacity(0.2),
                                      child: const Text('UNDER REVIEW',
                                        style: TextStyle(color: Color(0xFFFFB300), fontSize: 9)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _challengeResults[criterion]!['review_message'] ?? '',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
                child: Text(_result!['summary'],
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        ),

        // Appeal Section (only for rejected)
        if (_result!['decision'] == 'REJECTED') ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _showAppeal = !_showAppeal),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('File an Appeal',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Disagree with this decision? Submit an appeal.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(_showAppeal ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey),
                ],
              ),
            ),
          ),

          if (_showAppeal && !_appealSubmitted) ...[
            const SizedBox(height: 16),
            _buildLabel('REASON FOR APPEAL'),
            _buildInput(_appealReasonController, 'Why do you think the decision was wrong?'),
            const SizedBox(height: 16),
            _buildLabel('SUPPORTING INFORMATION'),
            _buildInput(_appealInfoController, 'Any additional documents or context...'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade900,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  side: const BorderSide(color: Color(0xFFFFB300)),
                ),
                child: const Text('SUBMIT APPEAL',
                  style: TextStyle(letterSpacing: 2, color: Color(0xFFFFB300))),
              ),
            ),
          ],

          if (_appealSubmitted && _appealResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.05),
                border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('✅ Appeal Submitted',
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontWeight: FontWeight.bold,
                        )),
                      const Spacer(),
                      Text(_appealResult!['appeal_id'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_appealResult!['next_steps'] as List).map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('→ ', style: TextStyle(color: Color(0xFFFFB300))),
                          Expanded(
                            child: Text(step,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showChallengeDialog(String criterion) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: Text('Challenge: $criterion',
          style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why do you think this step is wrong?',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your reason...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _challengeReasons[criterion] = controller.text);
              Navigator.pop(context);
              _challenge(criterion);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300)),
            child: const Text('Submit', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          color: color.withOpacity(0.05),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
        style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2)),
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
          border: Border.all(color: selected ? _accentColor : Colors.grey.shade800),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          )),
      ),
    );
  }
}
