import 'package:flutter/material.dart';

import '../../../../core/strings/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/activation_result.dart';
import '../../domain/repositories/license_repository.dart';

/// Modal bottom sheet allowing users to input and redeem an activation code.
class ActivationSheet extends StatefulWidget {
  const ActivationSheet({super.key, required this.repository});

  final LicenseRepository repository;

  static Future<ActivationResult?> show(
    BuildContext context, {
    required LicenseRepository repository,
  }) {
    return showModalBottomSheet<ActivationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
      ),
      builder: (_) => ActivationSheet(repository: repository),
    );
  }

  @override
  State<ActivationSheet> createState() => _ActivationSheetState();
}

class _ActivationSheetState extends State<ActivationSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال رمز التفعيل');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await widget.repository.activateCode(code);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.chipBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.activationDialogTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.activationDialogDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _codeController,
              enabled: !_isSubmitting,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: AppStrings.codeFieldLabel,
                hintText: AppStrings.codeFieldHint,
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitCode,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      AppStrings.confirmActivationButton,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
