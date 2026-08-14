import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Enveloppe un widget dans un `Dismissible` avec fond rouge "Supprimer"
/// et une confirmation avant suppression effective (évite les erreurs
/// de manipulation, surtout pour des données financières).
class SwipeToDelete extends StatelessWidget {
  final Key dismissibleKey;
  final Widget child;
  final String confirmTitle;
  final String confirmMessage;
  final Future<void> Function() onDelete;

  const SwipeToDelete({
    super.key,
    required this.dismissibleKey,
    required this.child,
    required this.confirmTitle,
    required this.confirmMessage,
    required this.onDelete,
  });

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        title: Text(confirmTitle),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissibleKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pLarge),
        margin: const EdgeInsets.only(bottom: AppSizes.pSmall),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: child,
    );
  }
}
