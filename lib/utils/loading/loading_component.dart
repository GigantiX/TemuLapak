import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingComponent{
  static final LoadingComponent _instance = LoadingComponent._internal();
  static LoadingComponent get instance => _instance;
  
  factory LoadingComponent() => _instance;
  final String lottiePath = 'lib/assets/animation/AnimationLoading.json';

  LoadingComponent._internal();

  OverlayEntry? _overlayEntry;

  void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)
              ),
              child: ClipRRect(
                child: Lottie.asset(
                  lottiePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover
                  ),
              ),
            ),
          )
        ],
      )
      );
      Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  } 
}

