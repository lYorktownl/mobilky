import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'users_page.dart';
import 'tasks_page.dart';
import 'registration_page.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthManager(),
    );
  }
}

class AuthManager extends StatefulWidget {
  @override
  _AuthManagerState createState() => _AuthManagerState();
}

class _AuthManagerState extends State<AuthManager> {
  bool _isAuthenticated = false;
  User? _currentUser;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString('users');
    if (usersJson != null) {
      final List<dynamic> usersList = jsonDecode(usersJson);
      setState(() {
        _users = usersList.map((json) => User.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String usersJson = jsonEncode(_users.map((user) => user.toJson()).toList());
    await prefs.setString('users', usersJson);
  }

  Future<bool> _handleLogin(String login, String password) async {
    await _loadUsers();
    final user = _users.firstWhere(
          (user) => user.login == login && user.password == password,
      orElse: () => User(name: '', login: '', password: ''),
    );

    if (user.login.isNotEmpty) {
      setState(() {
        _isAuthenticated = true;
        _currentUser = user;
      });
      return true;
    } else {
      return false;
    }
  }

  void _handleRegister(User newUser) {
    if (_users.any((user) => user.login == newUser.login)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registration Failed'),
          content: Text('User with this login already exists.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _users.add(newUser);
      });
      _saveUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully!')),
      );
    }
  }

  void _updateUser(User updatedUser) {
    final index = _users.indexWhere((user) => user.login == updatedUser.login);
    if (index != -1) {
      setState(() {
        _users[index] = updatedUser;
      });
      _saveUsers();
    }
  }

  void _logout() {
    setState(() {
      _isAuthenticated = false;
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return HomePage(
        currentUser: _currentUser,
        users: _users,
        onUpdateUser: _updateUser,
        onLogout: _logout,
      );
    } else {
      return LoginPage(
        onLogin: _handleLogin,
        onRegister: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RegistrationPage(onRegister: _handleRegister),
            ),
          );
        },
      );
    }
  }
}

class HomePage extends StatefulWidget {
  final User? currentUser;
  final List<User> users;
  final Function(User) onUpdateUser;
  final VoidCallback onLogout;

  const HomePage({
    required this.currentUser,
    required this.users,
    required this.onUpdateUser,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late UsersPage _usersPage;
  late TasksPage _tasksPage;

  @override
  void initState() {
    super.initState();
    _updatePages();
  }

  void _updatePages() {
    setState(() {
      _usersPage = UsersPage(
        users: widget.users,
        onUpdateUser: widget.onUpdateUser,
      );
      _tasksPage = TasksPage(users: widget.users);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [_usersPage, _tasksPage];

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _updatePages,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
