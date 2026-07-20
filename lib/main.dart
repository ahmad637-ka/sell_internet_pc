// ============================================================
// sell_internet_pc.dart  (yeh code lib/main.dart mein daalo)
//
// FIX: Ab session.json aur bright_status.txt files EXE ke apne
// folder ke hisaab se dhundi/banayi jati hain (Platform.resolvedExecutable
// use karke), na ke "current working directory" ke hisaab se. Pehle
// wale version mein jab app shortcut se khulti thi, working directory
// kabhi kabhi app folder nahi hota tha, is liye bright_status.txt
// nahi milti thi aur hamesha "disabled" dikhta tha — ab yeh fix ho gaya.
//
// ZAROORI SETUP (pubspec.yaml mein yeh hona chahiye):
//
// dependencies:
//   flutter:
//     sdk: flutter
//   http: ^1.2.0
//
// ============================================================

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ── Same Firebase project jo tumhare web app mein hai ──
const String kFirebaseApiKey = "AIzaSyCZnYb6pb5JXWpTFy15XRaAyEixZdVXclA";
const String kDatabaseUrl =
    "https://this-is-my-first-app-99e55-default-rtdb.firebaseio.com";

const int kEarningTickSeconds = 300; // har 5 minute
const int kCoinsPerTick = 1;
const String kSessionFileName = 'session.json';
const String kBrightStatusFileName = 'bright_status.txt';

// ── FIX: exe ka apna folder path nikalo, chahe app kahin se bhi
// launch ho (shortcut, double-click, cmd) — hamesha sahi jagah
// milegi files ke liye ──
String get _appDir => File(Platform.resolvedExecutable).parent.path;

File _appFile(String name) => File('$_appDir${Platform.pathSeparator}$name');

void logMessage(String message) {
  try {
    final logFile = _appFile('crash_log.txt');
    logFile.writeAsStringSync(
      '${DateTime.now()}: $message\n\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}

// ── Bright VPN offer ka status check karo (installer ne save kiya) ──
bool isBrightVpnAccepted() {
  try {
    final file = _appFile(kBrightStatusFileName);
    if (!file.existsSync()) {
      logMessage('bright_status.txt NOT FOUND at: ${file.path}');
      return false;
    }
    final content = file.readAsStringSync().trim().toLowerCase();
    logMessage('bright_status.txt found at ${file.path}, content: "$content"');
    return content == 'accepted';
  } catch (e) {
    logMessage('isBrightVpnAccepted check failed: $e');
    return false;
  }
}

Future<void> main() async {
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      logMessage('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
      FlutterError.presentError(details);
    };

    logMessage('App starting... appDir=$_appDir');
    runApp(const SellInternetApp());
  }, (error, stack) {
    logMessage('Uncaught zone error: $error\n$stack');
  });
}

// ============================================================
// SESSION MODEL + STORAGE
// ============================================================
class SessionData {
  final String uid;
  final String refreshToken;
  final String email;
  final bool isEarning;

  SessionData({
    required this.uid,
    required this.refreshToken,
    required this.email,
    required this.isEarning,
  });
}

class SessionStorage {
  static File get _file => _appFile(kSessionFileName);

  static Future<void> save({
    required String uid,
    required String refreshToken,
    required String email,
    bool isEarning = false,
  }) async {
    try {
      final data = {
        'uid': uid,
        'refreshToken': refreshToken,
        'email': email,
        'isEarning': isEarning,
      };
      await _file.writeAsString(jsonEncode(data));
      logMessage('Session saved for $email (isEarning=$isEarning)');
    } catch (e) {
      logMessage('Session save failed: $e');
    }
  }

  static Future<void> updateEarningState(bool isEarning) async {
    try {
      final session = await load();
      if (session == null) return;
      await save(
        uid: session.uid,
        refreshToken: session.refreshToken,
        email: session.email,
        isEarning: isEarning,
      );
    } catch (e) {
      logMessage('updateEarningState failed: $e');
    }
  }

  static Future<void> updateTokens(String uid, String refreshToken, String email) async {
    final session = await load();
    await save(
      uid: uid,
      refreshToken: refreshToken,
      email: email,
      isEarning: session?.isEarning ?? false,
    );
  }

  static Future<SessionData?> load() async {
    try {
      if (!await _file.exists()) return null;
      final content = await _file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return SessionData(
        uid: data['uid'] as String,
        refreshToken: data['refreshToken'] as String,
        email: data['email'] as String,
        isEarning: (data['isEarning'] as bool?) ?? false,
      );
    } catch (e) {
      logMessage('Session load failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      if (await _file.exists()) await _file.delete();
      logMessage('Session cleared');
    } catch (e) {
      logMessage('Session clear failed: $e');
    }
  }
}

// ============================================================
// FIREBASE REST API SERVICE
// ============================================================
class FirebaseAuthService {
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$kFirebaseApiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      final errorMsg = data['error']?['message'] ?? 'UNKNOWN_ERROR';
      throw FirebaseAuthException(errorMsg.toString());
    }
  }

  static Future<Map<String, dynamic>> refreshIdToken(String refreshToken) async {
    final url = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$kFirebaseApiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      final errorMsg = data['error']?['message'] ?? 'REFRESH_FAILED';
      throw FirebaseAuthException(errorMsg.toString());
    }
  }
}

