/// Centralized user-facing strings for Wefaq (Arabic RTL).
abstract final class AppStrings {
  static const updateQuestions = 'تحديث الأسئلة';
  static const updateQuestionsHint =
      'حمّل أحدث الأسئلة واحفظها على هذا الجهاز للاستخدام دون إنترنت.';
  static const updateUnconfigured = 'تحديث الأسئلة غير مهيأ في هذه النسخة.';
  static const updateHasSession =
      'أكمل الجلسة المحفوظة أو احذفها قبل تحديث الأسئلة.';
  static const resumeHistoryFailure =
      'تعذر حفظ سجل الأسئلة. الجلسة محفوظة؛ حاول استعادتها مجددًا.';
  static const updateSuccess = 'تم تحديث الأسئلة على الجهاز.';
  static const updateCurrent = 'الأسئلة محدثة بالفعل.';
  static const updateFailed =
      'تعذر تحديث الأسئلة. تظل النسخة السابقة متاحة؛ حاول لاحقًا.';
  static const updatingQuestions = 'جارٍ التحديث...';
  static const activationTitle = 'تفعيل وفاق';
  static const activationInstructions =
      'أرسل معرّف التثبيت للدعم للحصول على كود يناسب جهازك.';
  static const activationTrialExpiredSubtitle =
      'انتهت الفترة التجريبية المجانية (أسبوعان). أرسل معرّف التثبيت للدعم للحصول على كود التفعيل.';
  static const activationTrialCardTitle = 'الفترة التجريبية المجانية';
  static const activationTrialActiveBadge = 'سارية (أسبوعان)';
  static const activationTrialExpiredBadge = 'انتهت التجربة';
  static const activationTrialAutoCloseHint =
      'يعمل التطبيق مجانًا ودون إنترنت لمدة 14 يومًا، ثم يُغلق تلقائيًا للمطالبة بكود التفعيل.';
  static const activationTrialExpiredNotice =
      'انتهت مهلة التجربة المجانية (14 يومًا) على هذا الجهاز. انسخ معرّف التثبيت وأرسله لفريق الدعم للحصول على كود أو رابط التفعيل.';
  static const activationTrialClockTamperedNotice =
      'تم رصد تغيير في ساعة الجهاز أثناء التجربة المجانية. اضبط التاريخ الصحيح أو أدخل كود التفعيل للمتابعة.';
  static String trialRemainingDays(int days) {
    if (days <= 1) return 'متبقي أقل من يوم في التجربة المجانية';
    if (days == 2) return 'متبقي يومان في التجربة المجانية';
    if (days <= 10) return 'متبقي $days أيام في التجربة المجانية';
    return 'متبقي $days يومًا في التجربة المجانية';
  }

  static String trialBarStatus(int days) {
    if (days <= 1) return 'تجربة مجانية · أقل من يوم';
    if (days == 2) return 'تجربة مجانية · متبقي يومان';
    if (days <= 10) return 'تجربة مجانية · متبقي $days أيام';
    return 'تجربة مجانية · متبقي $days يومًا';
  }

