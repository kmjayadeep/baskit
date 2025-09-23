import 'package:flutter/material.dart';

/// Widget for the submit button with loading state (create or update)
class SubmitButtonWidget extends StatelessWidget {
  final bool isLoading;
  final Color selectedColor;
  final VoidCallback onPressed;
  final String buttonText;
  final String loadingText;

  const SubmitButtonWidget({
    super.key,
    required this.isLoading,
    required this.selectedColor,
    required this.onPressed,
    this.buttonText = 'Create List',
    this.loadingText = 'Creating...',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(loadingText),
                  ],
                )
                : Text(buttonText),
      ),
    );
  }
}
