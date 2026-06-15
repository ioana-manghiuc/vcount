import 'package:flutter/material.dart';

class CarSlideTransition extends StatefulWidget {
  const CarSlideTransition({super.key});

  @override
  State<CarSlideTransition> createState() => _CarSlideTransitionState();
}

class _CarSlideTransitionState extends State<CarSlideTransition>
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