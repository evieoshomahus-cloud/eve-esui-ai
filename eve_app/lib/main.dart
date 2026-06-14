import 'package:flutter/material.dart';

import 'attachment_picker.dart';
import 'eve_api.dart';
import 'eve_models.dart';

void main() {
  runApp(const EveApp());
}

class EveApp extends StatelessWidget {
  const EveApp({super.key});

  @override
  Widget build(BuildContext context) {
    const esuiBlue = Color(0xFF203B94);
    return MaterialApp(
      title: 'Eve ESUI AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: esuiBlue,
          primary: esuiBlue,
          secondary: const Color(0xFF79B900),
          tertiary: const Color(0xFFE2A03F),
          surface: const Color(0xFFF7F9FD),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FD),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE3E8F4)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const EveShell(),
    );
  }
}

class EveShell extends StatefulWidget {
  const EveShell({super.key});

  @override
  State<EveShell> createState() => _EveShellState();
}

class _EveShellState extends State<EveShell> {
  final EveApi _api = EveApi();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _courseController = TextEditingController(
    text: 'Computer Science',
  );
  final TextEditingController _jambController = TextEditingController(
    text: '245',
  );
  final TextEditingController _sessionAnswerController =
      TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _sessionStarted = false;
  bool _loadingUsers = true;
  bool _apiOnline = false;
  bool _sending = false;
  bool _estimating = false;
  bool _startingLearningSession = false;
  bool _submittingLearningAnswer = false;
  bool _uploadingAttachment = false;
  int _pageIndex = 0;
  final List<int> _pageHistory = <int>[];

  EveRole _role = EveRole.guest;
  String? _selectedUserId;
  String _english = 'B3';
  String _mathematics = 'B2';
  String _science = 'C4';
  String _fourthSubject = 'B3';
  AdmissionEstimate? _estimate;
  Map<String, dynamic>? _learningSession;

  List<EveUser> _users = const [
    EveUser(userId: 'guest-001', name: 'Guest User', role: EveRole.guest),
    EveUser(
      userId: 'stu-csc-001',
      name: 'Ada Osagie',
      role: EveRole.student,
      department: 'Computer Science',
      level: '200',
    ),
    EveUser(
      userId: 'stu-acc-002',
      name: 'Musa Bello',
      role: EveRole.student,
      department: 'Accounting',
      level: '300',
    ),
    EveUser(
      userId: 'lec-csc-001',
      name: 'Dr. Grace Ehi',
      role: EveRole.lecturer,
      department: 'Computer Science',
    ),
    EveUser(
      userId: 'lec-mth-002',
      name: 'Dr. Victor Ade',
      role: EveRole.lecturer,
      department: 'Mathematics',
    ),
    EveUser(
      userId: 'adm-knowledge-001',
      name: 'Mrs. Evelyn Okon',
      role: EveRole.admin,
      department: 'Registry / Student Affairs',
    ),
  ];

