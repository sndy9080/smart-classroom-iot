import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool autoPlay;
  final Duration interval;

  const HomeCarousel({
    super.key,
    required this.imageUrls,
    this.height = 280,
    this.autoPlay = true,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.imageUrls.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        final next = (_index + 1) % widget.imageUrls.length;
        _index = next;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sudut bawah rounded
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (p) => setState(() => _index = p),
              itemBuilder: (context, i) {
                final url = widget.imageUrls[i];
                if (url.startsWith('http')) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey),
                  );
                } else {
                  return Image.asset(url, fit: BoxFit.cover);
                }
              },
            ),
          ),

          // Gradient bottom untuk transisi halus
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 100,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Indikator
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: widget.imageUrls.length,
                effect: const WormEffect(
                  dotWidth: 10,
                  dotHeight: 6,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}