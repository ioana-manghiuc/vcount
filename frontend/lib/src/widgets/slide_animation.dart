import 'package:flutter/material.dart';

class SlideTransitionExample extends StatefulWidget {
  const SlideTransitionExample({super.key});

  @override
  State<SlideTransitionExample> createState() => _SlideTransitionExampleState();
}

class _SlideTransitionExampleState extends State<SlideTransitionExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(-1.5, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleSlideStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleSlideStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _animationFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: SizedBox(
        width: 570,
        child: _animationFinished
            ? Image.asset('assets/images/car.png', fit: BoxFit.contain)
            : Image.asset('assets/animation/car_moving.gif', fit: BoxFit.contain),
      ),
    );
  }
}