  static const activationStorageError =
      'تعذر قراءة بيانات التفعيل. حاول مرة أخرى.';
  static const activationCodeError =
      'تعذر التفعيل. تأكد من الكود ومعرّف الجهاز وصلاحية الاشتراك.';
  static const activationUnconfigured =
      'نسخة التطبيق غير مهيأة للتحقق من أكواد التفعيل. تواصل مع الدعم.';
  static const activationUnlimited = 'الاشتراك غير محدد بعدد جلسات.';
  static String activationRemaining(int count) =>
      'الجلسات المتبقية على هذا الجهاز: $count';
  static const installationCopied = 'تم نسخ المعرّف.';
  static const copyInstallation = 'نسخ المعرّف';
  static const activationCode = 'كود التفعيل';
  static const activating = 'جارٍ التحقق...';
  static const activate = 'تفعيل';
  static const retry = 'إعادة المحاولة';
  static const activationLinkFailure =
      'تعذر تفعيل الرابط. تأكد أنه مخصص لهذا الجهاز ولم تنتهِ صلاحيته.';
  static const activationLinkSuccess = 'تم تفعيل الاشتراك على هذا الجهاز.';
  static const activationReplaceTitle = 'تغيير الاشتراك؟';
  static const activationReplaceBody =
      'سيصبح الاشتراك الموجود في الرابط هو الاشتراك الحالي على هذا الجهاز.';
  static const activationReplaceConfirm = 'تفعيل الاشتراك الجديد';
  static const navHome = 'الرئيسية';
  static const navPlay = 'الأنشطة';
  static const navFavorites = 'المفضلة';
  static const navHelp = 'المساعدة';
  static const discTitle = 'استكشف أسلوبك';
  static const discHint = 'أسئلة مستوحاة من نموذج DISC للحوار';
  static const discDisclaimer =
      'تمرين للتأمل مستوحى من DISC، وليس اختبارًا معتمدًا أو تشخيصًا نفسيًا ولا يقيس التوافق. لا يوجد أسلوب أفضل من آخر.';
  static const discPrivacy =
      'الاختيارات والملاحظات مؤقتة على الجهاز وتُحذف عند الخروج. الملاحظات لا تدخل في النتيجة.';
  static const discStart = 'ابدأ الاستكشاف';
  static const discNote = 'اكتب ملاحظة لنفسك (اختياري)';
  static const discResult = 'ميول ظهرت في اختياراتك';
  static const discAgain = 'ابدأ من جديد';
  static const discExitTitle = 'الخروج من الاستكشاف؟';
  static const discExitBody = 'ستُحذف اختياراتك وملاحظاتك المؤقتة.';
  static const discExit = 'خروج';
  static const discStay = 'متابعة';
  static const playTitle = 'يلا نلعب ونتكلم';
  static const playSubtitle = 'اختاروا لعبة، وكل واحد يشارك على راحته.';
  static const playScenarios = 'لو حصل كده؟';
  static const playScenariosHint = 'مواقف بسيطة تفتح باب النقاش';
  static const playPriorities = 'رتّب أولوياتك';
  static const playPrioritiesHint = 'اختاروا الأهم واتكلموا عن السبب';
  static const playStart = 'ابدأ اللعب';
  static const playNext = 'بطاقة تانية';
  static const playReset = 'إعادة الترتيب';
  static const playOrderHint =
      'اضغطوا على الخيارات بالترتيب المناسب لكم. اضغطوا مرة أخرى لإلغاء الاختيار.';
  static const playChoiceNote = 'الترتيب مؤقت على هذا الجهاز ولا يتم حفظه.';
  static const playReviewNotice =
      'الأنشطة تجريبية ولم تُراجع شرعيًا أو أسريًا بعد.';
  static const playNoCards = 'لا توجد بطاقات متاحة لهذه اللعبة حاليًا.';
  static const playRetry = 'تعذر تحميل الأنشطة. حاول مرة أخرى.';
  static const playPrompts = 'اتكلموا مع بعض';
  static String playProgress(int current, int total) =>
      'بطاقة $current من $total';

  // App Branding & Meta
  static const appName = 'وفاق';
  static const appLogoSemantics = 'رمز وفاق';
  static const welcomeTitle = 'أهلًا بكم في وفاق';
  static const heroSubtitle = 'حوار يقرّب الفهم';
  static const heroDescription =
      'مساحة تساعدكم تفتحوا مواضيع مهمة، وتفهموا بعض بهدوء واحترام.';
  static const startConversation = 'ابدأ جلسة';

  // Mode Selection
  static const chooseModeSectionTitle = 'اختاروا طريقة الحوار';
  static const chooseModeSectionSubtitle = 'ابدأوا بالطريقة المناسبة لكم';
  static const modeTogetherTitle = 'مع بعض';
  static const modeTogetherSubtitle = 'حوار مباشر من جهاز واحد';
  static const modePhoneTitle = 'في مكالمة';
  static const modePhoneSubtitle = 'اقرأوا الأسئلة خلال مكالمة خارج التطبيق';
  static const phoneNotice =
      'افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.';

  // Notice & Disclaimer
  static const sampleNotice =
      'الأسئلة تجريبية ولم تُراجع شرعيًا أو أسريًا بعد. هذه نسخة أولية قيد التطوير.';
  static const sampleNoticeSetup =
      'أسئلة تجريبية للاختبار فقط، لم تُراجع شرعيًا أو أسريًا بعد.';
  static const sessionPacingNotice =
      'خدوا وقتكم. من حق أي طرف تخطي السؤال، والتطبيق لا يسجل إجاباتكما.';

