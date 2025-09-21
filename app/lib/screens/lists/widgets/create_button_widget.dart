import 'package:flutter/material.dart';

/// Widget for the create list button with loading state
class CreateButtonWidget extends StatelessWidget {
  final bool isLoading;
  final Color selectedColor;
  final VoidCallback onPressed;

  const CreateButtonWidget({
    super.key,
    required this.isLoading,
    required this.selectedColor,
    required this.onPressed,
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
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Creating...'),
                  ],
                )
                : const Text('Create List'),
      ),
    );
  }
}