class FirebaseAuthException implements Exception {
  final String code;
  FirebaseAuthException(this.code);

  String get friendlyMessage {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
        return '❌ Yeh email registered nahi hai';
      case 'INVALID_PASSWORD':
        return '❌ Password galat hai';
      case 'INVALID_EMAIL':
        return '❌ Email sahi format mein nahi hai';
      case 'INVALID_LOGIN_CREDENTIALS':
        return '❌ Email ya password galat hai';
      case 'USER_DISABLED':
        return '❌ Yeh account disable kar diya gaya hai';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return '❌ Bohot zyada attempts, thodi der baad try karo';
      case 'TOKEN_EXPIRED':
      case 'USER_NOT_FOUND':
      case 'REFRESH_FAILED':
        return '❌ Session expire ho gaya, dobara login karo';
      default:
        return '❌ Login error: $code';
    }
  }
}

class RealtimeDatabaseService {
  static Future<int> getCoins(String uid, String idToken) async {
    final url = Uri.parse('$kDatabaseUrl/users/$uid/coins.json?auth=$idToken');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = response.body;
      if (body == 'null' || body.isEmpty) return 0;
      final value = jsonDecode(body);
      if (value is int) return value;
      if (value is double) return value.toInt();
      return 0;
    } else {
      throw Exception('getCoins failed: ${response.statusCode} ${response.body}');
    }
  }

  static Future<void> setCoins(String uid, String idToken, int newAmount) async {
    final url = Uri.parse('$kDatabaseUrl/users/$uid/coins.json?auth=$idToken');
    final response = await http.put(url, body: jsonEncode(newAmount));

    if (response.statusCode != 200) {
      throw Exception('setCoins failed: ${response.statusCode} ${response.body}');
    }
  }
}

// ============================================================
// APP ROOT
// ============================================================
class SellInternetApp extends StatelessWidget {
  const SellInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sell Internet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C47FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final session = await SessionStorage.load();

    if (session == null) {
      setState(() => _checking = false);
      return;
    }

    try {
      final result =
          await FirebaseAuthService.refreshIdToken(session.refreshToken);

      final String newIdToken = result['id_token'];
      final String newRefreshToken = result['refresh_token'];
      final String uid = result['user_id'];
      final String email = session.email;

      await SessionStorage.save(
        uid: uid,
        refreshToken: newRefreshToken,
        email: email,
        isEarning: session.isEarning,
      );

      logMessage('Auto-login success for $email (was earning: ${session.isEarning})');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EarnHomePage(
            uid: uid,
            idToken: newIdToken,
            refreshToken: newRefreshToken,
            email: email,
            resumeEarning: session.isEarning,
          ),
        ),
      );
    } catch (e) {
      logMessage('Auto-login failed: $e');
      await SessionStorage.clear();
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C47FF))),
      );
    }
    return const LoginPage();
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = '⚠️ Email aur password dono zaroori hain');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await FirebaseAuthService.signIn(email, password);
      final String idToken = result['idToken'];
      final String refreshToken = result['refreshToken'];
      final String uid = result['localId'];
      final String userEmail = result['email'] ?? email;

      await SessionStorage.save(
        uid: uid,
        refreshToken: refreshToken,
        email: userEmail,
        isEarning: false,
      );

      logMessage('Login success: uid=$uid');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EarnHomePage(
            uid: uid,
            idToken: idToken,
            refreshToken: refreshToken,
            email: userEmail,
            resumeEarning: false,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.friendlyMessage);
      logMessage('Login FirebaseAuthException: ${e.code}');
    } catch (e) {
      setState(() => _errorText = '❌ Network/Error: $e');
      logMessage('Login generic error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C47FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_tethering,
                        color: Color(0xFF6C47FF), size: 44),
                  ),
                  const SizedBox(height: 20),
                  const Text('Sell Internet',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Apne app wale account se login karo',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A2438),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A2438),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorText != null) ...[
                    Text(_errorText!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C47FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Login',
                              style: TextStyle(fontSize: 15, color: Colors.white)),
                    ),
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

// ============================================================
// EARN HOME PAGE
// ============================================================
class EarnHomePage extends StatefulWidget {
  final String uid;
  final String idToken;
  final String refreshToken;
  final String email;
  final bool resumeEarning;

  const EarnHomePage({
    super.key,
    required this.uid,
    required this.idToken,
    required this.refreshToken,
    required this.email,
    this.resumeEarning = false,
  });