  // Session Setup
  static const setupTitle = 'إعداد الجلسة';
  static const setupHeader = 'خلّوا الحوار على راحتكم';
  static const setupSubheader = 'اختاروا التفاصيل المناسبة لكم.';
  static const setupSectionMode = 'طريقة الحوار';
  static const setupSectionTopic = 'الموضوع';
  static const setupSectionDepth = 'عمق الحوار';
  static const setupSectionCount = 'عدد الأسئلة';
  static const quickCount = 'اختيار سريع';
  static const newQuestionsTitle = 'أسئلة جديدة';
  static const avoidPreviousQuestions = 'تجنب الأسئلة السابقة';
  static const historyUnavailable =
      'تحتاج هذه الميزة إلى حفظ السجل على الجهاز.';
  static const historyExplanation =
      'يسجّل التطبيق أسئلة الجلسة عند بدايتها على هذا الجهاز فقط. عند نفاد الأسئلة الجديدة، غيّر اختياراتك أو أوقف الخيار.';
  static const noNewQuestions =
      'لا توجد أسئلة جديدة لهذه الاختيارات. غيّر اختياراتك أو أوقف تجنب التكرار.';
  static String newQuestionCount(int available, int total) =>
      'الجديدة: $available من $total';
  static const availableCountPrefix = 'المتاح';
  static const decreaseQuestionsTooltip = 'تقليل عدد الأسئلة';
  static const increaseQuestionsTooltip = 'زيادة عدد الأسئلة';
  static const startSessionButton = 'ابدأ الجلسة';

  // Session Dialogue
  static const sessionModePrefix = 'جلسة';
  static const sessionCardTitle = 'مساحة للحوار';
  static String questionProgress(int current, int total) =>
      'السؤال $current من $total';
  static const nextButton = 'التالي';
  static const finishSessionButton = 'إنهاء الجلسة';
  static const previousButton = 'السابق';
  static const skipButton = 'تخطي';

  // Session Completion & Summary
  static const sessionFinishedTitle = 'انتهت الجلسة';
  static String discussedQuestions(int count) =>
      'الأسئلة التي انتقلتم منها: $count';
  static String skippedQuestions(int count) => 'الأسئلة المتخطاة: $count';
  static const returnToSetup = 'العودة لإعداد الجلسة';

  // Exit Dialog
  static const exitDialogTitle = 'إنهاء الجلسة؟';
  static const exitDialogContent = 'إنهاء الجلسة يحذف تقدمها المحفوظ.';
  static const continueSessionAction = 'متابعة الجلسة';
  static const exitSessionAction = 'إنهاء';

  // Session Resumption
  static const resumeCardTitle = 'جلسة سابقة غير مكتملة';
  static const resumeSessionButton = 'استئناف الجلسة';
  static const discardSessionButton = 'تجاهل';
  static const discardDialogTitle = 'تجاهل الجلسة السابقة؟';
  static const discardDialogContent = 'سيتم حذف التقدم المحفوظ للجلسة السابقة.';
  static const discardConfirmAction = 'تأكيد الحذف';
  static const cancelAction = 'إلغاء';

  // Topic Labels
  static const topicCommunication = 'التواصل';
  static const topicDailyLife = 'الحياة اليومية';
  static const topicFamilyRelations = 'الأهل والحدود';
  static const topicFinances = 'المالية والتطلعات';
  static const topicValues = 'القيم والمبادئ';
  static const topicMixed = 'مزيج شامل';

  // Favorites
  static const favoritesTitle = 'أسئلة تهمنا';
  static const favoritesSubtitle =
      'أسئلة اخترتم حفظها للرجوع إليها والتفكير فيها لاحقًا.';
  static const emptyFavoritesMessage =
      'لم تحفظوا أي أسئلة بعد. يمكنكم الضغط على رمز النجمة أثناء الجلسة لحفظ أي سؤال.';
  static const addToFavoritesTooltip = 'حفظ في أسئلة تهمنا';
  static const removeFromFavoritesTooltip = 'إزالة من أسئلة تهمنا';
  static const favoritesBadge = 'محفوظة محليًا';

  // Depth Labels
  static const depthIntroductory = 'تمهيدي';
  static const depthDeeper = 'أعمق';

  // Activities & Scenarios
  static const activitiesTitle = 'أنشطة ومواقف للنقاش';
  static const activitiesSubtitle =
      'سيناريوهات واقعية وترتيب أولويات لتبادل الآراء بهدوء.';
  static const emptyActivitiesMessage =
      'لا توجد أنشطة متوفرة للتصنيف المحدد حاليًا.';
  static const allActivitiesTab = 'الكل';
  static const scenariosTab = 'سيناريوهات';
  static const prioritiesTab = 'ترتيب أولويات';

