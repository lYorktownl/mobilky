import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UsersPage extends StatefulWidget {
  final List<User> users;

  UsersPage({Key? key, this.users = const []}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final List<User> _users;

  @override
  void initState() {
    super.initState();
    _users = List.from(widget.users);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersString = prefs.getString('users');
      if (usersString != null) {
        final List<dynamic> usersJson = jsonDecode(usersString);
        setState(() {
          _users.addAll(usersJson.map((json) => User.fromJson(json)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load users. Please try again later.'),
      ));
    }
  }

  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = _users.map((user) => user.toJson()).toList();
      await prefs.setString('users', jsonEncode(usersJson));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save users. Please try again later.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(user.name[0]),
            ),
            title: Text(user.name),
            subtitle: Text('Login: ${user.login}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditUserDialog(context, user, index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onAddUser: (name, login, password) {
          if (name.isNotEmpty && login.isNotEmpty && password.isNotEmpty) {
            if (_users.any((user) => user.login == login)) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Login already exists!'),
              ));
              return;
            }
            setState(() {
              _users.add(User(
                name: name,
                login: login,
                password: password,
              ));
            });
            _saveUsers();
          }
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user, int index) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        user: user,
        onEditUser: (name, login, password) {
          setState(() {
            _users[index] = User(
              name: name,
              login: login,
              password: password,
            );
          });
          _saveUsers();
        },
      ),
    );
  }

  void _deleteUser(int index) {
    final deletedUser = _users[index];

    setState(() {
      _users.removeAt(index);
    });
    _saveUsers();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ${deletedUser.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _users.insert(index, deletedUser);
            });
            _saveUsers();
          },
        ),
      ),
    );
  }
}

class AddUserDialog extends StatelessWidget {
  final Function(String name, String login, String password) onAddUser;

  const AddUserDialog({required this.onAddUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return AlertDialog(
      title: Text('Add User'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onAddUser(
              nameController.text,
              loginController.text,
              passwordController.text,
            );
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class EditUserDialog extends StatelessWidget {
  final User user;
  final Function(String name, String login, String password) onEditUser;

  const EditUserDialog({required this.user, required this.onEditUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: user.name);
    final TextEditingController loginController = TextEditingController(text: user.login);
    final TextEditingController passwordController = TextEditingController(text: user.password);

    return AlertDialog(
      title: Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onEditUser(
              nameController.text,
              loginController.text,
              passwordController.text,
            );
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class User {
  final String name;
  final String login;
  final String password;

  User({required this.name, required this.login, required this.password});

  Map<String, dynamic> toJson() => {
    'name': name,
    'login': login,
    'password': password,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      login: json['login'],
      password: json['password'],
    );
  }
}
