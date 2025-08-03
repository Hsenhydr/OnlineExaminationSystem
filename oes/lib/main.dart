import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  List<Map<String, dynamic>> majors = [];
  int? selectedMajorId;

  @override
  void initState() {
    super.initState();
    fetchMajors();
  }

  Future<void> fetchMajors() async {
    final url = Uri.parse('http://192.168.0.106:4000/api/instructor/getmajors');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          majors = data.cast<Map<String, dynamic>>();
        });
      } else {
        _showError("Failed to load majors");
      }
    } catch (e) {
      _showError("Error fetching majors: $e");
    }
  }

  Future<void> _signUp() async {
    final fullName = fullNameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final role = roleController.text;

    if (selectedMajorId == null) {
      _showError("Please select a major.");
      return;
    }

    final url = Uri.parse('http://192.168.0.106:4000/api/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-client-platform': 'mobile',
        },
        body: jsonEncode({
          'name': fullName,
          'email': email,
          'password': password,
          'role': role,
          'major_id': selectedMajorId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        _showError(responseData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Signup Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedMajorId,
                items: majors.map((major) {
                  return DropdownMenuItem<int>(
                    value: major['id'],
                    child: Text(major['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMajorId = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Select Major',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.106:4000/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-platform': 'mobile',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Raw response: ${response.body}');
      print('Status code: ${response.statusCode}');

      final data = jsonDecode(response.body);
      print('Decoded response: $data');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamList(userId: data['user']['id']),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      _showError('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExamList extends StatefulWidget {
  final int userId;

  const ExamList({Key? key, required this.userId}) : super(key: key);

  @override
  State<ExamList> createState() => _ExamListState();
}

class _ExamListState extends State<ExamList> {
  List<Map<String, dynamic>> exams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchStudentExams();
  }

  Future<void> fetchStudentExams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          'http://192.168.0.106:4000/api/student/${widget.userId}/getexams');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          exams = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              jsonDecode(response.body)['message'] ?? 'Failed to load exams';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching exams: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    } else if (exams.isEmpty) {
      content = const Center(
        child: Text('No exams available for your major.'),
      );
    } else {
      content = Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: exams.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(exams[index]['title'].toString()),
                    subtitle: Text(
                        'Duration: ${exams[index]['duration'].toString()} minutes'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamQuestionsPage(
                            studentId: widget.userId,
                            examTitle: exams[index]['title'].toString(),
                            examId: exams[index]['id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assessment),
                label: const Text('View My Results'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentResult(
                        studentId: widget.userId.toString(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Exams')),
      body: content,
    );
  }
}

class StudentResult extends StatefulWidget {
  final String studentId;
  const StudentResult({Key? key, required this.studentId}) : super(key: key);

  @override
  _StudentResultState createState() => _StudentResultState();
}

class _StudentResultState extends State<StudentResult> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          'http://192.168.0.106:4000/api/student/${widget.studentId}/getResults');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<Map<String, dynamic>> resultsList =
            List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item)),
        );

        setState(() {
          _results = resultsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              jsonDecode(response.body)['message'] ?? 'Failed to load results';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching results: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    } else if (_results.isEmpty) {
      content = const Center(
        child: Text('No results found.'),
      );
    } else {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 150,
          headingTextStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          dataTextStyle: const TextStyle(fontSize: 13),
          columns: const [
            DataColumn(label: Text('Exam Title')),
            DataColumn(label: Text('Score')),
          ],
          rows: _results.map((result) {
            final score = result['score'] as int? ?? 0;
            final isPassed = score >= 50;

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  return isPassed
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2);
                },
              ),
              cells: [
                DataCell(Text(result['exam_title']?.toString() ?? '')),
                DataCell(Text(score.toString())),
              ],
            );
          }).toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Results')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
}

class ExamQuestionsPage extends StatefulWidget {
  final String examTitle;
  final int examId;
  final int studentId;

  const ExamQuestionsPage({
    super.key,
    required this.examTitle,
    required this.examId,
    required this.studentId,
  });

  @override
  State<ExamQuestionsPage> createState() => _ExamQuestionsPageState();
}

class _ExamQuestionsPageState extends State<ExamQuestionsPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _exam;
  List<Map<String, dynamic>> _questions = [];
  List<int?> _selectedOptions = [];

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _fetchExamWithQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchExamWithQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.0.106:4000/api/student/getexam/${widget.examId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          _showError("Invalid response from server:\n${response.body}");
          return;
        }
        setState(() {
          _exam = data['exam'];
          _questions = (data['questions'] as List)
              .map<Map<String, dynamic>>((q) => q as Map<String, dynamic>)
              .toList();
          _selectedOptions = List<int?>.filled(_questions.length, null);

          _remainingSeconds = (_exam?['duration'] ?? 0) * 60;
          _startTimer();

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = jsonDecode(response.body)['message'] ??
              'Failed to load exam questions';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching exam questions: $e";
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmitOnTimeout();
      } else {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _autoSubmitOnTimeout() async {
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Time's up!"),
          content: const Text(
              "Your exam time has expired. Submitting your answers."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }

    await _submitAnswers(autoSubmit: true);
  }

  Future<void> _submitAnswers({bool autoSubmit = false}) async {
    final Map<String, String> answers = {};
    for (int i = 0; i < _questions.length; i++) {
      final selectedOptionIndex = _selectedOptions[i];
      if (selectedOptionIndex != null) {
        final questionId = _questions[i]['id'].toString();
        final answerLetter = String.fromCharCode(65 + selectedOptionIndex);
        answers[questionId] = answerLetter;
      }
    }

    if (!autoSubmit && answers.length < _questions.length) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Incomplete Exam"),
          content: const Text("Some questions are unanswered. Submit anyway?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Submit")),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.106:4000/api/student/submit-exam'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'studentId': widget.studentId,
          'examId': widget.examId,
          'answers': answers,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _showError("Invalid response from server:\n${response.body}");
        return;
      }

      print("Response status: ${response.statusCode}");
      print("Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        _timer?.cancel();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Exam Submitted'),
            content: Text(
              'You scored ${data['score']} out of 100\n'
              'Correct Answers: ${data['correctAnswers']} / ${data['totalQuestions']}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => StudentResult(
                        studentId: widget.studentId.toString(),
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showError(data['message'] ?? 'Failed to submit exam');
      }
    } catch (e) {
      _showError('Error submitting exam: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.examTitle}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center),
                ))
              : _questions.isEmpty
                  ? const Center(
                      child: Text('No questions found for this exam.'))
                  : Column(
                      children: [
                        if (_exam != null)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Exam: ${_exam!['title']}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text('Major: ${_exam!['major']}'),
                                Text('Duration: ${_exam!['duration']} minutes'),
                                Text(
                                    'Time Left: ${_formatTime(_remainingSeconds)}')
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final question = _questions[index];
                              final options = [
                                question['choice_a'] ?? '',
                                question['choice_b'] ?? '',
                                question['choice_c'] ?? '',
                                question['choice_d'] ?? '',
                              ];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Question ${index + 1}: ${question['question_text'] ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...List.generate(options.length,
                                          (optIndex) {
                                        return RadioListTile<int>(
                                          title: Text(
                                              '${String.fromCharCode(65 + optIndex)}. ${options[optIndex]}'),
                                          value: optIndex,
                                          groupValue: _selectedOptions[index],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedOptions[index] = value;
                                            });
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed:
                                _isLoading ? null : () => _submitAnswers(),
                            child: const Text("Submit Exam"),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
