/// Centralized user-facing strings for Wefaq (Arabic RTL).
abstract final class AppStrings {
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
  static const prototypeBadge = 'نسخة تجريبية';
  static const welcomeTitle = 'أهلًا بكم في وفاق';
  static const heroSubtitle = 'حوار يقرّب الفهم';
  static const heroDescription =
      'مساحة تساعدكم تفتحوا مواضيع مهمة، وتفهموا بعض بهدوء واحترام.';
  static const startPrototypeSession = 'ابدأ جلسة تجريبية';

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
}
