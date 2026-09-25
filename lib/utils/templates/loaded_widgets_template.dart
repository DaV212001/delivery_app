import 'package:flutter/material.dart';
import '../api_call_status.dart';
import '../error_data.dart';

class LoadedWidget extends StatelessWidget {
  final ApiCallStatus status;
  final ErrorData? errorData;
  final Widget child;
  final Widget loadingChild;
  final Widget? errorChild;
  final Widget? emptyChild;
  final VoidCallback? onReload;

  const LoadedWidget({
    super.key,
    required this.status,
    required this.child,
    required this.loadingChild,
    this.errorData,
    this.errorChild,
    this.emptyChild,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ApiCallStatus.loading) {
      return loadingChild;
    }
    if (status == ApiCallStatus.error) {
      return errorChild ??
          _DefaultErrorCard(
            errorData: errorData ??
                const ErrorData(
                  title: 'An error occurred',
                  body: 'Something went wrong. Please try again.',
                  buttonText: 'Retry',
                ),
            onReload: onReload,
          );
    }
    if (status == ApiCallStatus.empty && emptyChild != null) {
      return emptyChild!;
    }
    return child;
  }
}

class _DefaultErrorCard extends StatelessWidget {
  final ErrorData errorData;
  final VoidCallback? onReload;

  const _DefaultErrorCard({
    required this.errorData,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorData.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorData.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onReload != null && errorData.buttonText != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onReload,
                child: Text(errorData.buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
