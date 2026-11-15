import 'license_entitlement.dart';

enum ActivationErrorCode {
  invalidCode,
  expiredCode,
  slotsExhausted,
  revoked,
  networkError,
}

class ActivationResult {
  const ActivationResult._({
    required this.isSuccess,
    this.entitlement,
    this.errorCode,
    required this.message,
  });

  factory ActivationResult.success(
    LicenseEntitlement entitlement, [
    String? message,
  ]) {
    return ActivationResult._(
      isSuccess: true,
      entitlement: entitlement,
      message: message ?? 'تم تفعيل الاشتراك بنجاح',
    );
  }

  factory ActivationResult.failure(
    ActivationErrorCode code, [
    String? message,
  ]) {
    final defaultMsg = switch (code) {
      ActivationErrorCode.invalidCode => 'رمز التفعيل غير صحيح أو غير موجود',
      ActivationErrorCode.expiredCode => 'انتهت صلاحية رمز التفعيل',
      ActivationErrorCode.slotsExhausted =>
        'تم استخدام هذا الرمز على الحد الأقصى للأجهزة المصرح بها (جهازين)',
      ActivationErrorCode.revoked => 'تم إلغاء هذا الترخيص من قبل الإدارة',
      ActivationErrorCode.networkError => 'تعذر الاتصال بخادم التفعيل، يرجى التأكد من اتصال الإنترنت والمحاولة ثانية',
    };

    return ActivationResult._(
      isSuccess: false,
      errorCode: code,
      message: message ?? defaultMsg,
    );
  }

  final bool isSuccess;
  final LicenseEntitlement? entitlement;
  final ActivationErrorCode? errorCode;
  final String message;
}
