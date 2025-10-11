import 'package:flutter/material.dart';
import 'package:pollino/core/localization/i18n_service.dart';

class PollPrimaryButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onSubmit;

  const PollPrimaryButton({
    super.key,
    required this.isLoading,
    required this.label,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return // Submit Button
        Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
