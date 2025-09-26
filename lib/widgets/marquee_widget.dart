import 'package:flutter/material.dart';

class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration scrollDuration;
  final Duration pauseDuration;
  final double velocity;

  const MarqueeWidget({
    super.key,
    required this.text,
    this.style,
    this.scrollDuration = const Duration(seconds: 2),
    this.pauseDuration = const Duration(seconds: 1),
    this.velocity = 50.0,
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _needsMarquee = false;

  @override
  void initState() {
    super.initState();
    
    // Calculate duration based on text length and velocity
    final calculatedDuration = Duration(
      milliseconds: (1000 / widget.velocity * 100).round(),
    );
    
    _controller = AnimationController(
      duration: calculatedDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Start marquee if text is long
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfMarqueeNeeded();
    });
  }

  void _checkIfMarqueeNeeded() {
    if (mounted) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        setState(() {
          _needsMarquee = textPainter.width > renderBox.size.width;
        });

        if (_needsMarquee) {
          _startMarquee();
        }
      }
    }
  }

  void _startMarquee() {
    if (_needsMarquee && mounted) {
      _runMarqueeLoop();
    }
  }

  void _runMarqueeLoop() async {
    while (mounted && _needsMarquee) {
      // Pause at start
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_needsMarquee) break;

      // Scroll from start to end
      _controller.forward();
      await _controller.forward().then((_) {
        if (mounted && _needsMarquee) {
          // Pause at end
          return Future.delayed(widget.pauseDuration);
        }
      });
      if (!mounted || !_needsMarquee) break;

      // Reset to start
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsMarquee) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();

        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final containerWidth = renderBox.size.width;
        final textWidth = textPainter.width;
        final scrollDistance = textWidth - containerWidth;
        
        // Ensure we scroll far enough to show all text
        final offset = _animation.value * scrollDistance;

        return ClipRect(
          child: Transform.translate(
            offset: Offset(-offset, 0),
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }
}
