import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navidrome_service.dart';

class LoginPage extends StatefulWidget {
  final void Function(String username, String password) onLogin;
  const LoginPage({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final username = _usernameController.text;
    final password = _passwordController.text;

    final service = NavidromeService(
      baseUrl: 'https://musik.radio-endstation.de',
      username: username,
      password: password,
    );
    final success = await service.ping();

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      widget.onLogin(username, password);
    } else {
      setState(() {
        _error = 'Zugangsdaten ungültig';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Login')),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                style: const TextStyle(color: CupertinoColors.white),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                style: const TextStyle(color: CupertinoColors.white),
                obscureText: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              _loading
                  ? const CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
