import 'package:flutter/material.dart';
import 'package:scholar_chat/constants/app_colors.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
  });
  final String message;
  final bool isSender;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSender ? AppColors.messageBlue : AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(
                isSender ? 24 : 5,
              ),
              bottomRight: Radius.circular(
                isSender ? 5 : 24,
              ),
            ),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