  List<ChatMessage> _messages = const [];
  List<String> _suggestions = const [];
  List<EveAttachment> _pendingAttachments = const [];
  String? _attachmentError;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _courseController.dispose();
    _jambController.dispose();
    _sessionAnswerController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _api.users();
      if (!mounted) return;
      setState(() {
        _users = users;
        _apiOnline = true;
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiOnline = false;
        _loadingUsers = false;
      });
    }
  }

  List<EveUser> get _roleUsers =>
      _users.where((user) => user.role == _role).toList();

  EveUser get _selectedUser {
    final selected = _users.where((user) => user.userId == _selectedUserId);
    if (selected.isNotEmpty) return selected.first;
    final roleMatches = _roleUsers;
    if (roleMatches.isNotEmpty) return roleMatches.first;
    return _users.first;
  }

  List<String> _starterSuggestions(EveRole role) {
    switch (role) {
      case EveRole.guest:
        return const [
          'What are the requirements for Computer Science admission?',
          'How do I apply for undergraduate admission?',
          'What skills should I build before studying Computer Science?',
        ];
      case EveRole.student:
        return const [
          'What are my weak courses and how should I improve?',
          'Generate a mock test for CSC 201.',
          'Plan my week using my timetable.',
        ];
      case EveRole.lecturer:
        return const [
          'Show lecturer analytics for CSC 201.',
          'Generate exam questions for CSC 201.',
          'What teaching intervention should I use this week?',
        ];
      case EveRole.admin:
        return const [
          'Review unanswered knowledge gaps.',
          'Audit Eve payment guidance and official links.',
          'What school-wide information should admins maintain?',
        ];
    }
  }

  void _startSession(EveRole role, {String? userId}) {
    final user = userId == null
        ? _users.firstWhere((item) => item.role == role)
        : _users.firstWhere((item) => item.userId == userId);
    setState(() {
      _role = role;
      _selectedUserId = user.userId;
      _sessionStarted = true;
      _pageIndex = 0;
      _pageHistory.clear();
      _suggestions = _starterSuggestions(role);
      _pendingAttachments = const [];
      _attachmentError = null;
      _messages = [
        ChatMessage(
          text: _welcomeMessage(user),
          fromUser: false,
          intent: 'welcome',
          confidence: 1,
          nextActions: _starterSuggestions(role),
        ),
      ];
    });
  }

  String _welcomeMessage(EveUser user) {
    if (user.role == EveRole.guest) {
      return 'Welcome to Eve. Ask me about ESUI admissions, programmes, fees, requirements, or how to prepare for your course of interest.';
    }
    if (user.role == EveRole.student) {
      return 'Welcome back, ${user.name}. I can help with your academic progress, weak topics, timetable planning, mock tests, and payment guidance.';
    }
    if (user.role == EveRole.admin) {
      return 'Welcome, ${user.name}. I can help govern school-wide knowledge, review unanswered questions, audit official links, and keep Eve safe for students.';
    }
    return 'Welcome, ${user.name}. I can help review assigned-course analytics, weak topics, assessment ideas, and teaching interventions.';
  }

  void _switchAccount(EveUser user) {
    Navigator.of(context).pop();
    _startSession(user.role, userId: user.userId);
  }

  void _logout() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _sessionStarted = false;
      _pageIndex = 0;
      _pageHistory.clear();
      _role = EveRole.guest;
      _selectedUserId = null;
      _messages = const [];
      _suggestions = const [];
      _pendingAttachments = const [];
      _attachmentError = null;
      _learningSession = null;
      _estimate = null;
      _messageController.clear();
      _sessionAnswerController.clear();
    });
  }

  Future<void> _askEve(String prompt) async {
    _openPage(1);
    await _sendMessage(prompt);
  }

  void _openPage(int index, {bool remember = true}) {
    if (_pageIndex == index) return;
    setState(() {
      if (remember &&
          (_pageHistory.isEmpty || _pageHistory.last != _pageIndex)) {
        _pageHistory.add(_pageIndex);
      }
      _pageIndex = index;
    });
  }

  void _replacePage(int index) {
    if (_pageIndex == index) return;
    setState(() {
      if (_pageHistory.isNotEmpty && _pageHistory.last == index) {
        _pageHistory.removeLast();
      }
      _pageIndex = index;
    });
  }

  void _handleBackNavigation() {
    if (_pageHistory.isNotEmpty) {
      final previous = _pageHistory.removeLast();
      setState(() => _pageIndex = previous);
      return;
    }
    if (_pageIndex != 0) {
      setState(() => _pageIndex = 0);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are already on the home dashboard.')),
    );
  }

  Future<void> _attachFile() async {
    if (_uploadingAttachment) return;
    try {
      final picked = await pickAttachment();
      if (picked == null) return;
      setState(() {
        _uploadingAttachment = true;
        _attachmentError = null;
      });
      final attachment = await _api.uploadAttachment(
        role: _role,
        userId: _selectedUser.userId,
        file: picked,
      );
      if (!mounted) return;
      setState(() {
        _apiOnline = true;
        _pendingAttachments = [..._pendingAttachments, attachment];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _apiOnline = false;
        _attachmentError = 'Could not upload file. ${error.toString()}';
      });
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  void _removePendingAttachment(String id) {
    setState(() {
      _pendingAttachments = _pendingAttachments
          .where((attachment) => attachment.id != id)
          .toList();
    });
  }

  List<Map<String, String>> _conversationHistory() {
    return _messages
        .where(
          (message) =>
              message.intent != 'welcome' && message.intent != 'offline',
        )
        .toList()
        .reversed
        .take(10)
        .toList()
        .reversed
        .map(
          (message) => {
            'speaker': message.fromUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();
  }

  Future<void> _sendMessage([String? prompt]) async {
    final rawMessage = (prompt ?? _messageController.text).trim();
    final attachments = _pendingAttachments;
    final message = rawMessage.isEmpty && attachments.isNotEmpty
        ? 'Please review the uploaded file and tell me what I should focus on.'
        : rawMessage;
    if (message.isEmpty || _sending) return;
    final history = _conversationHistory();
    final attachmentIds = attachments.map((item) => item.id).toList();
    final attachmentNames = attachments.map((item) => item.filename).join(', ');
    final visibleUserMessage = attachmentNames.isEmpty
        ? message
        : '$message\n\nAttached: $attachmentNames';
    _messageController.clear();
    setState(() {
      _sending = true;
      _pendingAttachments = const [];
      _attachmentError = null;
      _messages = [
        ..._messages,
        ChatMessage(text: visibleUserMessage, fromUser: true),
      ];
    });
    _scrollChatToBottom();

    try {
      final response = await _api.chat(
        role: _role,
        userId: _selectedUser.userId,
        message: message,
        history: history,
        attachmentIds: attachmentIds,
      );
      if (!mounted) return;
      setState(() {
        _apiOnline = true;
        _suggestions = response.nextActions;
        _messages = [
          ..._messages,
          ChatMessage(
            text: response.answer,
            fromUser: false,
            blocked: response.blocked,
            intent: response.intent,
            confidence: response.confidence,
            sources: response.sources,
            nextActions: response.nextActions,
            modelMode: response.audit['model_mode'] as String?,
          ),
        ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiOnline = false;
        _messages = [
          ..._messages,
          const ChatMessage(
            text:
                'Eve could not complete that request. The backend may be offline, or the AI response may have taken too long. Please try again in a moment.',
            fromUser: false,
            blocked: true,
            intent: 'offline',
            confidence: 1,
          ),
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollChatToBottom();
      }
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _runEstimate() async {
    final jamb = int.tryParse(_jambController.text.trim()) ?? 0;
    setState(() => _estimating = true);
    try {
      final estimate = await _api.estimateAdmission(
        course: _courseController.text.trim(),
        jambScore: jamb,
        english: _english,
        mathematics: _mathematics,
        science: _science,
        fourthSubject: _fourthSubject,
      );
      if (!mounted) return;
      setState(() {
        _apiOnline = true;
        _estimate = estimate;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apiOnline = false;
        _estimate = null;
      });
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _startLearningSession(String courseCode, String? topic) async {
    if (_startingLearningSession) return;
    setState(() => _startingLearningSession = true);
    try {
      final session = await _api.startLearningSession(
        userId: _selectedUser.userId,
        courseCode: courseCode,
        topic: topic,
      );
      if (!mounted) return;
      if (session['found'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${session['message'] ?? 'Unable to start learning session.'}',
            ),
          ),
        );
        return;
      }
      _sessionAnswerController.clear();
      setState(() {
        _apiOnline = true;
        _learningSession = session;
      });
      _openPage(5);
    } catch (error) {
      if (!mounted) return;
      setState(() => _apiOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to start learning session: $error')),
      );
    } finally {
      if (mounted) setState(() => _startingLearningSession = false);
    }
  }

  Future<void> _submitLearningAnswer() async {
    final session = _learningSession;
    final answer = _sessionAnswerController.text.trim();
    if (session == null || answer.isEmpty || _submittingLearningAnswer) return;

    setState(() => _submittingLearningAnswer = true);
    try {
      final updated = await _api.submitLearningAnswer(
        sessionId: session['session_id'] as String,
        answer: answer,
      );
      if (!mounted) return;
      _sessionAnswerController.clear();
      setState(() {
        _apiOnline = true;
        _learningSession = updated;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _apiOnline = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit answer: $error')),
      );
    } finally {
      if (mounted) setState(() => _submittingLearningAnswer = false);
    }
  }

  void _showAccountSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => AccountSheet(
        users: _users,
        selectedUserId: _selectedUser.userId,
        onSelect: _switchAccount,
        onLogout: _logout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionStarted) {
      return LoginScreen(
        loading: _loadingUsers,
        online: _apiOnline,
        onStart: _startSession,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              leading: _pageIndex == 0
                  ? null
                  : IconButton(
                      onPressed: _handleBackNavigation,
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                    ),
              titleSpacing: 14,
              title: Row(
                children: [
                  Image.asset('assets/esui-logo.png', width: 36, height: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eve',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Edo State University Iyamho',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ApiDot(online: _apiOnline, loading: _loadingUsers),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _logout,
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: _showAccountSheet,
                  tooltip: 'Account',
                  icon: const Icon(Icons.person),
                ),
                const SizedBox(width: 10),
              ],
            ),
            body: wide
                ? Row(
                    children: [
                      EveRail(
                        selectedIndex: _pageIndex > 4 ? 2 : _pageIndex,
                        onSelect: _openPage,
                      ),
                      Expanded(child: _currentPage(wide)),
                    ],
                  )
                : _currentPage(wide),
            bottomNavigationBar: wide
                ? null
                : NavigationBar(
                    selectedIndex: _pageIndex > 4 ? 2 : _pageIndex,
                    onDestinationSelected: _openPage,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.chat_bubble_outline),
                        selectedIcon: Icon(Icons.chat_bubble),
                        label: 'Ask',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.apps_outlined),
                        selectedIcon: Icon(Icons.apps),
                        label: 'Tools',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.how_to_reg_outlined),
                        selectedIcon: Icon(Icons.how_to_reg),
                        label: 'Admission',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _currentPage(bool wide) {
    switch (_pageIndex) {
      case 1:
        return ChatPage(
          user: _selectedUser,
          role: _role,
          messages: _messages,
          suggestions: _suggestions,
          sending: _sending,
          controller: _messageController,
          scrollController: _chatScrollController,
          onSend: _sendMessage,
          onPrompt: _askEve,
          pendingAttachments: _pendingAttachments,
          uploadingAttachment: _uploadingAttachment,
          attachmentError: _attachmentError,
          onAttach: _attachFile,
          onRemoveAttachment: _removePendingAttachment,
        );
      case 2:
        return ToolsPage(
          api: _api,
          user: _selectedUser,
          role: _role,
          onPrompt: _askEve,
          onStartLearningSession: _startLearningSession,
          onOpenAdmission: () => _openPage(3),
          onOpenKnowledgeAdmin: () => _openPage(6),
          onOpenPeerNotes: () => _openPage(7),
          onOpenPeerReview: () => _openPage(8),
        );
      case 3:
        return AdmissionPage(
          courseController: _courseController,
          jambController: _jambController,
          english: _english,
          mathematics: _mathematics,
          science: _science,
          fourthSubject: _fourthSubject,
          estimate: _estimate,
          estimating: _estimating,
          onEnglishChanged: (value) => setState(() => _english = value),
          onMathematicsChanged: (value) => setState(() => _mathematics = value),
          onScienceChanged: (value) => setState(() => _science = value),
          onFourthSubjectChanged: (value) =>
              setState(() => _fourthSubject = value),
          onEstimate: _runEstimate,
          onAskEve: _askEve,
        );
      case 4:
        return ProfilePage(
          user: _selectedUser,
          online: _apiOnline,
          onSwitch: _showAccountSheet,
          onLogout: _logout,
          onAskSecurity: () => _askEve('How does Eve protect student privacy?'),
        );
      case 5:
        return LearningSessionPage(
          session: _learningSession,
          answerController: _sessionAnswerController,
          submitting: _submittingLearningAnswer,
          onSubmit: _submitLearningAnswer,
          onBack: () => _replacePage(2),
          onAskEve: _askEve,
        );
      case 6:
        return KnowledgeAdminPage(
          api: _api,
          user: _selectedUser,
          role: _role,
          onBack: () => _replacePage(2),
        );
      case 7:
        return StudentPeerNotesPage(
          api: _api,
          user: _selectedUser,
          onBack: () => _replacePage(2),
        );
      case 8:
        return PeerNoteReviewPage(
          api: _api,
          user: _selectedUser,
          role: _role,
          onBack: () => _replacePage(2),
        );
      default:
        return HomePage(
          api: _api,
          user: _selectedUser,
          role: _role,
          online: _apiOnline,
          onPrompt: _askEve,
          onNavigate: _openPage,
          onStartLearningSession: _startLearningSession,
          onOpenPeerNotes: () => _openPage(7),
        );
    }
  }
}

class AppColors {
  static const blue = Color(0xFF203B94);
  static const deepBlue = Color(0xFF162A6D);
  static const green = Color(0xFF79B900);
  static const gold = Color(0xFFE2A03F);
  static const ink = Color(0xFF162033);
  static const muted = Color(0xFF62708A);
  static const line = Color(0xFFE3E8F4);
  static const softBlue = Color(0xFFEFF4FF);
  static const surface = Color(0xFFF7F9FD);
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    required this.loading,
    required this.online,
    required this.onStart,
    super.key,
  });

  final bool loading;
  final bool online;
  final void Function(EveRole role, {String? userId}) onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  Image.asset('assets/esui-logo.png', width: 116, height: 116),
                  const SizedBox(height: 16),
                  Text(
                    'Eve',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ESUI intelligent academic companion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ApiPill(online: online, loading: loading),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth >= 920
                          ? (constraints.maxWidth - 36) / 4
                          : constraints.maxWidth >= 680
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: EntryCard(
                              icon: Icons.public,
                              title: 'Continue as Guest',
                              subtitle:
                                  'Admissions, programmes, fees, and requirements',
                              button: 'Enter',
                              onTap: () => onStart(EveRole.guest),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: EntryCard(
                              icon: Icons.school,
                              title: 'Student Login',
                              subtitle:
                                  'Academic support, timetable, practice, and payments',
                              button: 'Use demo',
                              onTap: () => onStart(EveRole.student),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: EntryCard(
                              icon: Icons.badge,
                              title: 'Lecturer Login',
                              subtitle:
                                  'Course analytics, weak topics, and assessments',
                              button: 'Use demo',
                              onTap: () => onStart(EveRole.lecturer),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: EntryCard(
                              icon: Icons.admin_panel_settings,
                              title: 'Admin Login',
                              subtitle:
                                  'School-wide knowledge, gaps, and source control',
                              button: 'Use demo',
                              onTap: () => onStart(EveRole.admin),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EntryCard extends StatelessWidget {
  const EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: icon),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.api,
    required this.user,
    required this.role,
    required this.online,
    required this.onPrompt,
    required this.onNavigate,
    required this.onStartLearningSession,
    required this.onOpenPeerNotes,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final EveRole role;
  final bool online;
  final ValueChanged<String> onPrompt;
  final ValueChanged<int> onNavigate;
  final void Function(String courseCode, String? topic) onStartLearningSession;
  final VoidCallback onOpenPeerNotes;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForRole(role);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WelcomePanel(
            user: user,
            role: role,
            online: online,
            onAsk: () => onNavigate(1),
          ),
          const SizedBox(height: 18),
          if (role == EveRole.student)
            StudentHomeDashboard(
              api: api,
              user: user,
              onPrompt: onPrompt,
              onNavigate: onNavigate,
              onStartLearningSession: onStartLearningSession,
              onOpenPeerNotes: onOpenPeerNotes,
            )
          else ...[
            Text(
              'Today',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ResponsiveWrap(
              children: actions
                  .map(
                    (action) => ActionTile(
                      icon: action.icon,
                      title: action.title,
                      subtitle: action.subtitle,
                      accent: action.accent,
                      onTap: action.prompt == null
                          ? () => onNavigate(action.pageIndex ?? 1)
                          : () => onPrompt(action.prompt!),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          AskBar(onTap: () => onNavigate(1)),
        ],
      ),
    );
  }

  List<HomeAction> _actionsForRole(EveRole role) {
    switch (role) {
      case EveRole.guest:
        return const [
          HomeAction(
            Icons.how_to_reg,
            'Admission readiness',
            'Estimate your preparation strength',
            AppColors.blue,
            pageIndex: 3,
          ),
          HomeAction(
            Icons.menu_book,
            'Programmes',
            'Browse admission guidance',
            AppColors.green,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.route,
            'Application roadmap',
            'Know the next steps',
            AppColors.gold,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.psychology,
            'Skill guide',
            'Prepare for your course',
            Color(0xFF6E5CC2),
            pageIndex: 2,
          ),
        ];
      case EveRole.student:
        return const [
          HomeAction(
            Icons.trending_up,
            'Academic pulse',
            'Weak courses and improvement plan',
            AppColors.blue,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.quiz,
            'Practice test',
            'Start from course cards',
            AppColors.green,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.calendar_month,
            'Plan my week',
            'Open weekly plan',
            AppColors.gold,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.payments,
            'Payments',
            'Open student workspace',
            Color(0xFF6E5CC2),
            pageIndex: 2,
          ),
        ];
      case EveRole.lecturer:
        return const [
          HomeAction(
            Icons.query_stats,
            'Course analytics',
            'Performance and weak topics',
            AppColors.blue,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.edit_note,
            'Question studio',
            'Use assigned-course tools',
            AppColors.green,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.lightbulb,
            'Teaching plan',
            'Review interventions',
            AppColors.gold,
            pageIndex: 2,
          ),
          HomeAction(
            Icons.verified_user,
            'Privacy scope',
            'Assigned-course access only',
            Color(0xFF6E5CC2),
            pageIndex: 2,
          ),
        ];
      case EveRole.admin:
        return const [
          HomeAction(
            Icons.manage_search,
            'Knowledge base',
            'Approve school-wide guidance',
            AppColors.blue,
            pageIndex: 6,
          ),
          HomeAction(
            Icons.psychology_alt,
            'Gap review',
            'Turn weak answers into entries',
            AppColors.green,
            pageIndex: 6,
          ),
          HomeAction(
            Icons.payments,
            'Payment links',
            'Review knowledge entries',
            AppColors.gold,
            pageIndex: 6,
          ),
          HomeAction(
            Icons.security,
            'Role scope',
            'Review audit controls',
            Color(0xFF6E5CC2),
            pageIndex: 6,
          ),
        ];
    }
  }
}

class StudentHomeDashboard extends StatefulWidget {
  const StudentHomeDashboard({
    required this.api,
    required this.user,
    required this.onPrompt,
    required this.onNavigate,
    required this.onStartLearningSession,
    required this.onOpenPeerNotes,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final ValueChanged<String> onPrompt;
  final ValueChanged<int> onNavigate;
  final void Function(String courseCode, String? topic) onStartLearningSession;
  final VoidCallback onOpenPeerNotes;

  @override
  State<StudentHomeDashboard> createState() => _StudentHomeDashboardState();
}

class _StudentHomeDashboardState extends State<StudentHomeDashboard> {
  late Future<_StudentHomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(StudentHomeDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.userId != widget.user.userId) {
      _future = _load();
    }
  }

  Future<_StudentHomeData> _load() async {
    final results = await Future.wait<Map<String, dynamic>>([
      widget.api.learningProfile(widget.user.userId),
      widget.api.studentPeerNotes(widget.user.userId),
    ]);
    return _StudentHomeData(
      learningPayload: results[0],
      notesPayload: results[1],
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentHomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoCard(
            icon: Icons.hourglass_empty,
            title: 'Loading your dashboard',
            subtitle: 'Personal progress',
            body:
                'Eve is gathering your progress, weak topics, learning history, and peer-note activity.',
          );
        }
        if (snapshot.hasError) {
          return InfoCard(
            icon: Icons.error_outline,
            title: 'Personal dashboard unavailable',
            subtitle: 'Try again',
            body: snapshot.error.toString(),
            actionLabel: 'Refresh',
            onTap: _refresh,
          );
        }
        final data = snapshot.data!;
        if (data.learningPayload['found'] != true) {
          return const InfoCard(
            icon: Icons.person_search,
            title: 'No student profile',
            subtitle: 'Demo account',
            body:
                'This student account does not have a linked learning profile.',
          );
        }
        final profile = data.learningPayload['profile'] as Map<String, dynamic>;
        final priority =
            profile['priority_course'] as Map<String, dynamic>? ?? const {};
        final progressHistory =
            (profile['progress_history'] as Map<String, dynamic>?) ?? const {};
        final weakTopics =
            ((profile['weak_topics'] as List<dynamic>?) ?? const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        final recentSessions =
            ((progressHistory['recent_sessions'] as List<dynamic>?) ?? const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        final ownNotes =
            ((data.notesPayload['own_notes'] as List<dynamic>?) ?? const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        final approvedNotes =
            ((data.notesPayload['approved_peer_notes'] as List<dynamic>?) ??
                    const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        final pendingNotes = ownNotes
            .where((note) => note['status'] == 'pending')
            .length;
        final approvedOwnNotes = ownNotes
            .where((note) => note['status'] == 'approved')
            .length;
        final gaps = ((priority['topic_gaps'] as List<dynamic>?) ?? const [])
            .cast<String>();
        final priorityCourse = '${priority['course_code'] ?? ''}';
        final priorityTopic = gaps.isNotEmpty ? gaps.first : null;
        final latestSession = recentSessions.isNotEmpty
            ? recentSessions.first
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: '${widget.user.name.split(' ').first}\'s dashboard',
              trailing: 'Personalized',
            ),
            const SizedBox(height: 10),
            StudentFocusCard(
              priority: priority,
              topic: priorityTopic,
              onStart: priorityCourse.isEmpty
                  ? null
                  : () => widget.onStartLearningSession(
                      priorityCourse,
                      priorityTopic,
                    ),
              onOpenTools: () => widget.onNavigate(2),
            ),
            const SizedBox(height: 12),
            ResponsiveWrap(
              children: [
                MetricCard(
                  label: 'Overall progress',
                  value: '${profile['overall_progress']}%',
                  icon: Icons.show_chart,
                ),
                MetricCard(
                  label: 'CGPA',
                  value: '${profile['cgpa']}',
                  icon: Icons.school,
                ),
                MetricCard(
                  label: 'Weak topics',
                  value: '${profile['weak_topic_count']}',
                  icon: Icons.warning_amber,
                ),
                MetricCard(
                  label: 'Quiz average',
                  value: '${progressHistory['average_session_score'] ?? 0}%',
                  icon: Icons.insights,
                ),
                MetricCard(
                  label: 'Peer notes',
                  value: '$approvedOwnNotes/${ownNotes.length}',
                  icon: Icons.library_books,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Immediate actions',
              trailing: 'Your next steps',
            ),
            const SizedBox(height: 10),
            ResponsiveWrap(
              children: [
                ActionTile(
                  icon: Icons.play_circle,
                  title: 'Start recommended session',
                  subtitle: priorityCourse.isEmpty
                      ? 'Open learning tools'
                      : priorityCourse,
                  accent: AppColors.blue,
                  onTap: priorityCourse.isEmpty
                      ? () => widget.onNavigate(2)
                      : () => widget.onStartLearningSession(
                          priorityCourse,
                          priorityTopic,
                        ),
                ),
                ActionTile(
                  icon: Icons.quiz,
                  title: 'Generate practice',
                  subtitle: priorityCourse.isEmpty
                      ? 'Use your registered courses'
                      : 'Mock test for $priorityCourse',
                  accent: AppColors.green,
                  onTap: () => widget.onPrompt(
                    priorityCourse.isEmpty
                        ? 'Generate a mock test for one of my registered courses.'
                        : 'Generate a mock test for $priorityCourse${priorityTopic == null ? '' : ' focusing on $priorityTopic'}.',
                  ),
                ),
                ActionTile(
                  icon: Icons.library_books,
                  title: 'Peer Notes',
                  subtitle: pendingNotes > 0
                      ? '$pendingNotes pending review'
                      : '${approvedNotes.length} approved classmate notes',
                  accent: AppColors.gold,
                  onTap: widget.onOpenPeerNotes,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionTitle(title: 'Weak topic watchlist', trailing: 'Private'),
            const SizedBox(height: 10),
            if (weakTopics.isEmpty)
              const InfoCard(
                icon: Icons.check_circle_outline,
                title: 'No urgent weak topic',
                subtitle: 'Keep practising',
                body:
                    'Your current profile does not show an urgent topic gap. Keep using practice sessions to maintain momentum.',
              )
            else
              ResponsiveWrap(
                children: weakTopics
                    .take(4)
                    .map(
                      (item) => WeakTopicCard(
                        courseCode: '${item['course_code']}',
                        topic: '${item['topic']}',
                        onPractice: () => widget.onStartLearningSession(
                          '${item['course_code']}',
                          '${item['topic']}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 18),
            SectionTitle(title: 'Recent progress', trailing: 'Saved sessions'),
            const SizedBox(height: 10),
            if (latestSession == null)
              const InfoCard(
                icon: Icons.history,
                title: 'No saved session yet',
                subtitle: 'Start today',
                body:
                    'After you complete an Eve learning session, your latest score and topic will appear here.',
              )
            else
              StudentRecentSessionCard(session: latestSession),
          ],
        );
      },
    );
  }
}

class _StudentHomeData {
  const _StudentHomeData({
    required this.learningPayload,
    required this.notesPayload,
  });

  final Map<String, dynamic> learningPayload;
  final Map<String, dynamic> notesPayload;
}

class StudentFocusCard extends StatelessWidget {
  const StudentFocusCard({
    required this.priority,
    required this.topic,
    required this.onOpenTools,
    this.onStart,
    super.key,
  });

  final Map<String, dynamic> priority;
  final String? topic;
  final VoidCallback? onStart;
  final VoidCallback onOpenTools;

  @override
  Widget build(BuildContext context) {
    final progress = ((priority['progress'] as num?) ?? 0).toDouble();
    final courseCode = '${priority['course_code'] ?? 'Course'}';
    final title = '${priority['title'] ?? 'Recommended learning session'}';
    final nextActivity =
        '${priority['next_activity'] ?? 'Open your learning tools to continue.'}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(icon: Icons.flag, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Focus',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '$courseCode - $title',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progress.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress <= 0 ? null : progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text(nextActivity, style: const TextStyle(height: 1.4)),
            if (topic != null) ...[
              const SizedBox(height: 6),
              Text(
                'Weak topic: $topic',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start now'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenTools,
                  icon: const Icon(Icons.apps),
                  label: const Text('Open tools'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WeakTopicCard extends StatelessWidget {
  const WeakTopicCard({
    required this.courseCode,
    required this.topic,
    required this.onPractice,
    super.key,
  });

  final String courseCode;
  final String topic;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      icon: Icons.bolt,
      title: courseCode,
      subtitle: topic,
      body:
          'This topic is part of your private weak-topic profile. Practise it before moving to broader revision.',
      actionLabel: 'Practise',
      onTap: onPractice,
    );
  }
}

class StudentRecentSessionCard extends StatelessWidget {
  const StudentRecentSessionCard({required this.session, super.key});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final score = ((session['average_score'] as num?) ?? 0).round();
    final color = score >= 70
        ? AppColors.green
        : score >= 50
        ? AppColors.gold
        : const Color(0xFFB73535);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(icon: Icons.history, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session['course_code']} - ${session['topic']}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session['answered_count']}/${session['total_questions']} questions answered',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Text(
              '$score%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeAction {
  const HomeAction(
    this.icon,
    this.title,
    this.subtitle,
    this.accent, {
    this.prompt,
    this.pageIndex,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? prompt;
  final int? pageIndex;
}

class WelcomePanel extends StatelessWidget {
  const WelcomePanel({
    required this.user,
    required this.role,
    required this.online,
    required this.onAsk,
    super.key,
  });

  final EveUser user;
  final EveRole role;
  final bool online;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final name = role == EveRole.guest ? 'there' : user.name.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_greeting()}, $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ApiPill(online: online, loading: false, dark: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _headline(role),
            style: const TextStyle(
              color: Color(0xFFEAF0FF),
              height: 1.45,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAsk,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Ask Eve'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _headline(EveRole role) {
    switch (role) {
      case EveRole.guest:
        return 'Find verified ESUI admission guidance, programme information, and preparation advice.';
      case EveRole.student:
        return 'Stay ahead of your courses with academic guidance, practice, planning, and private progress support.';
      case EveRole.lecturer:
        return 'Review assigned-course insight, assessment ideas, and teaching interventions from one workspace.';
      case EveRole.admin:
        return 'Govern Eve knowledge, review gaps, and keep official student guidance ready for safe use.';
    }
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({
    required this.user,
    required this.role,
    required this.messages,
    required this.suggestions,
    required this.sending,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.onPrompt,
    required this.pendingAttachments,
    required this.uploadingAttachment,
    required this.attachmentError,
    required this.onAttach,
    required this.onRemoveAttachment,
    super.key,
  });

  final EveUser user;
  final EveRole role;
  final List<ChatMessage> messages;
  final List<String> suggestions;
  final bool sending;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final ValueChanged<String> onPrompt;
  final List<EveAttachment> pendingAttachments;
  final bool uploadingAttachment;
  final String? attachmentError;
  final VoidCallback onAttach;
  final ValueChanged<String> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatHeader(user: user, role: role),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                EveBubble(message: messages[index]),
          ),
        ),
        if (suggestions.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: Text(suggestions[index]),
                onPressed: () => onPrompt(suggestions[index]),
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: suggestions.length,
            ),
          ),
        ChatComposer(
          controller: controller,
          sending: sending,
          pendingAttachments: pendingAttachments,
          uploadingAttachment: uploadingAttachment,
          attachmentError: attachmentError,
          onSend: onSend,
          onAttach: onAttach,
          onRemoveAttachment: onRemoveAttachment,
        ),
      ],
    );
  }
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({required this.user, required this.role, super.key});

  final EveUser user;
  final EveRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const IconBadge(icon: Icons.auto_awesome, small: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask Eve',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${role.label} academic assistant - ${user.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.sending,
    required this.pendingAttachments,
    required this.uploadingAttachment,
    required this.attachmentError,
    required this.onSend,
    required this.onAttach,
    required this.onRemoveAttachment,
    super.key,
  });

  final TextEditingController controller;
  final bool sending;
  final List<EveAttachment> pendingAttachments;
  final bool uploadingAttachment;
  final String? attachmentError;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingAttachments.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pendingAttachments
                  .map(
                    (attachment) => InputChip(
                      avatar: Icon(
                        _attachmentIcon(attachment.kind),
                        size: 18,
                        color: AppColors.blue,
                      ),
                      label: Text(
                        '${attachment.filename} (${_formatBytes(attachment.size)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () => onRemoveAttachment(attachment.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (attachmentError != null) ...[
            Text(
              attachmentError!,
              style: const TextStyle(color: Color(0xFFB73535), fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Tooltip(
                message: 'Upload note, image, PDF, or document',
                child: IconButton.filledTonal(
                  onPressed: uploadingAttachment || sending ? null : onAttach,
                  icon: uploadingAttachment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText:
                        'Ask about school, courses, progress, or an uploaded file...',
                    prefixIcon: Icon(Icons.auto_awesome),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(54, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _attachmentIcon(String kind) {
    switch (kind) {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.notes_outlined;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EveBubble extends StatelessWidget {
  const EveBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              message.text,
              style: const TextStyle(color: Colors.white, height: 1.46),
            ),
          ),
        ),
      );
    }

    final answer = message.blocked
        ? Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE6B8B8)),
            ),
            child: MarkdownText(data: message.text, color: AppColors.ink),
          )
        : MarkdownText(data: message.text, color: AppColors.ink);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(icon: Icons.auto_awesome, small: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    answer,
                    if (message.sources.isNotEmpty || message.modelMode != null)
                      _AssistantDetails(message: message),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantDetails extends StatelessWidget {
  const _AssistantDetails({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Reference notes',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          children: [
            if (message.modelMode != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode: ${message.modelMode}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final source in message.sources)
                SourceDetail(source: source),
            ],
          ],
        ),
      ),
    );
  }
}

class SourceDetail extends StatelessWidget {
  const SourceDetail({required this.source, super.key});

  final EveSource source;

  @override
  Widget build(BuildContext context) {
    final updated = source.updated == null
        ? ''
        : ' • updated ${source.updated}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            source.sourceLabel == 'Live ESUI Website'
                ? Icons.public
                : Icons.verified_outlined,
            size: 15,
            color: source.sourceLabel == 'Live ESUI Website'
                ? AppColors.gold
                : AppColors.green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                Text(
                  '${source.sourceLabel} • ${source.category}$updated',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MarkdownText extends StatelessWidget {
  const MarkdownText({required this.data, required this.color, super.key});

  final String data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: color, height: 1.46) ??
        TextStyle(color: color, height: 1.46);
    final blocks = _buildBlocks(context, baseStyle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          blocks[index],
          if (index != blocks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<Widget> _buildBlocks(BuildContext context, TextStyle baseStyle) {
    final lines = data.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];
    final paragraph = <String>[];
    final codeLines = <String>[];
    var inCodeBlock = false;

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_richText(paragraph.join('\n'), baseStyle));
      paragraph.clear();
    }

    void flushCodeBlock() {
      blocks.add(_codeBlock(codeLines.join('\n'), baseStyle));
      codeLines.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          inCodeBlock = false;
          flushCodeBlock();
        } else {
          flushParagraph();
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeLines.add(line);
        continue;
      }

      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        final level = heading.group(1)!.length;
        final text = heading.group(2)!;
        final size = switch (level) {
          1 => 18.0,
          2 => 16.0,
          _ => 15.0,
        };
        blocks.add(
          _richText(
            text,
            baseStyle.copyWith(
              fontSize: size,
              fontWeight: FontWeight.w900,
              height: 1.28,
            ),
          ),
        );
        continue;
      }

      final bullet = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
      if (bullet != null) {
        flushParagraph();
        blocks.add(_listItem(context, bullet.group(1)!, baseStyle));
        continue;
      }

      final numbered = RegExp(r'^(\d+)[.)]\s+(.+)$').firstMatch(trimmed);
      if (numbered != null) {
        flushParagraph();
        blocks.add(
          _listItem(
            context,
            numbered.group(2)!,
            baseStyle,
            marker: '${numbered.group(1)}.',
          ),
        );
        continue;
      }

      paragraph.add(line);
    }

    if (inCodeBlock) flushCodeBlock();
    flushParagraph();
    return blocks.isEmpty ? [_richText(data, baseStyle)] : blocks;
  }

  Widget _richText(String text, TextStyle style) {
    return SelectableText.rich(
      TextSpan(style: style, children: _inlineSpans(text, style)),
    );
  }

  Widget _listItem(
    BuildContext context,
    String text,
    TextStyle baseStyle, {
    String? marker,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: marker == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : Text(
                  marker,
                  style: baseStyle.copyWith(fontWeight: FontWeight.w800),
                ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _richText(text, baseStyle)),
      ],
    );
  }

  Widget _codeBlock(String text, TextStyle baseStyle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: SelectableText(
        text.trimRight(),
        style: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(`[^`]+`|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\))');
    var cursor = 0;

    void addPlain(String value) {
      if (value.isNotEmpty) spans.add(TextSpan(text: value));
    }

    for (final match in pattern.allMatches(text)) {
      addPlain(text.substring(cursor, match.start));
      final token = match.group(0)!;
      if (token.startsWith('`')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: AppColors.ink.withValues(alpha: 0.08),
            ),
          ),
        );
      } else if (token.startsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: baseStyle.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      } else {
        final label =
            RegExp(r'^\[([^\]]+)\]\([^)]+\)$').firstMatch(token)?.group(1) ??
            token;
        spans.add(
          TextSpan(
            text: label,
            style: baseStyle.copyWith(
              color: color == Colors.white ? Colors.white : AppColors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
      cursor = match.end;
    }
    addPlain(text.substring(cursor));
    return spans;
  }
}

class ToolsPage extends StatelessWidget {
  const ToolsPage({
    required this.api,
    required this.user,
    required this.role,
    required this.onPrompt,
    required this.onStartLearningSession,
    required this.onOpenAdmission,
    required this.onOpenKnowledgeAdmin,
    required this.onOpenPeerNotes,
    required this.onOpenPeerReview,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final EveRole role;
  final ValueChanged<String> onPrompt;
  final void Function(String courseCode, String? topic) onStartLearningSession;
  final VoidCallback onOpenAdmission;
  final VoidCallback onOpenKnowledgeAdmin;
  final VoidCallback onOpenPeerNotes;
  final VoidCallback onOpenPeerReview;

  @override
  Widget build(BuildContext context) {
    if (role == EveRole.student) {
      return StudentTools(
        api: api,
        user: user,
        onPrompt: onPrompt,
        onStartLearningSession: onStartLearningSession,
        onOpenPeerNotes: onOpenPeerNotes,
      );
    }
    if (role == EveRole.lecturer) {
      return LecturerTools(
        api: api,
        user: user,
        onPrompt: onPrompt,
        onOpenKnowledgeAdmin: onOpenKnowledgeAdmin,
        onOpenPeerReview: onOpenPeerReview,
      );
    }
    if (role == EveRole.admin) {
      return AdminTools(
        user: user,
        onPrompt: onPrompt,
        onOpenKnowledgeAdmin: onOpenKnowledgeAdmin,
        onOpenPeerReview: onOpenPeerReview,
      );
    }
    return GuestTools(onPrompt: onPrompt, onOpenAdmission: onOpenAdmission);
  }
}

class GuestTools extends StatelessWidget {
  const GuestTools({
    required this.onPrompt,
    required this.onOpenAdmission,
    super.key,
  });

  final ValueChanged<String> onPrompt;
  final VoidCallback onOpenAdmission;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Admissions Guide',
      subtitle: 'Explore ESUI before asking Eve for details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveWrap(
            children: [
              ActionTile(
                icon: Icons.how_to_reg,
                title: 'Readiness estimator',
                subtitle: 'Check JAMB and O-Level preparation',
                accent: AppColors.blue,
                onTap: onOpenAdmission,
              ),
              InfoCard(
                icon: Icons.route,
                title: 'Application roadmap',
                subtitle: 'Guest guidance',
                body:
                    'Start by checking programme requirements, prepare documents, complete the official ESUI application process, and confirm admission updates only through approved university channels.',
                actionLabel: 'Ask Eve',
                onTap: () => onPrompt(
                  'Give me a simple ESUI undergraduate admission roadmap.',
                ),
              ),
              InfoCard(
                icon: Icons.school,
                title: 'Programme requirements',
                subtitle: 'Department search',
                body:
                    'Guests can review broad admission guidance and ask Eve for a specific department, such as Computer Science, Accounting, Nursing, or Law.',
                actionLabel: 'Check course',
                onTap: () => onPrompt(
                  'What are the requirements for Computer Science admission?',
                ),
              ),
              InfoCard(
                icon: Icons.psychology,
                title: 'Preparation guide',
                subtitle: 'Before admission',
                body:
                    'Eve can help prospective students prepare with subject focus, study habits, digital skills, and course-readiness advice before admission.',
                actionLabel: 'Get guide',
                onTap: () => onPrompt(
                  'What skills should I strengthen before studying Computer Science?',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const InfoCard(
            icon: Icons.verified_user,
            title: 'Guest mode',
            subtitle: 'Public information only',
            body:
                'Guest users can browse public admission and school guidance. Personal student records are available only after a verified student login in a production deployment.',
          ),
        ],
      ),
    );
  }
}

class StudentTools extends StatelessWidget {
  const StudentTools({
    required this.api,
    required this.user,
    required this.onPrompt,
    required this.onStartLearningSession,
    required this.onOpenPeerNotes,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final ValueChanged<String> onPrompt;
  final void Function(String courseCode, String? topic) onStartLearningSession;
  final VoidCallback onOpenPeerNotes;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.learningProfile(user.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return OfflineState(error: snapshot.error.toString());
          }
          return const Center(child: CircularProgressIndicator());
        }
        final payload = snapshot.data!;
        if (payload['found'] != true) {
          return const EmptyState(
            title: 'No learning profile',
            message: 'This demo account has no linked learning profile.',
          );
        }
        final profile = payload['profile'] as Map<String, dynamic>;
        final courses = (profile['courses'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        final weeklyPlan = (profile['weekly_plan'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        final milestones = (profile['milestones'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        final progressHistory =
            (profile['progress_history'] as Map<String, dynamic>?) ?? const {};
        final recentSessions =
            ((progressHistory['recent_sessions'] as List<dynamic>?) ?? const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        final priority = profile['priority_course'] as Map<String, dynamic>;
        return PageShell(
          title: 'Learning Progress',
          subtitle: '${profile['department']} - ${profile['level']}L',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveWrap(
                children: [
                  MetricCard(
                    label: 'Overall progress',
                    value: '${profile['overall_progress']}%',
                    icon: Icons.show_chart,
                  ),
                  MetricCard(
                    label: 'Learning status',
                    value: '${profile['learning_status']}',
                    icon: Icons.psychology_alt,
                  ),
                  MetricCard(
                    label: 'Weak topics',
                    value: '${profile['weak_topic_count']}',
                    icon: Icons.warning_amber,
                  ),
                  MetricCard(
                    label: 'Completed sessions',
                    value:
                        '${progressHistory['completed_sessions'] ?? 0}/${progressHistory['total_sessions'] ?? 0}',
                    icon: Icons.fact_check,
                  ),
                  MetricCard(
                    label: 'Quiz average',
                    value: '${progressHistory['average_session_score'] ?? 0}%',
                    icon: Icons.insights,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              InfoCard(
                icon: Icons.auto_awesome,
                title: 'Recommended next session',
                subtitle: '${priority['course_code']} - ${priority['title']}',
                body: '${priority['next_activity']}',
                actionLabel: 'Start with Eve',
                onTap: () => onStartLearningSession(
                  priority['course_code'] as String,
                  ((priority['topic_gaps'] as List<dynamic>?)
                              ?.cast<String>()
                              .isNotEmpty ??
                          false)
                      ? (priority['topic_gaps'] as List<dynamic>).first
                            as String
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              const InfoCard(
                icon: Icons.lock_person,
                title: 'Private student workspace',
                subtitle: 'Your input stays personal',
                body:
                    'Practice answers, weak topics, and learning-session scores are saved to this student dashboard for progress tracking. They do not publish school-wide knowledge. Official school information is managed separately through admin-reviewed knowledge entries.',
              ),
              const SizedBox(height: 18),
              ResponsiveWrap(
                children: [
                  ActionTile(
                    icon: Icons.library_books,
                    title: 'Peer Notes',
                    subtitle:
                        'Submit how you understand a course for lecturer/admin review',
                    accent: AppColors.green,
                    onTap: onOpenPeerNotes,
                  ),
                  const InfoCard(
                    icon: Icons.verified_user,
                    title: 'Moderated sharing',
                    subtitle: 'Not published immediately',
                    body:
                        'Student notes stay pending until a reviewer approves them. Approved notes can help classmates study, but they are labeled as peer learning support, not official school policy.',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionTitle(title: 'Recent learning history', trailing: 'Saved'),
              const SizedBox(height: 10),
              if (recentSessions.isEmpty)
                const InfoCard(
                  icon: Icons.history,
                  title: 'No saved sessions yet',
                  subtitle: 'Start a session',
                  body:
                      'Your completed learning sessions and quiz scores will appear here.',
                )
              else
                ResponsiveWrap(
                  children: recentSessions
                      .map(
                        (session) => SessionHistoryCard(
                          session: session,
                          onPrompt: onPrompt,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              SectionTitle(title: 'Course progress', trailing: 'Personalized'),
              const SizedBox(height: 10),
              ResponsiveWrap(
                children: courses
                    .map(
                      (course) => CourseProgressCard(
                        course: course,
                        onPrompt: onPrompt,
                        onStartLearningSession: onStartLearningSession,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'This week\'s learning plan',
                trailing: 'Trackable',
              ),
              const SizedBox(height: 10),
              ResponsiveWrap(
                children: weeklyPlan
                    .map(
                      (item) => InfoCard(
                        icon: Icons.calendar_month,
                        title: '${item['day']} - ${item['course_code']}',
                        subtitle: '${item['duration_minutes']} minutes',
                        body: '${item['task']}',
                        actionLabel: 'Do this now',
                        onTap: () => onStartLearningSession(
                          item['course_code'] as String,
                          item['focus'] as String?,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              SectionTitle(title: 'Progress milestones', trailing: 'Roadmap'),
              const SizedBox(height: 10),
              ResponsiveWrap(
                children: milestones
                    .map(
                      (item) => InfoCard(
                        icon: Icons.flag_outlined,
                        title: '${item['title']}',
                        subtitle: '${item['status']}',
                        body: '${item['target']}',
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    required this.course,
    required this.onPrompt,
    required this.onStartLearningSession,
    super.key,
  });

  final Map<String, dynamic> course;
  final ValueChanged<String> onPrompt;
  final void Function(String courseCode, String? topic) onStartLearningSession;

  @override
  Widget build(BuildContext context) {
    final progress = (course['progress'] as num).toDouble();
    final risk = course['risk'] as String;
    final gaps = (course['topic_gaps'] as List<dynamic>).cast<String>();
    final accent = switch (risk) {
      'high' => const Color(0xFFB73535),
      'medium' => AppColors.gold,
      _ => AppColors.green,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.menu_book, color: accent, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course['course_code']}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${course['title']}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progress.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${course['status']} - CA ${course['ca']}%',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              'Sessions: ${course['completed_sessions']}/${course['session_count']} completed - Quiz avg ${course['average_session_score']}%',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            if (course['last_studied_topic'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last topic: ${course['last_studied_topic']} (${course['last_session_score']}%)',
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              gaps.isEmpty
                  ? 'Focus: maintain practice momentum'
                  : 'Focus: ${gaps.join(', ')}',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onStartLearningSession(
                course['course_code'] as String,
                gaps.isNotEmpty ? gaps.first : null,
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start session'),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionHistoryCard extends StatelessWidget {
  const SessionHistoryCard({
    required this.session,
    required this.onPrompt,
    super.key,
  });

  final Map<String, dynamic> session;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final score = ((session['average_score'] as num?) ?? 0).round();
    final completed = session['completed'] == true;
    final answered = session['answered_count'] ?? 0;
    final total = session['total_questions'] ?? 0;
    final color = score >= 75
        ? AppColors.green
        : score >= 55
        ? AppColors.gold
        : const Color(0xFFB73535);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(
                  icon: completed ? Icons.task_alt : Icons.pending_actions,
                  color: completed ? AppColors.green : AppColors.gold,
                  small: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${session['course_code']} - ${session['topic']}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        completed ? 'Completed' : 'In progress',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0
                  ? 0
                  : (answered as num).toDouble() / (total as num).toDouble(),
              minHeight: 8,
              color: completed ? AppColors.green : AppColors.gold,
              backgroundColor: AppColors.line,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(
              'Answered $answered of $total questions',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onPrompt(
                'Review my ${session['course_code']} session on ${session['topic']} and recommend my next study step.',
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Review with Eve'),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningSessionPage extends StatelessWidget {
  const LearningSessionPage({
    required this.session,
    required this.answerController,
    required this.submitting,
    required this.onSubmit,
    required this.onBack,
    required this.onAskEve,
    super.key,
  });

  final Map<String, dynamic>? session;
  final TextEditingController answerController;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final ValueChanged<String> onAskEve;

  @override
  Widget build(BuildContext context) {
    final data = session;
    if (data == null || data['found'] != true) {
      return PageShell(
        title: 'Learning Session',
        subtitle: 'No active session',
        child: InfoCard(
          icon: Icons.play_lesson_outlined,
          title: 'Start from Tools',
          subtitle: 'Personalized learning',
          body:
              'Open Tools and choose a course to begin a guided learning session.',
          actionLabel: 'Back to Tools',
          onTap: onBack,
        ),
      );
    }

    final history = (data['history'] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
    final completed = data['completed'] == true;
    final summary = data['summary'] as Map<String, dynamic>?;

    return PageShell(
      title: '${data['course_code']} Learning Session',
      subtitle:
          '${data['topic']} - ${data['current_question_index']}/${data['total_questions']}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Tools'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => onAskEve(
                  'Explain ${data['topic']} in ${data['course_code']} with simpler examples.',
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Ask Eve'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResponsiveWrap(
            children: [
              InfoCard(
                icon: Icons.lightbulb_outline,
                title: 'Concept explanation',
                subtitle: '${data['course_title']}',
                body: '${data['explanation']}',
              ),
              InfoCard(
                icon: Icons.science_outlined,
                title: 'Worked example',
                subtitle: 'Connect the idea',
                body: '${data['example']}',
              ),
              MetricCard(
                label: 'Average score',
                value: '${data['average_score']}%',
                icon: Icons.speed,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!completed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Practice question',
                      trailing: 'Answer in your words',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${data['question']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Type your answer here...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: submitting ? null : onSubmit,
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Submit answer'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            InfoCard(
              icon: Icons.emoji_events_outlined,
              title: 'Session complete',
              subtitle:
                  'Average score: ${summary?['average_score'] ?? data['average_score']}%',
              body:
                  '${summary?['next_step'] ?? 'Review your feedback and continue practising.'}',
              actionLabel: 'Start chat follow-up',
              onTap: () => onAskEve(
                'Review my ${data['course_code']} learning session on ${data['topic']} and tell me what to do next.',
              ),
            ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Feedback history',
            trailing: '${history.length} answered',
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const InfoCard(
              icon: Icons.history,
              title: 'No answers yet',
              subtitle: 'Progress tracking',
              body: 'Submit your first answer to receive a score and feedback.',
            )
          else
            Column(
              children: history
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FeedbackCard(item: item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({required this.item, super.key});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final score = item['score'] as int;
    final color = score >= 75
        ? AppColors.green
        : score >= 55
        ? AppColors.gold
        : const Color(0xFFB73535);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.grading, color: color, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${item['question']}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Your answer: ${item['answer']}',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              'Feedback: ${item['feedback']}',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTools extends StatelessWidget {
  const AdminTools({
    required this.user,
    required this.onPrompt,
    required this.onOpenKnowledgeAdmin,
    required this.onOpenPeerReview,
    super.key,
  });

  final EveUser user;
  final ValueChanged<String> onPrompt;
  final VoidCallback onOpenKnowledgeAdmin;
  final VoidCallback onOpenPeerReview;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Admin Workbench',
      subtitle: user.department ?? 'School-wide governance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveWrap(
            children: [
              ActionTile(
                icon: Icons.manage_search,
                title: 'Knowledge base',
                subtitle: 'Approve and publish school-wide information',
                accent: AppColors.blue,
                onTap: onOpenKnowledgeAdmin,
              ),
              ActionTile(
                icon: Icons.psychology_alt,
                title: 'Gap review',
                subtitle: 'Convert unanswered questions into reviewed entries',
                accent: AppColors.green,
                onTap: onOpenKnowledgeAdmin,
              ),
              ActionTile(
                icon: Icons.payments,
                title: 'Payment guidance',
                subtitle: 'Check official links before students use them',
                accent: AppColors.gold,
                onTap: () => onPrompt(
                  'Audit Eve payment guidance and official ESUI links.',
                ),
              ),
              ActionTile(
                icon: Icons.rate_review,
                title: 'Peer note review',
                subtitle: 'Approve or return student learning notes',
                accent: AppColors.green,
                onTap: onOpenPeerReview,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(title: 'Access model', trailing: 'Admin scope'),
          const SizedBox(height: 10),
          ResponsiveWrap(
            children: [
              const InfoCard(
                icon: Icons.admin_panel_settings,
                title: 'School affairs',
                subtitle: 'Admin-controlled',
                body:
                    'Admissions, fees, portals, hostel guidance, calendars, student affairs, and payment links are managed from this account.',
              ),
              const InfoCard(
                icon: Icons.badge,
                title: 'Course material',
                subtitle: 'Lecturer-controlled',
                body:
                    'Lecturers can maintain learning entries only when the entry is tied to one of their assigned course codes.',
              ),
              InfoCard(
                icon: Icons.security,
                title: 'Audit trail',
                subtitle: 'Defense-ready rule',
                body:
                    'Every knowledge write sends the acting role and account ID to the backend before Eve saves it.',
                actionLabel: 'Ask Eve',
                onTap: () => onPrompt(
                  'Explain Eve knowledge permissions for admins and lecturers.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LecturerTools extends StatelessWidget {
  const LecturerTools({
    required this.api,
    required this.user,
    required this.onPrompt,
    required this.onOpenKnowledgeAdmin,
    required this.onOpenPeerReview,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final ValueChanged<String> onPrompt;
  final VoidCallback onOpenKnowledgeAdmin;
  final VoidCallback onOpenPeerReview;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.lecturerInsights(user.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return OfflineState(error: snapshot.error.toString());
          }
          return const Center(child: CircularProgressIndicator());
        }
        final payload = snapshot.data!;
        if (payload['found'] != true) {
          return const EmptyState(
            title: 'No lecturer profile',
            message: 'This demo account has no linked analytics.',
          );
        }
        final profile = payload['profile'] as Map<String, dynamic>;
        final courses = (profile['assigned_courses'] as List<dynamic>)
            .cast<String>();
        final insights =
            (profile['learning_insights'] as Map<String, dynamic>?) ?? const {};
        final insightCourses =
            ((insights['courses'] as List<dynamic>?) ?? const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        return PageShell(
          title: 'Teaching Workbench',
          subtitle: '${profile['department']}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveWrap(
                children: [
                  MetricCard(
                    label: 'Assigned courses',
                    value: '${courses.length}',
                    icon: Icons.menu_book,
                  ),
                  MetricCard(
                    label: 'Tracked students',
                    value: '${insights['student_count'] ?? 0}',
                    icon: Icons.groups,
                  ),
                  MetricCard(
                    label: 'Completed sessions',
                    value: '${insights['completed_sessions'] ?? 0}',
                    icon: Icons.fact_check,
                  ),
                  MetricCard(
                    label: 'Quiz average',
                    value: '${insights['average_score'] ?? 0}%',
                    icon: Icons.insights,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Eve controls',
                trailing: 'Source governance',
              ),
              const SizedBox(height: 10),
              ResponsiveWrap(
                children: [
                  ActionTile(
                    icon: Icons.manage_search,
                    title: 'Course knowledge',
                    subtitle: 'Assigned-course entries only',
                    accent: AppColors.gold,
                    onTap: onOpenKnowledgeAdmin,
                  ),
                  ActionTile(
                    icon: Icons.rate_review,
                    title: 'Peer notes',
                    subtitle: 'Review student notes for your courses',
                    accent: AppColors.green,
                    onTap: onOpenPeerReview,
                  ),
                  InfoCard(
                    icon: Icons.policy,
                    title: 'Answer quality',
                    subtitle: 'Curated before live web',
                    body:
                        'Eve uses approved ESUI knowledge first, then clearly marks live website sources when they are needed.',
                    actionLabel: 'Ask Eve',
                    onTap: () => onPrompt(
                      'Explain how Eve verifies ESUI answers before responding to students.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Assigned-course learning trends',
                trailing: 'Saved sessions',
              ),
              const SizedBox(height: 10),
              ResponsiveWrap(
                children: insightCourses.isEmpty
                    ? courses
                          .map(
                            (course) =>
                                InfoCard(
                                      icon: Icons.query_stats,
                                      title: course,
                                      subtitle: 'Assigned course',
                                      body:
                                          'No saved Eve learning-session data is available yet.',
                                      actionLabel: 'Open insight',
                                      onTap: () => onPrompt(
                                        'Show lecturer analytics for $course and recommend interventions.',
                                      ),
                                    )
                                    as Widget,
                          )
                          .toList()
                    : insightCourses
                          .map(
                            (course) =>
                                LecturerCourseInsightCard(
                                      course: course,
                                      onPrompt: onPrompt,
                                    )
                                    as Widget,
                          )
                          .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class KnowledgeAdminPage extends StatefulWidget {
  const KnowledgeAdminPage({
    required this.api,
    required this.user,
    required this.role,
    required this.onBack,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final EveRole role;
  final VoidCallback onBack;

  @override
  State<KnowledgeAdminPage> createState() => _KnowledgeAdminPageState();
}

class _KnowledgeAdminPageState extends State<KnowledgeAdminPage> {
  static const List<String> _categoryOptions = [
    'admission',
    'fees',
    'portal',
    'learning',
    'planning',
    'calendar',
    'department',
    'institution',
    'governance',
    'security',
    'analytics',
    'career',
    'news',
  ];
  static const List<String> _audienceOptions = [
    'public',
    'guest',
    'student',
    'lecturer',
  ];
  static const List<String> _approvalStatusOptions = [
    'demo',
    'draft',
    'approved',
    'needs_review',
  ];
  static final RegExp _courseCodePattern = RegExp(r'\b[A-Z]{2,4}\s?\d{3}\b');

  final GlobalKey<FormState> _entryFormKey = GlobalKey<FormState>();
  final TextEditingController _entryIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();
  final TextEditingController _reviewNotesController = TextEditingController();
  final TextEditingController _librarySearchController =
      TextEditingController();
  final Set<String> _selectedAudiences = <String>{};

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _validation;
  List<Map<String, dynamic>> _knowledgeEntries = const [];
  List<Map<String, dynamic>> _knowledgeGaps = const [];
  List<Map<String, dynamic>> _auditEvents = const [];
  bool _loading = true;
  bool _reloading = false;
  bool _saving = false;
  String _selectedCategory = 'admission';
  String _approvalStatus = 'approved';
  String _libraryQuery = '';
  String _libraryAudienceFilter = 'all';
  String _libraryCategoryFilter = 'all';
  String _gapStatusFilter = 'open';
  String? _editingEntryId;
  String? _activeGapId;
  String? _busyEntryId;
  String? _busyGapId;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _defaultCategory;
    _approvalStatus = _defaultApprovalStatus;
    _selectedAudiences.addAll(_defaultAudiences);
    _load();
  }

  @override
  void dispose() {
    _entryIdController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _sourceUrlController.dispose();
    _reviewNotesController.dispose();
    _librarySearchController.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.role == EveRole.admin;
  bool get _isLecturer => widget.role == EveRole.lecturer;
  String get _actorUserId => widget.user.userId;
  String get _defaultCategory => _isLecturer ? 'learning' : 'admission';
  String get _defaultApprovalStatus => _isLecturer ? 'draft' : 'approved';
  Set<String> get _defaultAudiences =>
      _isLecturer ? {'lecturer'} : {'public', 'guest', 'student'};
  List<String> get _availableCategoryOptions =>
      _isLecturer ? const ['learning'] : _categoryOptions;
  List<String> get _availableAudienceOptions =>
      _isLecturer ? const ['lecturer'] : _audienceOptions;
  List<String> get _availableApprovalStatuses => _isLecturer
      ? const ['demo', 'draft', 'needs_review']
      : _approvalStatusOptions;
  String get _pageTitle => _isLecturer ? 'Course Knowledge' : 'Knowledge Base';
  String get _pageSubtitle => _isLecturer
      ? 'Assigned-course source control'
      : 'Curated ESUI source control';
  String get _entryScopeNote => _isLecturer
      ? 'Lecturer entries must stay in Learning and include one of the lecturer assigned course codes, such as CSC 201.'
      : 'Admins can manage school-wide knowledge such as admissions, fees, portals, calendars, hostel guidance, and student affairs.';

  Future<void> _load({bool clearMessage = true}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (clearMessage) _message = null;
    });
    try {
      final results = await Future.wait<Map<String, dynamic>>([
        widget.api.knowledgeStats(),
        widget.api.validateKnowledge(),
        widget.api.knowledgeEntries(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
        widget.api.knowledgeGaps(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
        widget.api.knowledgeAudit(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0];
        _validation = results[1];
        _knowledgeEntries = _entryList(results[2]['entries']);
        _knowledgeGaps = _entryList(results[3]['gaps']);
        _auditEvents = _entryList(results[4]['events']);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reload() async {
    setState(() {
      _reloading = true;
      _error = null;
      _message = null;
    });
    try {
      final reloadPayload = await widget.api.reloadKnowledge();
      final results = await Future.wait<Map<String, dynamic>>([
        widget.api.knowledgeStats(),
        widget.api.validateKnowledge(),
        widget.api.knowledgeEntries(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
        widget.api.knowledgeGaps(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
        widget.api.knowledgeAudit(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        ),
      ]);
      if (!mounted) return;
      final entryCount =
          reloadPayload['entry_count'] ?? results[0]['entry_count'] ?? 0;
      setState(() {
        _stats = results[0];
        _validation = results[1];
        _knowledgeEntries = _entryList(results[2]['entries']);
        _knowledgeGaps = _entryList(results[3]['gaps']);
        _auditEvents = _entryList(results[4]['events']);
        _message = 'Reloaded $entryCount curated knowledge entries.';
        _loading = false;
        _reloading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _reloading = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    final valid = _entryFormKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_selectedAudiences.isEmpty) {
      setState(() {
        _error = 'Choose at least one audience for this knowledge entry.';
        _message = null;
      });
      return;
    }
    if (_isLecturer && _selectedCategory != 'learning') {
      setState(() {
        _error = 'Lecturers can only save Learning entries for their courses.';
        _message = null;
      });
      return;
    }
    if (_isLecturer && !_draftContainsCourseCode()) {
      setState(() {
        _error =
            'Add an assigned course code such as CSC 201 to the title, tags, summary, or content before saving.';
        _message = null;
      });
      return;
    }

    final title = _titleController.text.trim();
    final convertingGapId = _activeGapId;
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final payload = _editingEntryId == null
          ? await widget.api.createKnowledgeEntry(
              _entryPayload(),
              actorRole: widget.role,
              actorUserId: _actorUserId,
            )
          : await widget.api.updateKnowledgeEntry(
              _editingEntryId!,
              _entryPayload(),
              actorRole: widget.role,
              actorUserId: _actorUserId,
            );
      if (!mounted) return;
      final action = _editingEntryId == null ? 'Saved' : 'Updated';
      Map<String, dynamic>? gapsPayload;
      Map<String, dynamic>? auditPayload;
      if (convertingGapId != null) {
        final savedEntry = _asMap(payload['entry']);
        await widget.api.updateKnowledgeGap(
          convertingGapId,
          {'status': 'converted', 'converted_entry_id': savedEntry['id']},
          actorRole: widget.role,
          actorUserId: _actorUserId,
        );
        gapsPayload = await widget.api.knowledgeGaps(
          actorRole: widget.role,
          actorUserId: _actorUserId,
        );
      }
      auditPayload = await widget.api.knowledgeAudit(
        actorRole: widget.role,
        actorUserId: _actorUserId,
      );
      if (!mounted) return;
      _clearEntryForm();
      setState(() {
        _stats = payload;
        _validation = _asMap(payload['validation']);
        _knowledgeEntries = _entryList(payload['entries']);
        if (gapsPayload != null) {
          _knowledgeGaps = _entryList(gapsPayload['gaps']);
        }
        if (auditPayload != null) {
          _auditEvents = _entryList(auditPayload['events']);
        }
        _message =
            '$action "$title" and reloaded Eve with the latest knowledge.';
        _saving = false;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _saving = false;
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _entryPayload() {
    final id = _entryIdController.text.trim();
    final sourceUrl = _sourceUrlController.text.trim();
    return {
      'id': id.isEmpty ? null : id,
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'audience': _selectedAudiences.toList()..sort(),
      'tags': _splitTags(_tagsController.text),
      'summary': _summaryController.text.trim(),
      'content': _contentController.text.trim(),
      'source_url': sourceUrl.isEmpty ? null : sourceUrl,
      'updated': _todayIso(),
      'approval_status': _approvalStatus,
      'review_notes': _reviewNotesController.text.trim(),
    };
  }

  bool _draftContainsCourseCode() {
    final text = [
      _titleController.text,
      _tagsController.text,
      _summaryController.text,
      _contentController.text,
    ].join(' ').toUpperCase();
    return _courseCodePattern.hasMatch(text);
  }

  List<String> _splitTags(String value) {
    return value
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String _todayIso() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _clearEntryForm() {
    _entryIdController.clear();
    _titleController.clear();
    _tagsController.clear();
    _summaryController.clear();
    _contentController.clear();
    _sourceUrlController.clear();
    _reviewNotesController.clear();
    _editingEntryId = null;
    _activeGapId = null;
    _selectedCategory = _defaultCategory;
    _approvalStatus = _defaultApprovalStatus;
    _selectedAudiences
      ..clear()
      ..addAll(_defaultAudiences);
    _entryFormKey.currentState?.reset();
  }

  String? _requiredMin(String? value, int minLength, String label) {
    final text = value?.trim() ?? '';
    if (text.length < minLength) {
      return '$label must be at least $minLength characters.';
    }
    return null;
  }

  String? _sourceUrlError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a complete URL.';
    }
    if (uri.scheme != 'https') {
      return 'Use an HTTPS source URL.';
    }
    return null;
  }

  List<String> get _categoryChoices {
    final categories = {
      ..._availableCategoryOptions,
      ..._knowledgeEntries
          .map((entry) => '${entry['category'] ?? ''}')
          .where(
            (category) =>
                category.isNotEmpty &&
                (!_isLecturer || _availableCategoryOptions.contains(category)),
          ),
      if (_selectedCategory.isNotEmpty) _selectedCategory,
    }.toList()..sort();
    return categories;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return const {};
  }

  List<Map<String, dynamic>> _issues(String key) {
    final value = _validation?[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  List<Map<String, dynamic>> _entryList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();
  }

  String _approvalStatusForEntry(Map<String, dynamic> entry) {
    final raw = '${entry['approval_status'] ?? ''}'.trim().toLowerCase();
    if (_approvalStatusOptions.contains(raw)) return raw;
    final tags = ((entry['tags'] as List<dynamic>?) ?? const [])
        .map((item) => '$item'.toLowerCase())
        .toSet();
    final id = '${entry['id'] ?? ''}'.toLowerCase();
    if (id.startsWith('demo-') || tags.contains('demo')) return 'demo';
    return 'approved';
  }

  String _statusLabel(String status) {
    if (status == 'needs_review') return 'Needs Review';
    return _titleCase(status);
  }

  List<Map<String, dynamic>> _filteredKnowledgeEntries() {
    final query = _libraryQuery.trim().toLowerCase();
    return _knowledgeEntries.where((entry) {
      final category = '${entry['category'] ?? ''}';
      final audience = ((entry['audience'] as List<dynamic>?) ?? const [])
          .map((item) => '$item')
          .toSet();
      if (_libraryCategoryFilter != 'all' &&
          category != _libraryCategoryFilter) {
        return false;
      }
      if (_libraryAudienceFilter != 'all' &&
          !audience.contains(_libraryAudienceFilter)) {
        return false;
      }
      if (query.isEmpty) return true;
      final tags = ((entry['tags'] as List<dynamic>?) ?? const []).join(' ');
      final haystack =
          '${entry['id']} ${entry['title']} ${entry['summary']} ${entry['content']} $category $tags'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _editKnowledgeEntry(Map<String, dynamic> entry) {
    final category = '${entry['category'] ?? 'admission'}';
    final audience = ((entry['audience'] as List<dynamic>?) ?? const [])
        .map((item) => '$item')
        .where((item) => item.isNotEmpty)
        .toSet();
    setState(() {
      _editingEntryId = '${entry['id'] ?? ''}';
      _entryIdController.text = _editingEntryId ?? '';
      _titleController.text = '${entry['title'] ?? ''}';
      _selectedCategory = category.isEmpty ? _defaultCategory : category;
      _tagsController.text = ((entry['tags'] as List<dynamic>?) ?? const [])
          .map((item) => '$item')
          .join(', ');
      _selectedAudiences
        ..clear()
        ..addAll(audience.isEmpty ? const {'public'} : audience);
      _summaryController.text = '${entry['summary'] ?? ''}';
      _contentController.text = '${entry['content'] ?? ''}';
      _sourceUrlController.text = '${entry['source_url'] ?? ''}';
      _approvalStatus = _approvalStatusForEntry(entry);
      _reviewNotesController.text = '${entry['review_notes'] ?? ''}';
      _error = null;
      _message = 'Editing ${entry['title'] ?? 'knowledge entry'}.';
    });
  }

  Future<void> _deleteKnowledgeEntry(Map<String, dynamic> entry) async {
    final entryId = '${entry['id'] ?? ''}';
    if (entryId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete knowledge entry'),
        content: Text(
          'Delete "${entry['title'] ?? entryId}" from Eve knowledge? This action removes the entry from the local curated file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB73535),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busyEntryId = entryId;
      _error = null;
      _message = null;
    });
    try {
      final payload = await widget.api.deleteKnowledgeEntry(
        entryId,
        actorRole: widget.role,
        actorUserId: _actorUserId,
      );
      if (!mounted) return;
      if (_editingEntryId == entryId) _clearEntryForm();
      final auditPayload = await widget.api.knowledgeAudit(
        actorRole: widget.role,
        actorUserId: _actorUserId,
      );
      if (!mounted) return;
      setState(() {
        _stats = payload;
        _validation = _asMap(payload['validation']);
        _knowledgeEntries = _entryList(payload['entries']);
        _auditEvents = _entryList(auditPayload['events']);
        _message = 'Deleted "${entry['title'] ?? entryId}" from Eve knowledge.';
        _busyEntryId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _busyEntryId = null;
      });
    }
  }

  void _showKnowledgeEntry(Map<String, dynamic> entry) {
    final tags = ((entry['tags'] as List<dynamic>?) ?? const []).join(', ');
    final audience = ((entry['audience'] as List<dynamic>?) ?? const []).join(
      ', ',
    );
    final source = '${entry['source_url'] ?? 'Curated internal knowledge'}';
    final status = _approvalStatusForEntry(entry);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry['title'] ?? 'Knowledge entry'}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: SelectableText(
              'ID: ${entry['id']}\n'
              'Category: ${_titleCase('${entry['category'] ?? ''}')}\n'
              'Status: ${_statusLabel(status)}\n'
              'Audience: $audience\n'
              'Tags: $tags\n'
              'Updated: ${entry['updated'] ?? 'Not set'}\n'
              'Created by: ${entry['created_by'] ?? 'system'} (${entry['created_by_role'] ?? 'system'})\n'
              'Updated by: ${entry['updated_by'] ?? 'system'} (${entry['updated_by_role'] ?? 'system'})\n'
              'Reviewed by: ${entry['reviewed_by'] ?? 'Not reviewed'}\n'
              'Reviewed at: ${entry['reviewed_at'] ?? 'Not reviewed'}\n'
              'Source: $source\n\n'
              'Review notes\n${entry['review_notes'] ?? 'No review notes.'}\n\n'
              'Summary\n${entry['summary'] ?? ''}\n\n'
              'Content\n${entry['content'] ?? ''}',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _editKnowledgeEntry(entry);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filteredKnowledgeGaps() {
    if (_gapStatusFilter == 'all') return _knowledgeGaps;
    return _knowledgeGaps
        .where((gap) => '${gap['status'] ?? 'open'}' == _gapStatusFilter)
        .toList();
  }

  void _draftEntryFromGap(Map<String, dynamic> gap) {
    final question = '${gap['question'] ?? ''}'.trim();
    final role = '${gap['role'] ?? 'student'}';
    final suggestedTags =
        ((gap['suggested_tags'] as List<dynamic>?) ??
                const ['demo', 'knowledge gap'])
            .map((item) => '$item')
            .where((item) => item.isNotEmpty)
            .toList();
    setState(() {
      _editingEntryId = null;
      _activeGapId = '${gap['id'] ?? ''}';
      _entryIdController.clear();
      _titleController.text =
          '${gap['suggested_title'] ?? 'Demo Knowledge Entry'}';
      _selectedCategory = _isLecturer
          ? 'learning'
          : '${gap['suggested_category'] ?? 'governance'}';
      _tagsController.text = suggestedTags.join(', ');
      _approvalStatus = 'needs_review';
      _selectedAudiences
        ..clear()
        ..addAll(
          _isLecturer
              ? const {'lecturer'}
              : role == 'guest'
              ? const {'public', 'guest'}
              : role == 'lecturer'
              ? const {'lecturer'}
              : const {'student'},
        );
      _summaryController.text =
          'Demo placeholder drafted from a student question. Replace with approved ESUI information before production.';
      _contentController.text =
          'Demo placeholder drafted from this knowledge gap: "$question". Eve should not treat this as final policy. A staff reviewer should replace this draft with approved ESUI information, source links, office ownership, and any official limits before production use.';
      _sourceUrlController.clear();
      _message =
          'Drafted a knowledge entry from a gap. Review and edit before saving.';
      _error = null;
    });
  }

  Future<void> _setGapStatus(
    Map<String, dynamic> gap,
    String status, {
    String? notes,
  }) async {
    final gapId = '${gap['id'] ?? ''}';
    if (gapId.isEmpty) return;
    setState(() {
      _busyGapId = gapId;
      _error = null;
      _message = null;
    });
    try {
      final updates = <String, dynamic>{'status': status};
      if (notes != null) updates['notes'] = notes;
      await widget.api.updateKnowledgeGap(
        gapId,
        updates,
        actorRole: widget.role,
        actorUserId: _actorUserId,
      );
      final payload = await widget.api.knowledgeGaps(
        actorRole: widget.role,
        actorUserId: _actorUserId,
      );
      if (!mounted) return;
      setState(() {
        _knowledgeGaps = _entryList(payload['gaps']);
        _message = 'Knowledge gap marked as $status.';
        _busyGapId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _busyGapId = null;
      });
    }
  }

  String _formatCounts(Map<String, dynamic> counts) {
    if (counts.isEmpty) return 'No entries available yet.';
    return counts.entries
        .map((entry) => '${_titleCase(entry.key)}: ${entry.value}')
        .join('\n');
  }

  String _titleCase(String value) {
    final parts = value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty);
    return parts
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _actionBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Tools'),
        ),
        OutlinedButton.icon(
          onPressed: _loading || _reloading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        FilledButton.icon(
          onPressed: _loading || _reloading ? null : _reload,
          icon: _reloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(_reloading ? 'Reloading' : 'Reload'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _entryForm() {
    final editing = _editingEntryId != null;
    return Form(
      key: _entryFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(
                    icon: Icons.add_circle_outline,
                    color: AppColors.green,
                    small: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing
                              ? 'Edit knowledge entry'
                              : 'Add knowledge entry',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          editing ? _editingEntryId! : _entryScopeNote,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final halfWidth = constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: halfWidth,
                        child: TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) => _requiredMin(value, 4, 'Title'),
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_selectedCategory),
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categoryChoices
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(_titleCase(category)),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _selectedCategory =
                                      value ?? _defaultCategory,
                                ),
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: TextFormField(
                          controller: _entryIdController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Entry ID',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: editing
                              ? (value) => _requiredMin(value, 4, 'Entry ID')
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: TextFormField(
                          controller: _tagsController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tags',
                            prefixIcon: Icon(Icons.sell),
                          ),
                          validator: (value) => _splitTags(value ?? '').isEmpty
                              ? 'Add at least one tag.'
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _audienceSelector(),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('status-$_approvalStatus'),
                          initialValue: _approvalStatus,
                          decoration: const InputDecoration(
                            labelText: 'Approval status',
                            prefixIcon: Icon(Icons.verified_user),
                          ),
                          items: _availableApprovalStatuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_statusLabel(status)),
                                ),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _approvalStatus =
                                      value ?? _defaultApprovalStatus,
                                ),
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: TextFormField(
                          controller: _reviewNotesController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Review notes',
                            prefixIcon: Icon(Icons.rate_review),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: TextFormField(
                          controller: _summaryController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Summary',
                            prefixIcon: Icon(Icons.short_text),
                          ),
                          validator: (value) =>
                              _requiredMin(value, 20, 'Summary'),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: TextFormField(
                          controller: _contentController,
                          minLines: 5,
                          maxLines: 9,
                          decoration: const InputDecoration(
                            labelText: 'Full content',
                            prefixIcon: Icon(Icons.notes),
                          ),
                          validator: (value) =>
                              _requiredMin(value, 40, 'Full content'),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: TextFormField(
                          controller: _sourceUrlController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Source URL',
                            prefixIcon: Icon(Icons.link),
                          ),
                          validator: _sourceUrlError,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() {
                            _clearEntryForm();
                            _error = null;
                            _message = null;
                          }),
                    icon: const Icon(Icons.clear),
                    label: Text(editing ? 'Cancel edit' : 'Clear'),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveEntry,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving
                          ? (editing ? 'Updating' : 'Saving')
                          : (editing ? 'Update entry' : 'Save entry'),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audienceSelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Audience',
        prefixIcon: Icon(Icons.groups),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableAudienceOptions
            .map(
              (audience) => FilterChip(
                label: Text(_titleCase(audience)),
                selected: _selectedAudiences.contains(audience),
                onSelected: _saving
                    ? null
                    : (selected) => setState(() {
                        if (selected) {
                          _selectedAudiences.add(audience);
                        } else {
                          _selectedAudiences.remove(audience);
                        }
                      }),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _knowledgeLibrary() {
    final filteredEntries = _filteredKnowledgeEntries();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Knowledge library',
          trailing: '${filteredEntries.length}/${_knowledgeEntries.length}',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 900
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 640
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: _librarySearchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _libraryQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () => setState(() {
                                    _librarySearchController.clear();
                                    _libraryQuery = '';
                                  }),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                        onChanged: (value) =>
                            setState(() => _libraryQuery = value),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: _libraryCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All categories'),
                          ),
                          ..._categoryChoices.map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(_titleCase(category)),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _libraryCategoryFilter = value ?? 'all',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: _libraryAudienceFilter,
                        decoration: const InputDecoration(
                          labelText: 'Audience',
                          prefixIcon: Icon(Icons.groups),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All audiences'),
                          ),
                          ..._availableAudienceOptions.map(
                            (audience) => DropdownMenuItem(
                              value: audience,
                              child: Text(_titleCase(audience)),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _libraryAudienceFilter = value ?? 'all',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredEntries.isEmpty)
          const InfoCard(
            icon: Icons.search_off,
            title: 'No matching entries',
            subtitle: 'Library filter',
            body: 'Adjust the search text, category, or audience filter.',
          )
        else
          ResponsiveWrap(
            children: filteredEntries
                .map(
                  (entry) =>
                      KnowledgeEntryCard(
                            entry: entry,
                            busy: _busyEntryId == entry['id'],
                            onView: () => _showKnowledgeEntry(entry),
                            onEdit: () => _editKnowledgeEntry(entry),
                            onDelete: () => _deleteKnowledgeEntry(entry),
                          )
                          as Widget,
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _knowledgeGapPanel() {
    final filteredGaps = _filteredKnowledgeGaps();
    final openCount = _knowledgeGaps
        .where((gap) => '${gap['status'] ?? 'open'}' == 'open')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Knowledge gaps', trailing: '$openCount open'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 760
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: _gapStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.rule),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(
                            value: 'reviewing',
                            child: Text('Reviewing'),
                          ),
                          DropdownMenuItem(
                            value: 'converted',
                            child: Text('Converted'),
                          ),
                          DropdownMenuItem(
                            value: 'dismissed',
                            child: Text('Dismissed'),
                          ),
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All gaps'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _gapStatusFilter = value ?? 'open'),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          IconBadge(
                            icon: Icons.psychology_alt,
                            color: AppColors.green,
                            small: true,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Eve records weak or unanswered questions here. Staff review the gap, draft a knowledge entry, then approve it before Eve uses it.',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredGaps.isEmpty)
          const InfoCard(
            icon: Icons.check_circle_outline,
            title: 'No gaps in this view',
            subtitle: 'Review queue',
            body:
                'When Eve cannot answer confidently, the question will appear here for staff review.',
          )
        else
          ResponsiveWrap(
            children: filteredGaps
                .map(
                  (gap) =>
                      KnowledgeGapCard(
                            gap: gap,
                            busy: _busyGapId == gap['id'],
                            onDraft: () => _draftEntryFromGap(gap),
                            onReview: () => _setGapStatus(gap, 'reviewing'),
                            onDismiss: () => _setGapStatus(gap, 'dismissed'),
                          )
                          as Widget,
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _auditTrailPanel() {
    final visibleEvents = _auditEvents.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Recent audit trail',
          trailing: '${visibleEvents.length} shown',
        ),
        const SizedBox(height: 10),
        if (visibleEvents.isEmpty)
          const InfoCard(
            icon: Icons.history,
            title: 'No audit events yet',
            subtitle: 'Knowledge governance',
            body:
                'Create, update, approve, or delete a knowledge entry and Eve will record the action here.',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: visibleEvents
                    .map(
                      (event) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const IconBadge(
                          icon: Icons.history,
                          color: AppColors.blue,
                          small: true,
                        ),
                        title: Text(
                          '${_titleCase('${event['action'] ?? 'event'}')} - ${event['entry_title'] ?? event['entry_id'] ?? 'Knowledge entry'}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${event['actor_user_id'] ?? 'unknown'} (${event['actor_role'] ?? 'role'})'
                          ' - ${_statusLabel('${event['approval_status'] ?? 'draft'}')}'
                          ' - ${event['timestamp'] ?? ''}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stats == null) {
      return PageShell(
        title: _pageTitle,
        subtitle: _pageSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _actionBar(),
            const SizedBox(height: 28),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (_error != null && _stats == null) {
      return PageShell(
        title: _pageTitle,
        subtitle: _pageSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _actionBar(),
            const SizedBox(height: 14),
            InfoCard(
              icon: Icons.terminal,
              title: 'Knowledge endpoints unavailable',
              subtitle: 'Backend check',
              body: _error!,
            ),
          ],
        ),
      );
    }

    final stats = _stats ?? const {};
    final validation = _validation ?? const {};
    final categories = _asMap(stats['categories']);
    final audiences = _asMap(stats['audiences']);
    final approvalStatuses = _asMap(stats['approval_statuses']);
    final errors = _issues('errors');
    final warnings = _issues('warnings');
    final ok = validation['ok'] == true;

    return PageShell(
      title: _pageTitle,
      subtitle: _pageSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionBar(),
          const SizedBox(height: 14),
          InfoCard(
            icon: _isLecturer ? Icons.badge : Icons.admin_panel_settings,
            title: _isLecturer ? 'Lecturer scope' : 'Admin scope',
            subtitle: widget.user.name,
            body: _entryScopeNote,
          ),
          const SizedBox(height: 18),
          _entryForm(),
          const SizedBox(height: 18),
          if (_isAdmin) ...[
            _knowledgeGapPanel(),
            const SizedBox(height: 18),
          ] else ...[
            const InfoCard(
              icon: Icons.rule,
              title: 'School affairs protected',
              subtitle: 'Admin queue',
              body:
                  'Knowledge gaps about hostel rules, fees, admission, portals, and other school affairs are reserved for admin review.',
            ),
            const SizedBox(height: 18),
          ],
          _knowledgeLibrary(),
          if (_isAdmin) ...[const SizedBox(height: 18), _auditTrailPanel()],
          if (_message != null) ...[
            const SizedBox(height: 14),
            InfoCard(
              icon: Icons.check_circle,
              title: 'Reload complete',
              subtitle: 'Current backend memory',
              body: _message!,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            InfoCard(
              icon: Icons.warning_amber,
              title: 'Last action failed',
              subtitle: 'Backend response',
              body: _error!,
            ),
          ],
          const SizedBox(height: 14),
          ResponsiveWrap(
            children: [
              MetricCard(
                label: 'Curated entries',
                value: '${stats['entry_count'] ?? 0}',
                icon: Icons.library_books,
              ),
              MetricCard(
                label: 'Official ESUI links',
                value: '${stats['official_source_count'] ?? 0}',
                icon: Icons.verified,
              ),
              MetricCard(
                label: 'Internal entries',
                value: '${stats['curated_internal_count'] ?? 0}',
                icon: Icons.storage,
              ),
              MetricCard(
                label: 'Approved',
                value: '${approvalStatuses['approved'] ?? 0}',
                icon: Icons.verified_user,
              ),
              MetricCard(
                label: 'Needs review',
                value: '${approvalStatuses['needs_review'] ?? 0}',
                icon: Icons.rate_review,
              ),
              MetricCard(
                label: 'Warnings',
                value: '${warnings.length}',
                icon: Icons.warning_amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Validation',
            trailing: ok ? 'Passing' : 'Needs review',
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: ok ? Icons.verified_user : Icons.error_outline,
            title: ok
                ? 'Knowledge file is valid'
                : 'Knowledge file needs edits',
            subtitle: '${errors.length} errors, ${warnings.length} warnings',
            body: ok
                ? 'Eve can use the current curated knowledge file. Warnings are review notes for freshness or source governance.'
                : 'Fix the listed errors before treating the knowledge base as approved for school-wide use.',
          ),
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            KnowledgeIssuePanel(
              title: 'Errors',
              subtitle: 'Must be fixed',
              icon: Icons.report,
              color: const Color(0xFFB73535),
              issues: errors,
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            KnowledgeIssuePanel(
              title: 'Warnings',
              subtitle: 'Review before defense',
              icon: Icons.warning_amber,
              color: AppColors.gold,
              issues: warnings,
            ),
          ],
          const SizedBox(height: 18),
          SectionTitle(title: 'Source coverage', trailing: 'Grouped entries'),
          const SizedBox(height: 10),
          ResponsiveWrap(
            children: [
              InfoCard(
                icon: Icons.groups,
                title: 'Audience scope',
                subtitle: 'Access labels',
                body: _formatCounts(audiences),
              ),
              ...categories.entries.map(
                (entry) =>
                    InfoCard(
                          icon: Icons.sell,
                          title: _titleCase(entry.key),
                          subtitle: 'Knowledge category',
                          body: '${entry.value} entries available to Eve.',
                        )
                        as Widget,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(title: 'Payment links', trailing: 'Official only'),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.payments,
            title: 'Portal safety',
            subtitle: 'Fees and payments',
            body:
                'Eve should only send students to approved ESUI payment pages and should warn them not to pay through unofficial third-party links.',
          ),
        ],
      ),
    );
  }
}

class KnowledgeIssuePanel extends StatelessWidget {
  const KnowledgeIssuePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.issues,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> issues;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = issues.take(6).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: icon, color: color, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${issues.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...visibleIssues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${issue['entry_id'] ?? 'entry'} - ${issue['field'] ?? 'field'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      '${issue['message'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (issues.length > visibleIssues.length)
              Text(
                'Showing first ${visibleIssues.length} of ${issues.length}.',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeEntryCard extends StatelessWidget {
  const KnowledgeEntryCard({
    required this.entry,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Map<String, dynamic> entry;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = '${entry['category'] ?? ''}';
    final audience = ((entry['audience'] as List<dynamic>?) ?? const [])
        .map((item) => '$item')
        .join(', ');
    final tags = ((entry['tags'] as List<dynamic>?) ?? const [])
        .map((item) => '#$item')
        .join(' ');
    final hasSource = '${entry['source_url'] ?? ''}'.isNotEmpty;
    final status = _approvalStatusStatic(entry);
    final statusColor = _statusColor(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  icon: hasSource ? Icons.verified : Icons.storage,
                  color: hasSource ? AppColors.green : AppColors.gold,
                  small: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry['title'] ?? 'Untitled entry'}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry['id'] ?? ''}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabelStatic(status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${entry['summary'] ?? ''}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 10),
            Text(
              '${_titleCaseStatic(category)} · $audience',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tags,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Updated by ${entry['updated_by'] ?? 'system'}'
              '${entry['reviewed_at'] == null ? '' : ' - Reviewed ${entry['reviewed_at']}'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDelete,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(busy ? 'Deleting' : 'Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _titleCaseStatic(String value) {
    final parts = value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty);
    return parts
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _approvalStatusStatic(Map<String, dynamic> entry) {
    final raw = '${entry['approval_status'] ?? ''}'.trim().toLowerCase();
    if (raw == 'demo' ||
        raw == 'draft' ||
        raw == 'approved' ||
        raw == 'needs_review') {
      return raw;
    }
    final tags = ((entry['tags'] as List<dynamic>?) ?? const [])
        .map((item) => '$item'.toLowerCase())
        .toSet();
    final id = '${entry['id'] ?? ''}'.toLowerCase();
    if (id.startsWith('demo-') || tags.contains('demo')) return 'demo';
    return 'approved';
  }

  static String _statusLabelStatic(String status) {
    if (status == 'needs_review') return 'Needs Review';
    return _titleCaseStatic(status);
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'needs_review':
        return AppColors.gold;
      case 'draft':
        return AppColors.blue;
      default:
        return AppColors.muted;
    }
  }
}

class KnowledgeGapCard extends StatelessWidget {
  const KnowledgeGapCard({
    required this.gap,
    required this.busy,
    required this.onDraft,
    required this.onReview,
    required this.onDismiss,
    super.key,
  });

  final Map<String, dynamic> gap;
  final bool busy;
  final VoidCallback onDraft;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final status = '${gap['status'] ?? 'open'}';
    final count = gap['count'] ?? 1;
    final confidence = gap['confidence'] ?? 0;
    final tags = ((gap['suggested_tags'] as List<dynamic>?) ?? const [])
        .map((item) => '#$item')
        .join(' ');
    final color = status == 'converted'
        ? AppColors.green
        : status == 'dismissed'
        ? AppColors.muted
        : status == 'reviewing'
        ? AppColors.gold
        : AppColors.blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: Icons.help_outline, color: color, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${gap['question'] ?? 'Unknown question'}',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status · Asked $count time(s) · Confidence: $confidence',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${gap['suggested_title'] ?? 'Suggested knowledge entry'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Suggested category: ${gap['suggested_category'] ?? 'governance'}',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tags,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.blue, fontSize: 12),
              ),
            ],
            if ('${gap['converted_entry_id'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Converted entry: ${gap['converted_entry_id']}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy || status == 'converted' ? null : onDraft,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Draft entry'),
                ),
                OutlinedButton.icon(
                  onPressed: busy || status == 'reviewing' ? null : onReview,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search),
                  label: Text(busy ? 'Updating' : 'Reviewing'),
                ),
                OutlinedButton.icon(
                  onPressed: busy || status == 'dismissed' ? null : onDismiss,
                  icon: const Icon(Icons.block),
                  label: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LecturerCourseInsightCard extends StatelessWidget {
  const LecturerCourseInsightCard({
    required this.course,
    required this.onPrompt,
    super.key,
  });

  final Map<String, dynamic> course;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final average = ((course['average_score'] as num?) ?? 0).round();
    final totalSessions = course['total_sessions'] ?? 0;
    final completedSessions = course['completed_sessions'] ?? 0;
    final weakest = course['weakest_topic'] as Map<String, dynamic>?;
    final color = average >= 75
        ? AppColors.green
        : average >= 55
        ? AppColors.gold
        : const Color(0xFFB73535);
    final topicText = weakest == null
        ? 'No weak saved topic yet'
        : 'Weakest saved topic: ${weakest['topic']} (${weakest['average_score']}%)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.query_stats, color: color, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course['course_code']}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${course['course_title']}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$average%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: average / 100,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(
              'Saved sessions: $completedSessions/$totalSessions completed',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              'Tracked students: ${course['student_count'] ?? 0}',
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              topicText,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 10),
            Text(
              '${course['intervention']}',
              style: const TextStyle(height: 1.35),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onPrompt(
                'Show lecturer analytics for ${course['course_code']} using saved Eve learning-session trends and recommend interventions.',
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask Eve'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdmissionPage extends StatelessWidget {
  const AdmissionPage({
    required this.courseController,
    required this.jambController,
    required this.english,
    required this.mathematics,
    required this.science,
    required this.fourthSubject,
    required this.estimate,
    required this.estimating,
    required this.onEnglishChanged,
    required this.onMathematicsChanged,
    required this.onScienceChanged,
    required this.onFourthSubjectChanged,
    required this.onEstimate,
    required this.onAskEve,
    super.key,
  });

  final TextEditingController courseController;
  final TextEditingController jambController;
  final String english;
  final String mathematics;
  final String science;
  final String fourthSubject;
  final AdmissionEstimate? estimate;
  final bool estimating;
  final ValueChanged<String> onEnglishChanged;
  final ValueChanged<String> onMathematicsChanged;
  final ValueChanged<String> onScienceChanged;
  final ValueChanged<String> onFourthSubjectChanged;
  final VoidCallback onEstimate;
  final ValueChanged<String> onAskEve;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Admission Readiness',
      subtitle: 'Preparation guidance for prospective candidates.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final form = FormPanel(
            courseController: courseController,
            jambController: jambController,
            english: english,
            mathematics: mathematics,
            science: science,
            fourthSubject: fourthSubject,
            estimating: estimating,
            onEnglishChanged: onEnglishChanged,
            onMathematicsChanged: onMathematicsChanged,
            onScienceChanged: onScienceChanged,
            onFourthSubjectChanged: onFourthSubjectChanged,
            onEstimate: onEstimate,
          );
          final result = EstimatePanel(estimate: estimate, onAskEve: onAskEve);
          if (!wide) {
            return Column(children: [form, const SizedBox(height: 12), result]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              const SizedBox(width: 12),
              Expanded(child: result),
            ],
          );
        },
      ),
    );
  }
}

class FormPanel extends StatelessWidget {
  const FormPanel({
    required this.courseController,
    required this.jambController,
    required this.english,
    required this.mathematics,
    required this.science,
    required this.fourthSubject,
    required this.estimating,
    required this.onEnglishChanged,
    required this.onMathematicsChanged,
    required this.onScienceChanged,
    required this.onFourthSubjectChanged,
    required this.onEstimate,
    super.key,
  });

  final TextEditingController courseController;
  final TextEditingController jambController;
  final String english;
  final String mathematics;
  final String science;
  final String fourthSubject;
  final bool estimating;
  final ValueChanged<String> onEnglishChanged;
  final ValueChanged<String> onMathematicsChanged;
  final ValueChanged<String> onScienceChanged;
  final ValueChanged<String> onFourthSubjectChanged;
  final VoidCallback onEstimate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Candidate profile'),
            const SizedBox(height: 12),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course of interest',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: jambController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'JAMB score'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GradePicker(
                  label: 'English',
                  value: english,
                  onChanged: onEnglishChanged,
                ),
                GradePicker(
                  label: 'Mathematics',
                  value: mathematics,
                  onChanged: onMathematicsChanged,
                ),
                GradePicker(
                  label: 'Science',
                  value: science,
                  onChanged: onScienceChanged,
                ),
                GradePicker(
                  label: 'Fourth subject',
                  value: fourthSubject,
                  onChanged: onFourthSubjectChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: estimating ? null : onEstimate,
              icon: estimating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Estimate readiness'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradePicker extends StatelessWidget {
  const GradePicker({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const grades = ['A1', 'B2', 'B3', 'C4', 'C5', 'C6', 'D7', 'E8', 'F9'];
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: grades
            .map((grade) => DropdownMenuItem(value: grade, child: Text(grade)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class EstimatePanel extends StatelessWidget {
  const EstimatePanel({
    required this.estimate,
    required this.onAskEve,
    super.key,
  });

  final AdmissionEstimate? estimate;
  final ValueChanged<String> onAskEve;

  @override
  Widget build(BuildContext context) {
    if (estimate == null) {
      return const InfoCard(
        icon: Icons.speed,
        title: 'Readiness result',
        subtitle: 'Waiting for estimate',
        body: 'Enter your details to get a preparation band and next steps.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              estimate!.band,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${estimate!.course} - ${estimate!.readinessScore}/100',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: estimate!.readinessScore / 100),
            const SizedBox(height: 14),
            const SectionTitle(title: 'Recommendations'),
            const SizedBox(height: 8),
            ...estimate!.recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $item'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onAskEve(
                'Explain my ${estimate!.course} admission readiness score of ${estimate!.readinessScore}/100 and give me a preparation plan.',
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask Eve to explain'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentPeerNotesPage extends StatefulWidget {
  const StudentPeerNotesPage({
    required this.api,
    required this.user,
    required this.onBack,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final VoidCallback onBack;

  @override
  State<StudentPeerNotesPage> createState() => _StudentPeerNotesPageState();
}

class _StudentPeerNotesPageState extends State<StudentPeerNotesPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _courseCode;
  String? _error;
  String? _message;
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _ownNotes = const [];
  List<Map<String, dynamic>> _approvedNotes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Map<String, dynamic>>([
        widget.api.learningProfile(widget.user.userId),
        widget.api.studentPeerNotes(widget.user.userId),
      ]);
      final profilePayload = results[0];
      final notesPayload = results[1];
      final profile =
          (profilePayload['profile'] as Map<String, dynamic>?) ?? const {};
      final courses = ((profile['courses'] as List<dynamic>?) ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _courseCode ??= courses.isNotEmpty
            ? '${courses.first['course_code']}'
            : null;
        _ownNotes = ((notesPayload['own_notes'] as List<dynamic>?) ?? const [])
            .map((item) => item as Map<String, dynamic>)
            .toList();
        _approvedNotes =
            ((notesPayload['approved_peer_notes'] as List<dynamic>?) ??
                    const [])
                .map((item) => item as Map<String, dynamic>)
                .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _courseCode == null) return;
    setState(() {
      _submitting = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.api.submitPeerNote(
        userId: widget.user.userId,
        courseCode: _courseCode!,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
      );
      _titleController.clear();
      _summaryController.clear();
      _contentController.clear();
      await _load();
      if (!mounted) return;
      setState(() {
        _message =
            'Submitted for review. A lecturer/admin must approve it before classmates can use it.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _minLength(String? value, int length, String label) {
    if ((value ?? '').trim().length < length) {
      return '$label should be at least $length characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageShell(
      title: 'Peer Notes',
      subtitle: 'Share useful course explanations after review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Tools'),
              ),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.error_outline,
              title: 'Peer notes unavailable',
              subtitle: 'Try again',
              body: _error!,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.check_circle_outline,
              title: 'Contribution received',
              subtitle: 'Pending review',
              body: _message!,
            ),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Submit a course note',
                      trailing: 'Review required',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _courseCode,
                      decoration: const InputDecoration(
                        labelText: 'Registered course',
                      ),
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem<String>(
                              value: '${course['course_code']}',
                              child: Text(
                                '${course['course_code']} - ${course['title']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _courseCode = value),
                      validator: (value) =>
                          value == null ? 'Choose a course.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Note title',
                        hintText: 'Example: Understanding normalization',
                      ),
                      validator: (value) => _minLength(value, 4, 'The title'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Short summary',
                        hintText:
                            'What should another student understand after reading this?',
                      ),
                      minLines: 2,
                      maxLines: 4,
                      validator: (value) =>
                          _minLength(value, 20, 'The summary'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Your explanation',
                        hintText:
                            'Write your explanation, example, formula, steps, or common mistakes here.',
                      ),
                      minLines: 8,
                      maxLines: 14,
                      validator: (value) =>
                          _minLength(value, 80, 'The explanation'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_submitting ? 'Submitting' : 'Submit note'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'My contributions',
            trailing: '${_ownNotes.length}',
          ),
          const SizedBox(height: 10),
          if (_ownNotes.isEmpty)
            const InfoCard(
              icon: Icons.note_add,
              title: 'No peer notes yet',
              subtitle: 'Start with one course',
              body:
                  'Your submitted notes will appear here with pending, approved, rejected, or needs revision status.',
            )
          else
            ResponsiveWrap(
              children: _ownNotes
                  .map((note) => PeerNoteCard(note: note))
                  .toList(),
            ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Approved notes from classmates',
            trailing: '${_approvedNotes.length}',
          ),
          const SizedBox(height: 10),
          if (_approvedNotes.isEmpty)
            const InfoCard(
              icon: Icons.groups,
              title: 'No approved peer notes yet',
              subtitle: 'Reviewer controlled',
              body:
                  'When a lecturer or admin approves student notes for your registered courses, they will appear here as study support.',
            )
          else
            ResponsiveWrap(
              children: _approvedNotes
                  .map((note) => PeerNoteCard(note: note))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class PeerNoteReviewPage extends StatefulWidget {
  const PeerNoteReviewPage({
    required this.api,
    required this.user,
    required this.role,
    required this.onBack,
    super.key,
  });

  final EveApi api;
  final EveUser user;
  final EveRole role;
  final VoidCallback onBack;

  @override
  State<PeerNoteReviewPage> createState() => _PeerNoteReviewPageState();
}

class _PeerNoteReviewPageState extends State<PeerNoteReviewPage> {
  bool _loading = true;
  String? _busyNoteId;
  String? _error;
  String? _message;
  List<Map<String, dynamic>> _notes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await widget.api.peerNoteReviewQueue(
        actorRole: widget.role,
        actorUserId: widget.user.userId,
      );
      if (!mounted) return;
      setState(() {
        _notes = ((payload['notes'] as List<dynamic>?) ?? const [])
            .map((item) => item as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<String?> _reviewNotesDialog(String status) {
    final controller = TextEditingController(
      text: status == 'approved'
          ? 'Approved for peer learning support in this demo.'
          : '',
    );
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as ${status.replaceAll('_', ' ')}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Review note',
            hintText: 'Tell the student what changed or why it was approved.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save review'),
          ),
        ],
      ),
    );
  }

  Future<void> _review(Map<String, dynamic> note, String status) async {
    final noteId = '${note['id'] ?? ''}';
    if (noteId.isEmpty) return;
    final reviewNotes = await _reviewNotesDialog(status);
    if (reviewNotes == null) return;
    setState(() {
      _busyNoteId = noteId;
      _error = null;
      _message = null;
    });
    try {
      await widget.api.reviewPeerNote(
        noteId: noteId,
        actorRole: widget.role,
        actorUserId: widget.user.userId,
        status: status,
        reviewNotes: reviewNotes,
      );
      await _load();
      if (!mounted) return;
      setState(() {
        _message = 'Peer note marked as ${status.replaceAll('_', ' ')}.';
        _busyNoteId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busyNoteId = null;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final pending = _notes
        .where((note) => note['status'] == 'pending')
        .toList();
    return PageShell(
      title: 'Peer Note Review',
      subtitle: widget.role == EveRole.lecturer
          ? 'Assigned-course student contributions'
          : 'School-wide student contribution queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Tools'),
              ),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.error_outline,
              title: 'Review queue unavailable',
              subtitle: 'Try again',
              body: _error!,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.check_circle_outline,
              title: 'Review saved',
              subtitle: 'Queue updated',
              body: _message!,
            ),
          ],
          const SizedBox(height: 18),
          SectionTitle(title: 'Pending review', trailing: '${pending.length}'),
          const SizedBox(height: 10),
          if (_notes.isEmpty)
            const InfoCard(
              icon: Icons.rate_review,
              title: 'No peer notes available',
              subtitle: 'Nothing to review',
              body:
                  'Student submissions will appear here when they match your review scope.',
            )
          else
            ResponsiveWrap(
              children: _notes
                  .map(
                    (note) => PeerNoteCard(
                      note: note,
                      actions: [
                        OutlinedButton.icon(
                          onPressed: _busyNoteId == note['id']
                              ? null
                              : () => _review(note, 'needs_revision'),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Revise'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busyNoteId == note['id']
                              ? null
                              : () => _review(note, 'rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                        FilledButton.icon(
                          onPressed: _busyNoteId == note['id']
                              ? null
                              : () => _review(note, 'approved'),
                          icon: const Icon(Icons.verified),
                          label: const Text('Approve'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class PeerNoteCard extends StatelessWidget {
  const PeerNoteCard({required this.note, this.actions = const [], super.key});

  final Map<String, dynamic> note;
  final List<Widget> actions;

  Color _statusColor(String status) {
    return switch (status) {
      'approved' => AppColors.green,
      'rejected' => const Color(0xFFB73535),
      'needs_revision' => AppColors.gold,
      _ => AppColors.blue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = '${note['status'] ?? 'pending'}';
    final color = _statusColor(status);
    final content = '${note['content'] ?? ''}';
    final preview = content.length > 320
        ? '${content.substring(0, 320)}...'
        : content;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.library_books, color: color, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${note['course_code']} - ${note['title']}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'By ${note['student_name'] ?? 'Student'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${note['summary'] ?? ''}',
              style: const TextStyle(height: 1.4),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                preview,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
            if ('${note['review_notes'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Review note: ${note['review_notes']}',
                style: const TextStyle(height: 1.4),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.user,
    required this.online,
    required this.onSwitch,
    required this.onLogout,
    required this.onAskSecurity,
    super.key,
  });

  final EveUser user;
  final bool online;
  final VoidCallback onSwitch;
  final VoidCallback onLogout;
  final VoidCallback onAskSecurity;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Profile',
      subtitle: user.role.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.softBlue,
                    child: Text(
                      user.name.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          user.department ?? 'Public access',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        if (user.level != null)
                          Text(
                            '${user.level}L',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                  ApiDot(online: online, loading: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveWrap(
            children: [
              ActionTile(
                icon: Icons.switch_account,
                title: 'Switch account',
                subtitle: 'Change demo role or user',
                accent: AppColors.blue,
                onTap: onSwitch,
              ),
              ActionTile(
                icon: Icons.lock_outline,
                title: 'Privacy',
                subtitle: 'Ask how Eve protects records',
                accent: AppColors.green,
                onTap: onAskSecurity,
              ),
              ActionTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Return to role selection',
                accent: const Color(0xFFB73535),
                onTap: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EveRail extends StatelessWidget {
  const EveRail({
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.white,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: Text('Ask Eve'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: Text('Tools'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: Text('Apply'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
        ],
      ),
    );
  }
}

class AccountSheet extends StatelessWidget {
  const AccountSheet({
    required this.users,
    required this.selectedUserId,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  final List<EveUser> users;
  final String selectedUserId;
  final ValueChanged<EveUser> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Switch account',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...users.map(
            (user) => ListTile(
              leading: CircleAvatar(child: Text(user.name.substring(0, 1))),
              title: Text(user.name),
              subtitle: Text(
                '${user.role.label}${user.department == null ? '' : ' - ${user.department}'}',
              ),
              trailing: user.userId == selectedUserId
                  ? const Icon(Icons.check_circle, color: AppColors.green)
                  : null,
              onTap: () => onSelect(user),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFB73535)),
            title: const Text('Logout'),
            subtitle: const Text('Return to the role selection screen'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class PageShell extends StatelessWidget {
  const PageShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 680
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconBadge(icon: icon, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actionLabel,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: icon, small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(height: 1.4)),
            if (actionLabel != null && onTap != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.auto_awesome),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(icon: icon, small: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(label, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AskBar extends StatelessWidget {
  const AskBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ask Eve anything about ESUI...',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, this.trailing, super.key});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    this.color = AppColors.blue,
    this.small = false,
    super.key,
  });

  final IconData icon;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: small ? 20 : 24),
    );
  }
}

class ApiDot extends StatelessWidget {
  const ApiDot({required this.online, required this.loading, super.key});

  final bool online;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = loading
        ? AppColors.gold
        : online
        ? AppColors.green
        : const Color(0xFFB73535);
    return Tooltip(
      message: loading
          ? 'Checking Eve backend'
          : online
          ? 'Eve backend online'
          : 'Eve backend offline',
      child: Icon(Icons.circle, color: color, size: 12),
    );
  }
}

class ApiPill extends StatelessWidget {
  const ApiPill({
    required this.online,
    required this.loading,
    this.dark = false,
    super.key,
  });

  final bool online;
  final bool loading;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = loading
        ? AppColors.gold
        : online
        ? AppColors.green
        : const Color(0xFFB73535);
    final label = loading
        ? 'Checking backend'
        : online
        ? 'Backend online'
        : 'Backend offline';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: dark ? Colors.white : color, size: 9),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: InfoCard(
          icon: Icons.info_outline,
          title: title,
          subtitle: 'Unavailable',
          body: message,
        ),
      ),
    );
  }
}

class OfflineState extends StatelessWidget {
  const OfflineState({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      title: 'Backend offline',
      subtitle: 'Start Eve backend and refresh this page.',
      child: InfoCard(
        icon: Icons.terminal,
        title: 'Backend command',
        subtitle: 'FastAPI',
        body:
            'python -m uvicorn api.eve_core.main:app --host 127.0.0.1 --port 8010 --reload\n\n$error',
      ),
    );
  }
}
