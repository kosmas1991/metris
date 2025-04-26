import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metris/screens/register_screen.dart';
import '../blocs/user_bloc.dart';
import '../widgets/retro_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<UserBloc>().add(
            UserLoginRequested(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const RegisterScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 450,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: BlocConsumer<UserBloc, UserState>(
                  listener: (context, state) {
                    if (state is UserAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black,
                          content: const Text(
                            'Login successful!',
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      );
                      Navigator.of(context).pushReplacementNamed('/lobby');
                    } else if (state is UserFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black,
                          content: Text(
                            state.message,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              color: Colors.green,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 24),
                          RetroTextField(
                            controller: _usernameController,
                            label: 'Username',
                          ),
                          const SizedBox(height: 12),
                          RetroTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                side: const BorderSide(
                                    color: Colors.green, width: 2),
                                foregroundColor: Colors.green,
                                textStyle:
                                    const TextStyle(fontFamily: 'PressStart2P'),
                              ),
                              onPressed: state is UserLoading ? null : _login,
                              child: state is UserLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.green)
                                  : const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _goToRegister,
                            child: const Text(
                              'Don\'t have an account? Register',
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'PressStart2P',
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/');
                            },
                            child: const Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'PressStart2P',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
