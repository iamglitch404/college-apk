import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isShort = size.height < 700;

    return Column(
      children: [
        // Brand Logo
        Container(
          padding: EdgeInsets.all(isShort ? 12 : 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school_rounded, size: isShort ? 40 : 60, color: theme.colorScheme.primary),
        ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
        
        SizedBox(height: isShort ? 8 : 16),
        
        // Brand Name
        Text(
          'BRIDGEWATER',
          style: GoogleFonts.outfit(
            fontSize: isShort ? 18 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: theme.colorScheme.onSurface,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 10, end: 0),
        
        Text(
          'COLLEGE',
          style: GoogleFonts.outfit(
            fontSize: isShort ? 12 : 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ).animate().fadeIn(delay: 600.ms),
        
        SizedBox(height: isShort ? 24 : 48),
        
        // Page Title & Subtitle
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isShort ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 700.ms).slideX(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  color: theme.hintColor,
                  fontSize: isShort ? 13 : 15,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ],
    );
  }
}
