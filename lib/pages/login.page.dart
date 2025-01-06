import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wct_mobile/pages/home.page.dart';
import 'package:wct_mobile/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000',
);

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogin = useState(true);
    final fullNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    useEffect(() {
      SharedPreferences.getInstance().then((prefs) {
        final savedEmail = prefs.getString('saved_email');
        if (savedEmail != null) {
          emailController.text = savedEmail;
        }
      });
      return null;
    }, []);

    Future<void> handleAuth() async {
      try {
        final email = emailController.text;
        final password = passwordController.text;

        if (email.isEmpty || password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all fields')),
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);

        final url =
            Uri.parse('$apiUrl/user/${isLogin.value ? 'login' : 'signup'}');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
            if (!isLogin.value) 'fullName': fullNameController.text,
          }),
        );

        if (!context.mounted) return;

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final token = responseData['token'] as String;

          await ref.read(authProvider.notifier).setToken(token);

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isLogin.value ? 'Login' : 'Signup'} successful'),
            ),
          );

          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${isLogin.value ? 'Login' : 'Signup'} failed: ${response.body}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Web Change Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isLogin.value ? 'Log in' : 'Sign up',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            if (!isLogin.value) ...[
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(
                isLogin.value ? 'Login' : 'Sign Up',
              ),
            ),
            TextButton(
              onPressed: () {
                isLogin.value = !isLogin.value;
              },
              child: Text(
                isLogin.value
                    ? 'Don\'t have an account? Sign Up'
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