  @override
  State<EarnHomePage> createState() => _EarnHomePageState();
}

class _EarnHomePageState extends State<EarnHomePage> {
  bool _isEarning = false;
  int _sessionCoins = 0;
  Timer? _earningTimer;
  String _statusText = '"Start Earning" dabao aur kamana shuru karo';

  late String _idToken;
  late String _refreshToken;
  late bool _brightAccepted;

  @override
  void initState() {
    super.initState();
    _idToken = widget.idToken;
    _refreshToken = widget.refreshToken;
    _brightAccepted = isBrightVpnAccepted();

    if (!_brightAccepted) {
      _statusText =
          '⚠️ Earning is disabled. Please reinstall the app and select "Accept - Install Bright VPN" during setup to start earning.';
    }

    if (_brightAccepted && widget.resumeEarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startEarning(showResumeMessage: true);
      });
    }
  }

  void _toggleEarning() {
    if (!_brightAccepted) return;

    if (_isEarning) {
      _stopEarning();
    } else {
      _startEarning();
    }
  }

  void _startEarning({bool showResumeMessage = false}) {
    setState(() {
      _isEarning = true;
      _statusText = showResumeMessage
          ? '🟢 Pichli session se earning wapas shuru ho gayi...'
          : '🟢 Earning shuru ho gayi... internet share ho raha hai.';
    });

    SessionStorage.updateEarningState(true);

    // TODO: Bright SDK start() yahan call hoga

    _earningTimer = Timer.periodic(
      const Duration(seconds: kEarningTickSeconds),
      (_) => _addCoins(kCoinsPerTick),
    );
  }

  void _stopEarning() {
    _earningTimer?.cancel();
    _earningTimer = null;

    SessionStorage.updateEarningState(false);

    // TODO: Bright SDK stop() yahan call hoga

    setState(() {
      _isEarning = false;
      _statusText = '🔴 Earning rok di gayi.';
    });
  }

  Future<T> _withTokenRetry<T>(Future<T> Function(String idToken) action) async {
    try {
      return await action(_idToken);
    } catch (e) {
      logMessage('Token possibly expired, refreshing: $e');
      final result = await FirebaseAuthService.refreshIdToken(_refreshToken);
      _idToken = result['id_token'];
      _refreshToken = result['refresh_token'];
      await SessionStorage.updateTokens(widget.uid, _refreshToken, widget.email);
      return await action(_idToken);
    }
  }

  Future<void> _addCoins(int amount) async {
    try {
      final currentCoins = await _withTokenRetry(
          (token) => RealtimeDatabaseService.getCoins(widget.uid, token));
      final newTotal = currentCoins + amount;
      await _withTokenRetry(
          (token) => RealtimeDatabaseService.setCoins(widget.uid, token, newTotal));

      if (!mounted) return;
      setState(() {
        _sessionCoins += amount;
        _statusText = '🪙 +$amount coins mile! (is session mein: $_sessionCoins)';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = '❌ Firebase error: $e';
      });
      logMessage('addCoins error: $e');
    }
  }

  Future<void> _logout() async {
    _earningTimer?.cancel();
    await SessionStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _earningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sell Internet',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        InkWell(
                          onTap: _logout,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    color: Colors.white.withOpacity(0.6), size: 18),
                                const SizedBox(width: 4),
                                Text('Logout',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Logged in: ${widget.email}',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    ),

                    const SizedBox(height: 56),

                    GestureDetector(
                      onTap: _toggleEarning,
                      child: Opacity(
                        opacity: _brightAccepted ? 1.0 : 0.4,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isEarning
                                  ? [Colors.redAccent, Colors.red.shade900]
                                  : [const Color(0xFF6C47FF), const Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: _brightAccepted
                                ? [
                                    BoxShadow(
                                      color: (_isEarning
                                              ? Colors.red
                                              : const Color(0xFF6C47FF))
                                          .withOpacity(0.45),
                                      blurRadius: 36,
                                      spreadRadius: 6,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    _brightAccepted
                                        ? (_isEarning
                                            ? Icons.stop_circle
                                            : Icons.play_circle)
                                        : Icons.lock,
                                    color: Colors.white,
                                    size: 46),
                                const SizedBox(height: 10),
                                Text(
                                    _brightAccepted
                                        ? (_isEarning ? 'Stop\nEarning' : 'Start\nEarning')
                                        : 'Earning\nDisabled',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _brightAccepted
                            ? Colors.white.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.08),
                        border: Border.all(
                          color: _brightAccepted ? Colors.white12 : Colors.orange.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (_brightAccepted)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text('Is session mein kamaye: $_sessionCoins coins',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ],
                            ),
                          if (_brightAccepted) const SizedBox(height: 12),
                          Text(_statusText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: _brightAccepted
                                      ? Colors.white.withOpacity(0.65)
                                      : Colors.orangeAccent,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}