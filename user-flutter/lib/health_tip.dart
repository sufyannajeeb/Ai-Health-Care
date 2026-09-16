import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class HealthTipPage extends StatefulWidget {
  @override
  _HealthTipPageState createState() => _HealthTipPageState();
}

class _HealthTipPageState extends State<HealthTipPage> {
  final List<String> healthTips = [
    // (Paste all your tips here - keeping it short for now)
    'Stay hydrated and drink plenty of water.',
    'Eat a balanced diet with a variety of fruits and vegetables.',
    'Exercise regularly to improve your overall health.',
    'Get at least 7-8 hours of sleep every night.',
    'Practice mindfulness and manage stress.',
    'Take care of your mental health and seek support when needed.',
    'Avoid processed sugar and trans fats.',
    'Try yoga or meditation for stress relief.',
    'Keep a food diary to track your nutrition.',
    'Practice deep breathing exercises for relaxation.',
  'Drink lemon water in the morning to kickstart digestion.',
  'Stand up and stretch every hour.',
  'Practice good sleep posture to reduce aches.',
  'Laugh daily—it’s good for your heart and mind.',
  'Avoid multitasking to reduce stress.',
  'Use stairs instead of elevators whenever possible.',
  'Chew your food slowly for better digestion.',
  'Keep healthy snacks on hand to avoid junk food.',
  'Read nutrition labels before purchasing packaged food.',
  'Take regular breaks from screen time.',
  'Wash fruits and vegetables thoroughly.',
  'Limit intake of saturated fats.',
  'Start your day with a healthy breakfast.',
  'Use herbs and spices instead of salt.',
  'Meditate for 10 minutes a day.',
  'Replace soda with sparkling water.',
  'Walk 10,000 steps a day.',
  'Use a standing desk part of the day.',
  'Try intermittent fasting under guidance.',
  'Keep a gratitude journal.',
  'Do a tech detox day once a month.',
  'Keep a consistent sleep and wake schedule.',
  'Practice digital mindfulness—turn off unnecessary notifications.',
  'Learn to say no to avoid burnout.',
  'Do bodyweight exercises at home.',
  'Walk barefoot on grass for grounding.',
  'Don’t eat when you are not hungry.',
  'Avoid eating in front of screens.',
  'Eat from smaller plates to control portions.',
  'Don’t skip meals regularly.',
  'Swap white rice for quinoa or brown rice.',
  'Use olive oil instead of butter.',
  'Eat nuts in moderation for heart health.',
  'Have regular eye exams.',
  'Spend time with pets—they reduce stress.',
  'Limit screen brightness in the evening.',
  'Get sunlight exposure for vitamin D.',
  'Try home gardening for stress relief.',
  'Take mental health days when needed.',
  'Practice forgiveness for emotional well-being.',
  'Keep your phone out of the bedroom.',
  'Use blue light filters after sunset.',
  'Incorporate fermented foods like yogurt or kimchi.',
  'Volunteer—it’s good for your soul.',
  'Learn a new skill to keep your brain active.',
  'Stay hydrated with coconut water after workouts.',
  'Eat dark chocolate in moderation for antioxidants.',
  'Take cold showers occasionally for circulation.',
  'Use a humidifier to improve air quality.',
  'Try a hobby that involves creativity.',
  'Keep a consistent workout schedule.',
  'Don’t ignore minor health symptoms.',
  'Declutter your space to reduce stress.',
  'Smile more—it boosts your mood.',
  'Practice good financial health to reduce anxiety.',
  'Use proper footwear to avoid back and knee pain.',
  'Schedule tech-free family time.',
  'Add turmeric to your cooking for anti-inflammatory benefits.',
  'Keep your home well-ventilated.',
  'Take magnesium-rich foods for better sleep.',
  'Avoid late-night caffeine or heavy meals.',
  'Eat slowly and mindfully.',
  'Practice self-compassion regularly.',
  'Drink herbal teas like chamomile before bed.',
  'Set realistic fitness goals.',
  'Avoid comparing your health journey to others.',
  'Build a supportive social network.',
  'Limit time spent on social media.',
  'Create a relaxing bedtime ritual.',
  'Keep learning about nutrition and fitness.',
  'Listen to calming music during stressful times.',
  'Surround yourself with positive influences.',
  'Try walking meetings instead of sitting.',
  'Schedule regular “me time.”',
  'Prepare meals at home more often.',
  'Take short naps if you’re tired.',
  'Try essential oils for relaxation (e.g., lavender).',
  'Get your blood pressure checked regularly.',
  'Breathe deeply when feeling overwhelmed.',
  'Take the scenic route to enjoy nature.',
  'Keep sugar out of your coffee.',
  'Make family meals a daily routine.',
  'Avoid gossip to reduce negativity.',
  'Brush your tongue while brushing your teeth.',
  'Store healthy snacks at eye level.',
  'Visualize your health goals.',
  'Keep fruits visible on the counter.',
  'Don’t underestimate the power of good posture.',
  'Avoid overdoing cardio—balance is key.',
  'Include legumes in your weekly diet.',
  'Use reminders for medication and hydration.',
  'Hydrate before meals, not during.',
  'Stay curious—mental stimulation boosts longevity.',
  'Switch to natural cleaners for health.',
  'Learn CPR or first aid basics.',
  'Floss daily—it impacts heart health too.',
  'Use calming colors in your living space.',
  'Add chia seeds to smoothies or oatmeal.',
  'Avoid over-reliance on supplements.',
  'Track your mood to identify triggers.',
  'Say affirmations aloud daily.',
  'Invest in a quality mattress.',
  'Value rest and recovery as much as workouts.',
  'Celebrate small health victories.',
  ];

  final FixedExtentScrollController _scrollController =
  FixedExtentScrollController();
  bool _isSpinning = false;
  int _currentIndex = 0;

  void _startSpinning() {
    if (_isSpinning) return;

    setState(() => _isSpinning = true);

    final random = Random();
    final targetIndex = random.nextInt(healthTips.length);

    int spinRounds = 40 + targetIndex; // spin at least 40 times then land
    int duration = 2000; // total animation time in milliseconds

    Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (spinRounds > 0) {
        _scrollController.jumpToItem((_scrollController.selectedItem + 1) % healthTips.length);
        spinRounds--;
      } else {
        timer.cancel();
        _scrollController.animateToItem(
          targetIndex,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
        setState(() {
          _currentIndex = targetIndex;
          _isSpinning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.shade100, Colors.teal.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.local_hospital, size: 60, color: Colors.redAccent),
              Text(
                "🎰 Spin the Tip Machine!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: size.height * 0.3,
                child: ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 80,
                  physics: FixedExtentScrollPhysics(),
                  perspective: 0.002,
                  diameterRatio: 2,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: healthTips.length,
                    builder: (context, index) {
                      final isSelected = index == _currentIndex && !_isSpinning;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white70,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            )
                          ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            healthTips[index],
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSpinning ? null : _startSpinning,
                icon: Icon(Icons.casino),
                label: Text("Spin for a Tip!"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (!_isSpinning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "🎯 Selected Tip:\n${healthTips[_currentIndex]}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

