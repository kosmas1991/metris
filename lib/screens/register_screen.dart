import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tetris/screens/login_screen.dart';
import '../blocs/user_bloc.dart';
import '../widgets/retro_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<UserBloc>().add(
            UserRegisterRequested(
              username: _usernameController.text,
              email: _emailController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const LoginScreen(),
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
                    if (state is UserRegisterSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black,
                          content: const Text(
                            'Registration successful! Please login.',
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
                      _goToLogin();
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
                            'Register',
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
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          RetroTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                          ),
                          const SizedBox(height: 12),
                          RetroTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
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
                              onPressed:
                                  state is UserLoading ? null : _register,
                              child: state is UserLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.green)
                                  : const Text('Register'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _goToLogin,
                            child: const Text(
                              'Already have an account? Login',
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
