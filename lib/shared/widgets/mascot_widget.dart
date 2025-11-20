import 'package:flutter/material.dart';

/// Atti - The Attenglish mascot widget
/// A friendly brain character that provides encouragement and guidance
class MascotWidget extends StatelessWidget {
  final String? message;
  final double size;
  final String? imagePath;
  final bool useLogo; // If true, displays logo without circular background

  const MascotWidget({
    super.key,
    this.message,
    this.size = 150,
    this.imagePath,
    this.useLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo or Mascot avatar
        if (useLogo)
          // Logo without background
          SizedBox(
            width: size * 1.5, // Logo is wider, so increase width
            height: size,
            child: Image.asset(
              'assets/images/logo/Attenglish_Logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback text
                return Center(
                  child: Text(
                    'Attenglish',
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                );
              },
            ),
          )
        else
          // Mascot avatar with circular background (uses PNG image or falls back to emoji)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF7ED321)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Image.asset(
                  imagePath ?? 'assets/images/mascot/atti_login.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to emoji if image not found
                    return Center(
                      child: Text(
                        '🧠',
                        style: TextStyle(
                          fontSize: size * 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        if (!useLogo) ...[
          const SizedBox(height: 12),
          // Mascot name (only for mascot mode, not logo)
          const Text(
            'Atti',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              letterSpacing: 0.5,
            ),
          ),
        ],

        // Speech bubble with message
        if (message != null) ...[
          const SizedBox(height: 16),
          _SpeechBubble(message: message!),
        ],
      ],
    );
  }
}

/// Speech bubble widget for Atti's messages
class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '💬',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C3E50),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
