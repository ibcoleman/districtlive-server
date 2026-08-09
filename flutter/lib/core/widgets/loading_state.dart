import 'package:flutter/material.dart';

/// Reusable loading state widget displayed while data is loading.
///
/// Shows a centered circular progress indicator.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
