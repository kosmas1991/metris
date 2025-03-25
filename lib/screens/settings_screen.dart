import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/rotation_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  double _difficulty = 1.0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 450,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              'SETTINGS',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.green,
            elevation: 0,
          ),
          body: Center(
            child: Container(
              width: 450,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withAlpha(20),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GAME OPTIONS',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRetroSwitch(
                    title: 'SOUND',
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'DIFFICULTY',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.green,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRetroSlider(
                    value: _difficulty,
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  BlocBuilder<RotationBloc, RotationState>(
                    builder: (context, state) {
                      return _buildRetroSwitch(
                        title: 'ROTATION CLOCKWISE',
                        value: state.isClockwise,
                        onChanged: (value) {
                          context
                              .read<RotationBloc>()
                              .add(ToggleRotationDirection());
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  _buildRetroButton(
                    'BACK',
                    onPressed: () {
                      Navigator.pop(context);
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

  Widget _buildRetroSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 14,
              color: Colors.green,
              letterSpacing: 1,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 60,
            height: 30,
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.grey.shade800,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Center(
              child: Text(
                value ? 'ON' : 'OFF',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetroSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: Colors.green,
        inactiveTrackColor: Colors.grey.shade800,
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayColor: Colors.green.withAlpha(30),
        valueIndicatorColor: Colors.green,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'PressStart2P',
        ),
      ),
      child: Slider(
        value: value,
        min: 0.5,
        max: 2.0,
        divisions: 3,
        label: _getDifficultyLabel(value),
        onChanged: onChanged,
      ),
    );
  }

  String _getDifficultyLabel(double value) {
    if (value <= 0.5) return 'EASY';
    if (value <= 1.0) return 'NORMAL';
    if (value <= 1.5) return 'HARD';
    return 'EXPERT';
  }

  Widget _buildRetroButton(String text, {required VoidCallback onPressed}) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.green, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(50),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.normal,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