  // Licensing & Activation
  static const licenseStatusTitle = 'حالة الاشتراك';
  static const trialStatusLabel = 'جلسات تجريبية مجانية';
  static const activeStatusLabel = 'اشتراك ساري (جهازين)';
  static const expiredStatusLabel = 'انتهت فترة الاشتراك';
  static const quotaExhaustedStatusLabel = 'تم استهلاك جميع الجلسات';
  static const remainingQuotaPrefix = 'الجلسات المتبقية:';
  static const activateCodeButton = 'تفعيل رمز اشتراك';
  static const activationDialogTitle = 'تفعيل رمز الاشتراك';
  static const activationDialogDescription =
      'أدخل رمز التفعيل المخصص لحسابكما (يربط جهازين معًا):';
  static const codeFieldLabel = 'رمز التفعيل';
  static const codeFieldHint = 'مثال: WFQ-COUPLE-2026';
  static const confirmActivationButton = 'تأكيد التفعيل';
  static const activationSuccessTitle = 'تم تفعيل الاشتراك بنجاح!';
  static const quotaExhaustedWarning =
      'استنفدتم جميع الجلسات المتاحة في باقتكم الحالية. يمكنكم تفعيل رمز اشتراك جديد للمتابعة.';

  // Support & Help
  static const supportTitle = 'الدعم والمساعدة';
  static const supportSubtitle =
      'إجابات على الأسئلة الشائعة وتواصل مباشر مع خدمة العملاء.';
  static const faqSectionTitle = 'الأسئلة الشائعة';
  static const contactSectionTitle = 'تواصل مع خدمة العملاء';
  static const installationIdLabel = 'معرف التثبيت الخاص بجهازك:';
  static const copyInstallationIdButton = 'نسخ معرف التثبيت';
  static const installationIdCopiedMessage = 'تم نسخ معرف التثبيت إلى الحافظة';
  static const openWhatsAppSupport = 'تواصل عبر واتساب';
  static const supportWorkingHours =
      'ساعات العمل: يوميًا من 10 صباحًا حتى 10 مساءً (بتوقيت القاهرة)';
  static const privacyTermsSummaryTitle = 'الخصوصية والشفافية التامة';
  static const privacyTermsSummaryBody =
      'وفاق لا يطلب إنشاء حساب، ولا يسجل إجاباتكم أو مكالماتكم، وتظل جميع تفضيلاتكم محفوظة على أجهزتكم فقط وفقًا لقانون حماية البيانات الشخصية.';

  // Errors & Empty states
  static const noQuestionsAvailable = 'لا تتوفر أسئلة مطابقة للخيارات المحددة.';

  // Enhanced UI Strings
  static const activationPasteCode = 'لصق الكود';
  static const activationPasted = 'تم لصق الكود من الحافظة.';
  static const activationClipboardEmpty = 'الحافظة فارغة.';
  static const activationRequestCode = 'طلب كود تفعيل عبر التواصل';
  static const activationCurrentLicense = 'بيانات التفعيل الحالي';
  static const activationLicenseId = 'رقم الترخيص';
  static const activationExpiryDate = 'صالح حتى';
  static const activationNoExpiry = 'غير محدد بتاريخ';
  static const activationUnconfiguredHint =
      'أضف المفتاح العام WEFAQ_LICENSE_PUBLIC_KEY في ملف .env أو عبر --dart-define لتفعيل التحقق من الأكواد.';
  static const copyQuestionTooltip = 'نسخ نص السؤال';
  static const questionCopiedMessage = 'تم نسخ نص السؤال.';
  static const reviewSkippedQuestions = 'مراجعة الأسئلة المتخطاة';
  static const favoritesSearchHint = 'ابحث داخل أسئلتك المحفوظة...';
  static const reviewFavoritesAsCards = 'تصفح المفضلة كبطاقات حوار';
  static const savedFeedbackTitle = 'ملاحظاتك المحفوظة محليًا';
  static const viewSavedFeedback = 'عرض الملاحظات المحفوظة';
  static const noSavedFeedback = 'لا توجد ملاحظات محفوظة محليًا بعد.';
  static const clearSavedFeedback = 'حذف سجل الملاحظات';
  static const contentSyncTitle = 'تحديث الأسئلة والأنشطة';
  static const syncContentNow = 'تحديث المحتوى الآن';
  static const previousCard = 'البطاقة السابقة';
}
