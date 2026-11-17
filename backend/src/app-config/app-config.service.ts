import {
  BadRequestException,
  Inject,
  Injectable,
  Optional,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import {
  createJsonDocumentStore,
  JsonDocumentStore,
  loadSeedFileOrFallback,
} from '../common/storage/json-document.store';
import { isPlainObject } from '../question-catalog/question-catalog.validator';
import {
  AnnouncementStyle,
  AppConfigSnapshot,
  SampleTopicKey,
  SiteContentConfig,
  SiteFaqItem,
  SiteFeatureCard,
  SiteSampleItem,
  SiteStepItem,
} from './app-config.types';

export const APP_CONFIG_STORE = Symbol('APP_CONFIG_STORE');

const SAMPLE_TOPIC_KEYS: readonly SampleTopicKey[] = [
  'communication',
  'dailyLife',
  'familyRelations',
  'finances',
  'coreValues',
];

export const FALLBACK_SITE_CONTENT: SiteContentConfig = {
  meta: {
    brandName: 'وفاق',
    pageTitle: 'وفاق | مساحة حوار هادئة للمقبلين على الزواج',
    footerText: 'جميع الحقوق محفوظة © وفاق 2026 | تواصل مباشر وخصوصية تامة',
  },
  hero: {
    primaryCtaLabel: 'تواصل لطلب التفعيل أو الاستفسار',
    secondaryCtaLabel: 'تصفح نماذج الأسئلة',
    downloadCtaLabel: 'تنزيل التطبيق (أسبوعان مجانًا)',
    trustPills: [
      '✓ تجربة مجانية أسبوعين فور التثبيت',
      '✓ يعمل دون إنترنت ويُغلق تلقائيًا بعد 14 يومًا',
      '✓ خصوصية 100% بدون حسابات',
      '✓ تفعيل مباشر بعد التجربة بدون دفع إلكتروني',
    ],
    mockupTitle: 'أهلًا بكم في وفاق',
    mockupSubtitle:
      'مساحة تساعدكم تفتحوا مواضيع مهمة، وتفهموا بعض بهدوء واحترام.',
    mockupQuestion: 'إيه الطريقة اللي بتحب حد يسمعك بيها؟',
    mockupClarify: 'معرفة كيف يفضل كل طرف التفاعل والإنصات دون مقاطعة.',
  },
  sections: {
    showFeatures: true,
    featuresBadge: 'لماذا وفاق؟',
    featuresTitle: 'مصمم لحوار ناضج ومريح',
    featuresSubtitle:
      'كل تفصيلة في وفاق تهدف لإزالة التوتر وإتاحة مساحة صادقة للتعارف الواعي.',
    showExplorer: true,
    explorerBadge: '5 محاور حياتية شاملة',
    explorerTitle: 'تصفح نماذج من أسئلة وفاق',
    explorerSubtitle:
      'أسئلة متدرجة من التمهيدي إلى الأعمق مع توضيح للهدف من كل سؤال.',
    showActivities: true,
    activitiesBadge: 'أكثر من مجرد أسئلة',
    activitiesTitle: 'أنشطة وتفاعلات لكسر الجمود',
    activitiesSubtitle:
      'ألعاب حوارية هادئة تكشف طريقة التفكير والأولويات الواقعية دون أي تقييمات قسرية.',
    showHowItWorks: true,
    howItWorksBadge: 'خطوات واضحة وبسيطة',
    howItWorksTitle: 'كيف تبدأ استخدام وفاق؟',
    howItWorksSubtitle:
      'ابدأ مجانًا لمدة أسبوعين فور التثبيت، وعند انتهاء المهلة تواصل معنا لتفعيل جهازيكما — بدون أي بوابات دفع في الموقع.',
    showContact: true,
    contactBadge: 'تواصل مباشر فقط — بدون دفع',
    contactTitle: 'تواصل مع فريق وفاق',
    contactSubtitle:
      'أرسل استفسارك، اطلب كود تفعيل لجهازك، أو شاركنا ملاحظاتك عبر الرسالة الجاهزة أدناه.',
    showFaq: true,
    faqBadge: 'الأسئلة الشائعة',
    faqTitle: 'إجابات واضحة وشفافة',
    showBoundaries: true,
  },
  featuresCards: [
    {
      icon: '🤝',
      title: 'مع بعض أو في مكالمة',
      description:
        'استخدموا التطبيق سويًا من جهاز واحد في اللقاءات العائلية، أو اقرأوا الأسئلة بسلاسة أثناء مكالمتكم الهاتفية المعتادة.',
    },
    {
      icon: '🔒',
      title: 'خصوصية مطلقة 100%',
      description:
        'بدون إنشاء حسابات، وبدون ميكروفون أو تسجيل إجابات. الجلسات والمفضلة تُحفظ محليًا على هاتفك فقط.',
    },
    {
      icon: '🗝️',
      title: 'تجربة أسبوعين ثم تفعيل موقّع',
      description:
        'ابدأ مجانًا لمدة 14 يومًا فور التثبيت حتى دون إنترنت، ثم يُغلق التطبيق تلقائيًا بعد الأسبوعين للمطالبة بكود تفعيل موقّع لجهازك أو جهازيكما.',
    },
    {
      icon: '🎯',
      title: 'مفضلة ومنع تكرار الأسئلة',
      description:
        'احفظ الأسئلة التي تهمكما للعودة إليها لاحقًا، وفعّل خيار تجنب الأسئلة السابقة لفتح آفاق جديدة في كل جلسة.',
    },
    {
      icon: '⏸️',
      title: 'حرية كاملة دون ضغط',
      description:
        'لكل طرف الحق في تخطي أي سؤال دون إحراج، مع إمكانية إيقاف الجلسة واستئنافها لاحقًا من نفس النقطة.',
    },
    {
      icon: '🔄',
      title: 'يعمل دون إنترنت مع تحديثات دورية',
      description:
        'مكتبة الأسئلة والأنشطة متوفرة معك دون اتصال، مع خيار تحديث الكتالوج يدويًا عند الرغبة دون المساس بخصوصيتك.',
    },
  ],
  activitiesCards: [
    {
      icon: '💬',
      title: 'لو حصل كده؟ (سيناريوهات)',
      description:
        'مواقف حياتية واقعية مثل تغيير المواعيد المفاجئ أو ضغط العمل، مع محاور نقاش تساعدكما على الاتفاق قبل حدوث الموقف.',
    },
    {
      icon: '📊',
      title: 'رتّب أولوياتك',
      description:
        'تمارين لترتيب أولويات الميزانية أو وقت العطلة أو إدارة الخلافات، ومقارنة أسباب كل طرف بهدوء وتفهم.',
    },
    {
      icon: '🧭',
      title: 'استكشف أسلوبك (مستوحى من DISC)',
      description:
        'تمرين تأملي اختياري يساعد كل طرف على فهم أسلوب تواصله المفضل. هو نشاط استكشافي فقط وليس اختبارًا تشخيصيًا أو مقياس توافق.',
    },
  ],
  steps: [
    {
      title: 'ثبّت التطبيق وابدأ مجانًا لمدة أسبوعين',
      description:
        'افتح وفاق بعد التثبيت مباشرة وابدأ الجلسات والأنشطة مجانًا لمدة 14 يومًا دون كود أو اتصال بالإنترنت.',
    },
    {
      title: 'يُغلق التطبيق تلقائيًا بعد الأسبوعين',
      description:
        'بعد انتهاء الـ 14 يومًا (حتى دون إنترنت) يُغلق الوصول تلقائيًا وتظهر شاشة التفعيل ومعرّف التثبيت الخاص بجهازك (inst_).',
    },
    {
      title: 'تواصل معنا لاستلام كود التفعيل',
      description:
        'أرسل معرّف التثبيت (لجهازك أو جهازيكما) عبر الواتساب أو البريد لتستلم كود أو رابط التفعيل الموقّع وتتابع الحوار.',
    },
  ],
  contactForm: {
    reasons: [
      'طلب كود تفعيل لتطبيق وفاق (بعد انتهاء الأسبوعين)',
      'نقل التفعيل لجهاز جديد أو تجديد الصلاحية',
      'استفسار عام عن النظام أو التجربة المجانية',
      'اقتراح تطوير أو ملاحظة على المحتوى',
    ],
    namePlaceholder: 'مثال: أحمد',
    notesPlaceholder: 'اكتب استفسارك أو أضف معرّف الجهاز الثاني إن وجد...',
    previewHeading: 'معاينة الرسالة الجاهزة',
    previewHint:
      'راجع النص التالي ثم اختر وسيلة التواصل المناسبة لك (لن يتم إرسال أي شيء إلا بعد ضغطك على الإرسال):',
  },
  faq: [
    {
      question: 'هل التطبيق مجاني في البداية أم يحتاج تفعيلًا فوريًا؟',
      answer:
        'يمكنك تنزيل وفاق واستخدامه فورًا مجانًا لمدة أسبوعين (14 يومًا) دون كود أو إنترنت. بعد انتهاء الأسبوعين يُغلق التطبيق تلقائيًا حتى في وضع عدم الاتصال، وتظهر شاشة التفعيل لإدخال كود أو رابط التفعيل.',
    },
    {
      question: 'هل يسجل التطبيق صوت المكالمة أو إجاباتنا؟',
      answer:
        'لا مطلقًا. وفاق لا يطلب إذن الميكروفون ولا يسجل أي مكالمات أو إجابات؛ هو أداة لعرض الأسئلة وتنظيم الحوار، وكل اختيارات الجلسة والمفضلة تبقى محليًا على هاتفك.',
    },
    {
      question: 'كيف أحصل على كود التفعيل بعد انتهاء الأسبوعين أو أنقله لجهاز جديد؟',
      answer:
        'عند انتهاء الفترة التجريبية أو من شاشة التفعيل انسخ معرّف التثبيت (يبدأ بـ inst_) ثم تواصل معنا عبر قسم «تواصل معنا» لإصدار كود أو رابط التفعيل المخصص لجهازك أو استبدال جهاز مفقود.',
    },
    {
      question: 'هل توجد عمليات دفع أو اشتراكات إلكترونية داخل الموقع أو التطبيق؟',
      answer:
        'لا، هذا الموقع تعريفي وتواصلي فقط ولا يتضمن أي بوابات دفع أو تحصيل إلكتروني. كل الطلبات والاستفسارات تتم عبر التواصل المباشر مع فريق الدعم.',
    },
    {
      question: 'هل يعمل التطبيق بدون اتصال بالإنترنت؟',
      answer:
        'نعم، تعمل الجلسات والأنشطة والمفضلة — وكذلك احتساب مهلة التجربة المجانية والإغلاق التلقائي بعد أسبوعين — بالكامل دون إنترنت. يتصل التطبيق بالإنترنت فقط عند ضغطك يدويًا على «تحديث الأسئلة».',
    },
  ],
  boundaries: {
    whatIsTitle: 'ما هو نظام وفاق؟',
    whatIsItems: [
      'مساعد حواري منظم للمخطوبين والمقبلين على الزواج (18+).',
      'أسئلة متدرجة وأنشطة واقعية تحفّز الفهم المتبادل باحترام.',
      'تصميم يضع الخصوصية الكاملة وعدم تسجيل الإجابات كأولوية قصوى.',
    ],
    whatIsNotTitle: 'ما الذي ليس وفاقًا؟',
    whatIsNotItems: [
      'ليس تطبيق تعارف أو مطابقة أو محادثة ومكالمات مدمجة.',
      'لا يقدّم فتاوى شرعية ولا استشارات نفسية أو طبية متخصصة.',
      'لا يحسب نسب توافق رقمية ولا يضمن نتائج الزواج.',
    ],
  },
  privacyPage: {
    badge: 'الشفافية وحماية الخصوصية',
    title: 'سياسة الخصوصية وحدود الاستخدام',
    subtitle:
      'صُمم نظام وفاق من الأساس لاحترام خصوصية المقبلين على الزواج، بحيث يظل حوارهما ملكًا لهما وحدهما دون تسجيل أو تتبع.',
  },
  sampleQuestions: {
    communication: [
      {
        question: 'إيه اللي بيساعدك تتكلم براحة عن يومك؟',
        clarification: 'الهدف معرفة أسلوب الاستماع والتواصل المفضل.',
      },
      {
        question:
          'لما يحصل سوء تفاهم، بتفضل نتكلم فورًا ولا ناخد وقت نهدى الأول؟',
        clarification: 'يساعد على وضع قاعدة محترمة لوقت النقاش عند الاختلاف.',
      },
      {
        question: 'إيه الطريقة اللي بتحسسك بالتقدير والاحتواء في الكلام؟',
        clarification: 'معرفة اللغات والكلمات التي تترك أثرًا طيبًا.',
      },
    ],
    dailyLife: [
      {
        question: 'إزاي بتشوف توزيع المسؤوليات اليومية في البيت؟',
        clarification: 'مناقشة التوقعات الواقعية للتعاون والمشاركة.',
      },
      {
        question: 'بتحب تقضي يوم الإجازة الأسبوعية إزاي في العادي؟',
        clarification: 'التنسيق بين الحاجة للراحة والأنشطة والزيارات.',
      },
      {
        question: 'إيه العادات اليومية الصباحية أو المسائية اللي بتفرق معاك؟',
        clarification: 'فهم إيقاع اليوم الشخصي لكل طرف.',
      },
    ],
    familyRelations: [
      {
        question: 'إزاي نوازن بين بر الأهل وخصوصية قرارات بيتنا؟',
        clarification: 'توضيح الحدود الصحية بين الود الأسري والاستقلال.',
      },
      {
        question: 'ما المناسبات العائلية اللي بتحرص على حضورها باستمرار؟',
        clarification: 'فهم أولويات التواصل مع العائلتين.',
      },
      {
        question: 'لو حصل تدخل غير مقصود من حد قريب، نتعامل معاه إزاي؟',
        clarification: 'الاتفاق على أسلوب مهذب وواحد لحفظ الاحترام.',
      },
    ],
    finances: [
      {
        question: 'ما أولوياتك في الادخار مقابل المصروفات والترفيه؟',
        clarification: 'فهم العقلية المالية والأمان المادي لكل طرف.',
      },
      {
        question: 'إزاي نخطط للالتزامات والظروف المالية الطارئة؟',
        clarification: 'بناء رؤية هادئة لمواجهة التحديات المادية معًا.',
      },
      {
        question: 'إيه الأهداف المالية اللي تحب نحققها في أول سنتين؟',
        clarification: 'تقريب الطموحات والخطط العملية للمستقبل.',
      },
    ],
    coreValues: [
      {
        question: 'ما المبادئ اللي ما بتتغيرش عندك في أصعب القرارات؟',
        clarification: 'استكشاف البوصلة الأخلاقية والقيمية المشتركة.',
      },
      {
        question: 'إيه أهم قيمة نفسك نربي عليها أولادنا بإذن الله؟',
        clarification: 'التعرف على الرؤية التربوية المستقبلية.',
      },
      {
        question: 'إيه مفهومك عن السكينة والمودة في الحياة الزوجية؟',
        clarification: 'مشاركة الصورة الذهنية لمعنى البيت المستقر.',
      },
    ],
  },
};

export const FALLBACK_APP_CONFIG: AppConfigSnapshot = {
  schemaVersion: 1,
  revision: 2,
  updatedAt: '2026-11-17T15:00:00Z',
  contact: {
    whatsappNumber: '',
    whatsappDisplay: 'فتح في واتساب',
    email: 'support@wefaq.app',
    supportHours: 'يوميًا من 10 صباحًا حتى 10 مساءً (بتوقيت القاهرة)',
    contactMessageTemplate: 'السلام عليكم، أود التواصل مع فريق وفاق:',
    telegramUrl: '',
    telegramDisplay: 'تواصل عبر تيليجرام',
    phoneDisplay: '',
    websiteUrl: 'https://wefaq-site.vercel.app',
  },
  announcement: {
    enabled: true,
    title: 'تجربة مجانية',
    message:
      'ابدأ استخدام التطبيق مجانًا فور التثبيت لمدة أسبوعين (14 يومًا) حتى دون إنترنت — وبعد انتهاء المدة يُغلق تلقائيًا لطلب التفعيل.',
    style: 'success',
  },
  appRelease: {
    latestVersion: '0.2.0+16',
    minSupportedVersion: '0.1.0+1',
    releaseNotes:
      'تفعيل تلقائي لفترة تجريبية مجانية لمدة أسبوعين (14 يومًا) تعمل دون إنترنت وتُغلق تلقائيًا عند الانتهاء لطلب التفعيل.',
    downloadUrl:
      'https://github.com/abdo6400/wefaq/releases/latest/download/app-release.apk',
  },
  features: {
    quickSparkEnabled: true,
    activitiesEnabled: true,
    discEnabled: true,
    feedbackEnabled: true,
  },
  branding: {
    badgeText: 'تجربة مجانية أسبوعين دون إنترنت — للمقبلين على الزواج',
    heroTitle: 'حوار يقرّب الفهم بهدوء واحترام',
    heroSubtitle:
      'مساحة منظمة تساعد المخطوبين على فتح المواضيع الأساسية للحياة المشتركة، وفهم أولويات كل طرف دون ضغط أو إحراج. ابدأ مجانًا لمدة أسبوعين فور التثبيت حتى دون إنترنت، ثم يُغلق التطبيق تلقائيًا للتفعيل الدائم بخصوصية كاملة.',
    siteNotice:
      'التواصل مباشر عبر فريق الدعم بدون أي معاملات مالية أو دفع إلكتروني داخل الموقع.',
  },
  site: FALLBACK_SITE_CONTENT,
};

@Injectable()
export class AppConfigService {
  private readonly store: JsonDocumentStore<AppConfigSnapshot>;
  private cached: AppConfigSnapshot | null = null;
  private versionTag: string | undefined;
  private mutationTail: Promise<unknown> = Promise.resolve();

  constructor(
    @Optional()
    @Inject(APP_CONFIG_STORE)
    store?: JsonDocumentStore<AppConfigSnapshot>,
  ) {
    this.store =
      store ??
      createJsonDocumentStore<AppConfigSnapshot>({
        filename: 'app-config.v1.json',
        blobPathname: 'wefaq/app-config.v1.json',
        envPathVar: 'APP_CONFIG_FILE_PATH',
        seedFactory: () =>
          loadSeedFileOrFallback('app-config.v1.json', () => FALLBACK_APP_CONFIG),
      });
  }

  async getConfig(): Promise<{
    readonly config: AppConfigSnapshot;
    readonly etag: string;
    readonly serializedJson: string;
  }> {
    const loaded = await this.store.loadLatest(this.versionTag);
    if (loaded) {
      this.cached = normalizeSnapshotWithDefaults(loaded.data);
      this.versionTag = loaded.versionTag;
    }
    const config = this.cached ?? FALLBACK_APP_CONFIG;
    const serializedJson = JSON.stringify(config);
    const hash = createHash('sha256')
      .update(serializedJson, 'utf8')
      .digest('hex')
      .slice(0, 16);
    const etag = `"cfg-v${config.schemaVersion}-r${config.revision}-${hash}"`;
    return { config, etag, serializedJson };
  }

  updateConfig(rawBody: unknown): Promise<AppConfigSnapshot> {
    if (!isPlainObject(rawBody)) {
      throw new BadRequestException('Request body must be a JSON object.');
    }

    const task = this.mutationTail.then(async () => {
      const { config: current } = await this.getConfig();
      const next = mergeAndValidateConfig(current, rawBody);
      const saved = await this.store.save(next, this.versionTag);
      this.cached = next;
      this.versionTag = saved.versionTag ?? this.versionTag;
      return next;
    });

    this.mutationTail = task.catch(() => undefined);
    return task;
  }
}

/**
 * Ensures older persisted JSON/Blob snapshots missing newer contact/site keys
 * cleanly receive FALLBACK defaults without mutating valid existing fields.
 */
function normalizeSnapshotWithDefaults(raw: unknown): AppConfigSnapshot {
  if (!isPlainObject(raw)) {
    return FALLBACK_APP_CONFIG;
  }
  const normalized = mergeAndValidateConfig(FALLBACK_APP_CONFIG, raw, true);
  return {
    ...normalized,
    revision:
      typeof raw.revision === 'number' && raw.revision >= 1
        ? Math.floor(raw.revision)
        : 1,
    updatedAt:
      typeof raw.updatedAt === 'string' && raw.updatedAt.trim().length > 0
        ? raw.updatedAt
        : FALLBACK_APP_CONFIG.updatedAt,
  };
}

function mergeAndValidateConfig(
  current: AppConfigSnapshot,
  raw: Record<string, unknown>,
  allowEmptyAnnouncement = false,
): AppConfigSnapshot {
  const contactRaw = isPlainObject(raw.contact) ? raw.contact : {};
  const announcementRaw = isPlainObject(raw.announcement)
    ? raw.announcement
    : {};
  const releaseRaw = isPlainObject(raw.appRelease) ? raw.appRelease : {};
  const featuresRaw = isPlainObject(raw.features) ? raw.features : {};
  const brandingRaw = isPlainObject(raw.branding) ? raw.branding : {};
  const siteRaw = isPlainObject(raw.site) ? raw.site : {};

  const whatsappNumber = parsePhoneOrEmpty(
    contactRaw.whatsappNumber,
    current.contact.whatsappNumber,
  );
  const downloadUrl = parseHttpsUrlOrEmpty(
    releaseRaw.downloadUrl,
    current.appRelease.downloadUrl,
    'appRelease.downloadUrl',
  );
  const telegramUrl = parseHttpsUrlOrEmpty(
    contactRaw.telegramUrl,
    current.contact.telegramUrl,
    'contact.telegramUrl',
  );
  const websiteUrl = parseHttpsUrlOrEmpty(
    contactRaw.websiteUrl,
    current.contact.websiteUrl,
    'contact.websiteUrl',
  );
  const style = parseAnnouncementStyle(
    announcementRaw.style,
    current.announcement.style,
  );

  const announcementEnabled = parseBool(
    announcementRaw.enabled,
    current.announcement.enabled,
    'announcement.enabled',
  );
  const announcementMessage = parseText(
    announcementRaw.message,
    current.announcement.message,
    500,
  );
  if (
    !allowEmptyAnnouncement &&
    announcementEnabled &&
    announcementMessage.length === 0
  ) {
    throw new BadRequestException(
      'Announcement message is required when announcement is enabled.',
    );
  }

  return {
    schemaVersion: 1,
    revision: current.revision + 1,
    updatedAt: new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'),
    contact: {
      whatsappNumber,
      whatsappDisplay: parseText(
        contactRaw.whatsappDisplay,
        current.contact.whatsappDisplay,
        100,
      ),
      email: parseText(contactRaw.email, current.contact.email, 160),
      supportHours: parseText(
        contactRaw.supportHours,
        current.contact.supportHours,
        200,
      ),
      contactMessageTemplate: parseText(
        contactRaw.contactMessageTemplate,
        current.contact.contactMessageTemplate,
        400,
      ),
      telegramUrl,
      telegramDisplay: parseText(
        contactRaw.telegramDisplay,
        current.contact.telegramDisplay,
        80,
      ),
      phoneDisplay: parseText(
        contactRaw.phoneDisplay,
        current.contact.phoneDisplay,
        60,
      ),
      websiteUrl,
    },
    announcement: {
      enabled: announcementEnabled,
      title: parseText(
        announcementRaw.title,
        current.announcement.title,
        120,
      ),
      message: announcementMessage,
      style,
    },
    appRelease: {
      latestVersion: parseText(
        releaseRaw.latestVersion,
        current.appRelease.latestVersion,
        40,
      ),
      minSupportedVersion: parseText(
        releaseRaw.minSupportedVersion,
        current.appRelease.minSupportedVersion,
        40,
      ),
      releaseNotes: parseText(
        releaseRaw.releaseNotes,
        current.appRelease.releaseNotes,
        600,
      ),
      downloadUrl,
    },
    features: {
      quickSparkEnabled: parseBool(
        featuresRaw.quickSparkEnabled,
        current.features.quickSparkEnabled,
        'features.quickSparkEnabled',
      ),
      activitiesEnabled: parseBool(
        featuresRaw.activitiesEnabled,
        current.features.activitiesEnabled,
        'features.activitiesEnabled',
      ),
      discEnabled: parseBool(
        featuresRaw.discEnabled,
        current.features.discEnabled,
        'features.discEnabled',
      ),
      feedbackEnabled: parseBool(
        featuresRaw.feedbackEnabled,
        current.features.feedbackEnabled,
        'features.feedbackEnabled',
      ),
    },
    branding: {
      badgeText: parseText(
        brandingRaw.badgeText,
        current.branding.badgeText,
        120,
      ),
      heroTitle: parseText(
        brandingRaw.heroTitle,
        current.branding.heroTitle,
        160,
      ),
      heroSubtitle: parseText(
        brandingRaw.heroSubtitle,
        current.branding.heroSubtitle,
        400,
      ),
      siteNotice: parseText(
        brandingRaw.siteNotice,
        current.branding.siteNotice,
        300,
      ),
    },
    site: mergeSiteContent(current.site, siteRaw),
  };
}

function mergeSiteContent(
  current: SiteContentConfig,
  raw: Record<string, unknown>,
): SiteContentConfig {
  const metaRaw = isPlainObject(raw.meta) ? raw.meta : {};
  const heroRaw = isPlainObject(raw.hero) ? raw.hero : {};
  const sectionsRaw = isPlainObject(raw.sections) ? raw.sections : {};
  const contactFormRaw = isPlainObject(raw.contactForm) ? raw.contactForm : {};
  const boundariesRaw = isPlainObject(raw.boundaries) ? raw.boundaries : {};
  const privacyRaw = isPlainObject(raw.privacyPage) ? raw.privacyPage : {};
  const samplesRaw = isPlainObject(raw.sampleQuestions)
    ? raw.sampleQuestions
    : {};

  return {
    meta: {
      brandName: parseText(metaRaw.brandName, current.meta.brandName, 60),
      pageTitle: parseText(metaRaw.pageTitle, current.meta.pageTitle, 140),
      footerText: parseText(metaRaw.footerText, current.meta.footerText, 240),
    },
    hero: {
      primaryCtaLabel: parseText(
        heroRaw.primaryCtaLabel,
        current.hero.primaryCtaLabel,
        80,
      ),
      secondaryCtaLabel: parseText(
        heroRaw.secondaryCtaLabel,
        current.hero.secondaryCtaLabel,
        80,
      ),
      downloadCtaLabel: parseText(
        heroRaw.downloadCtaLabel,
        current.hero.downloadCtaLabel,
        80,
      ),
      trustPills: parseStringList(
        heroRaw.trustPills,
        current.hero.trustPills,
        6,
        90,
        'site.hero.trustPills',
      ),
      mockupTitle: parseText(heroRaw.mockupTitle, current.hero.mockupTitle, 90),
      mockupSubtitle: parseText(
        heroRaw.mockupSubtitle,
        current.hero.mockupSubtitle,
        220,
      ),
      mockupQuestion: parseText(
        heroRaw.mockupQuestion,
        current.hero.mockupQuestion,
        180,
      ),
      mockupClarify: parseText(
        heroRaw.mockupClarify,
        current.hero.mockupClarify,
        240,
      ),
    },
    sections: {
      showFeatures: parseBool(
        sectionsRaw.showFeatures,
        current.sections.showFeatures,
        'site.sections.showFeatures',
      ),
      featuresBadge: parseText(
        sectionsRaw.featuresBadge,
        current.sections.featuresBadge,
        80,
      ),
      featuresTitle: parseText(
        sectionsRaw.featuresTitle,
        current.sections.featuresTitle,
        140,
      ),
      featuresSubtitle: parseText(
        sectionsRaw.featuresSubtitle,
        current.sections.featuresSubtitle,
        300,
      ),
      showExplorer: parseBool(
        sectionsRaw.showExplorer,
        current.sections.showExplorer,
        'site.sections.showExplorer',
      ),
      explorerBadge: parseText(
        sectionsRaw.explorerBadge,
        current.sections.explorerBadge,
        80,
      ),
      explorerTitle: parseText(
        sectionsRaw.explorerTitle,
        current.sections.explorerTitle,
        140,
      ),
      explorerSubtitle: parseText(
        sectionsRaw.explorerSubtitle,
        current.sections.explorerSubtitle,
        300,
      ),
      showActivities: parseBool(
        sectionsRaw.showActivities,
        current.sections.showActivities,
        'site.sections.showActivities',
      ),
      activitiesBadge: parseText(
        sectionsRaw.activitiesBadge,
        current.sections.activitiesBadge,
        80,
      ),
      activitiesTitle: parseText(
        sectionsRaw.activitiesTitle,
        current.sections.activitiesTitle,
        140,
      ),
      activitiesSubtitle: parseText(
        sectionsRaw.activitiesSubtitle,
        current.sections.activitiesSubtitle,
        300,
      ),
      showHowItWorks: parseBool(
        sectionsRaw.showHowItWorks,
        current.sections.showHowItWorks,
        'site.sections.showHowItWorks',
      ),
      howItWorksBadge: parseText(
        sectionsRaw.howItWorksBadge,
        current.sections.howItWorksBadge,
        80,
      ),
      howItWorksTitle: parseText(
        sectionsRaw.howItWorksTitle,
        current.sections.howItWorksTitle,
        140,
      ),
      howItWorksSubtitle: parseText(
        sectionsRaw.howItWorksSubtitle,
        current.sections.howItWorksSubtitle,
        300,
      ),
      showContact: parseBool(
        sectionsRaw.showContact,
        current.sections.showContact,
        'site.sections.showContact',
      ),
      contactBadge: parseText(
        sectionsRaw.contactBadge,
        current.sections.contactBadge,
        80,
      ),
      contactTitle: parseText(
        sectionsRaw.contactTitle,
        current.sections.contactTitle,
        140,
      ),
      contactSubtitle: parseText(
        sectionsRaw.contactSubtitle,
        current.sections.contactSubtitle,
        300,
      ),
      showFaq: parseBool(
        sectionsRaw.showFaq,
        current.sections.showFaq,
        'site.sections.showFaq',
      ),
      faqBadge: parseText(
        sectionsRaw.faqBadge,
        current.sections.faqBadge,
        80,
      ),
      faqTitle: parseText(
        sectionsRaw.faqTitle,
        current.sections.faqTitle,
        140,
      ),
      showBoundaries: parseBool(
        sectionsRaw.showBoundaries,
        current.sections.showBoundaries,
        'site.sections.showBoundaries',
      ),
    },
    featuresCards: parseFeatureCards(
      raw.featuresCards,
      current.featuresCards,
      8,
      'site.featuresCards',
    ),
    activitiesCards: parseFeatureCards(
      raw.activitiesCards,
      current.activitiesCards,
      6,
      'site.activitiesCards',
    ),
    steps: parseSteps(raw.steps, current.steps, 5),
    contactForm: {
      reasons: parseStringList(
        contactFormRaw.reasons,
        current.contactForm.reasons,
        10,
        120,
        'site.contactForm.reasons',
      ),
      namePlaceholder: parseText(
        contactFormRaw.namePlaceholder,
        current.contactForm.namePlaceholder,
        80,
      ),
      notesPlaceholder: parseText(
        contactFormRaw.notesPlaceholder,
        current.contactForm.notesPlaceholder,
        180,
      ),
      previewHeading: parseText(
        contactFormRaw.previewHeading,
        current.contactForm.previewHeading,
        100,
      ),
      previewHint: parseText(
        contactFormRaw.previewHint,
        current.contactForm.previewHint,
        240,
      ),
    },
    faq: parseFaqList(raw.faq, current.faq, 12),
    boundaries: {
      whatIsTitle: parseText(
        boundariesRaw.whatIsTitle,
        current.boundaries.whatIsTitle,
        100,
      ),
      whatIsItems: parseStringList(
        boundariesRaw.whatIsItems,
        current.boundaries.whatIsItems,
        8,
        220,
        'site.boundaries.whatIsItems',
      ),
      whatIsNotTitle: parseText(
        boundariesRaw.whatIsNotTitle,
        current.boundaries.whatIsNotTitle,
        100,
      ),
      whatIsNotItems: parseStringList(
        boundariesRaw.whatIsNotItems,
        current.boundaries.whatIsNotItems,
        8,
        220,
        'site.boundaries.whatIsNotItems',
      ),
    },
    privacyPage: {
      badge: parseText(privacyRaw.badge, current.privacyPage.badge, 80),
      title: parseText(privacyRaw.title, current.privacyPage.title, 140),
      subtitle: parseText(privacyRaw.subtitle, current.privacyPage.subtitle, 400),
    },
    sampleQuestions: {
      communication: parseSampleItems(
        samplesRaw.communication,
        current.sampleQuestions.communication,
        'site.sampleQuestions.communication',
      ),
      dailyLife: parseSampleItems(
        samplesRaw.dailyLife,
        current.sampleQuestions.dailyLife,
        'site.sampleQuestions.dailyLife',
      ),
      familyRelations: parseSampleItems(
        samplesRaw.familyRelations,
        current.sampleQuestions.familyRelations,
        'site.sampleQuestions.familyRelations',
      ),
      finances: parseSampleItems(
        samplesRaw.finances,
        current.sampleQuestions.finances,
        'site.sampleQuestions.finances',
      ),
      coreValues: parseSampleItems(
        samplesRaw.coreValues,
        current.sampleQuestions.coreValues,
        'site.sampleQuestions.coreValues',
      ),
    },
  };
}

function parseStringList(
  raw: unknown,
  fallback: readonly string[],
  maxItems: number,
  maxLength: number,
  field: string,
): readonly string[] {
  if (raw === undefined) return fallback;
  if (!Array.isArray(raw)) {
    throw new BadRequestException(`Field "${field}" must be an array.`);
  }
  const items = raw
    .map((entry) => parseText(entry, '', maxLength))
    .filter((entry) => entry.length > 0);
  if (items.length > maxItems) {
    throw new BadRequestException(
      `Field "${field}" may contain at most ${maxItems} items.`,
    );
  }
  return items;
}

function parseFeatureCards(
  raw: unknown,
  fallback: readonly SiteFeatureCard[],
  maxItems: number,
  field: string,
): readonly SiteFeatureCard[] {
  if (raw === undefined) return fallback;
  if (!Array.isArray(raw)) {
    throw new BadRequestException(`Field "${field}" must be an array.`);
  }
  if (raw.length > maxItems) {
    throw new BadRequestException(
      `Field "${field}" may contain at most ${maxItems} cards.`,
    );
  }
  const cards: SiteFeatureCard[] = [];
  for (const item of raw) {
    if (!isPlainObject(item)) {
      throw new BadRequestException(`Items in "${field}" must be objects.`);
    }
    const title = parseText(item.title, '', 100);
    const description = parseText(item.description, '', 360);
    const icon = parseText(item.icon, '✨', 16) || '✨';
    if (!title && !description) continue;
    if (!title) {
      throw new BadRequestException(`Card title is required in "${field}".`);
    }
    cards.push({ icon, title, description });
  }
  return cards;
}

function parseSteps(
  raw: unknown,
  fallback: readonly SiteStepItem[],
  maxItems: number,
): readonly SiteStepItem[] {
  if (raw === undefined) return fallback;
  if (!Array.isArray(raw)) {
    throw new BadRequestException('Field "site.steps" must be an array.');
  }
  if (raw.length > maxItems) {
    throw new BadRequestException(
      `Field "site.steps" may contain at most ${maxItems} steps.`,
    );
  }
  const steps: SiteStepItem[] = [];
  for (const item of raw) {
    if (!isPlainObject(item)) {
      throw new BadRequestException('Items in "site.steps" must be objects.');
    }
    const title = parseText(item.title, '', 120);
    const description = parseText(item.description, '', 360);
    if (!title && !description) continue;
    if (!title) {
      throw new BadRequestException('Step title is required in "site.steps".');
    }
    steps.push({ title, description });
  }
  return steps;
}

function parseFaqList(
  raw: unknown,
  fallback: readonly SiteFaqItem[],
  maxItems: number,
): readonly SiteFaqItem[] {
  if (raw === undefined) return fallback;
  if (!Array.isArray(raw)) {
    throw new BadRequestException('Field "site.faq" must be an array.');
  }
  if (raw.length > maxItems) {
    throw new BadRequestException(
      `Field "site.faq" may contain at most ${maxItems} items.`,
    );
  }
  const list: SiteFaqItem[] = [];
  for (const item of raw) {
    if (!isPlainObject(item)) {
      throw new BadRequestException('Items in "site.faq" must be objects.');
    }
    const question = parseText(item.question, '', 200);
    const answer = parseText(item.answer, '', 700);
    if (!question && !answer) continue;
    if (!question || !answer) {
      throw new BadRequestException(
        'Both question and answer are required in "site.faq".',
      );
    }
    list.push({ question, answer });
  }
  return list;
}

function parseSampleItems(
  raw: unknown,
  fallback: readonly SiteSampleItem[],
  field: string,
): readonly SiteSampleItem[] {
  if (raw === undefined) return fallback;
  if (!Array.isArray(raw)) {
    throw new BadRequestException(`Field "${field}" must be an array.`);
  }
  if (raw.length > 6) {
    throw new BadRequestException(
      `Field "${field}" may contain at most 6 sample questions.`,
    );
  }
  const items: SiteSampleItem[] = [];
  for (const item of raw) {
    if (!isPlainObject(item)) {
      throw new BadRequestException(`Items in "${field}" must be objects.`);
    }
    const question = parseText(item.question, '', 260);
    const clarification = parseText(item.clarification, '', 360);
    if (!question && !clarification) continue;
    if (!question) {
      throw new BadRequestException(`Sample question text is required in "${field}".`);
    }
    items.push({ question, clarification });
  }
  return items;
}

function parseText(raw: unknown, fallback: string, maxLength: number): string {
  if (raw === undefined) return fallback;
  if (raw === null) return '';
  if (typeof raw !== 'string') {
    throw new BadRequestException('Expected string configuration field.');
  }
  const trimmed = raw.trim();
  if (trimmed.length > maxLength) {
    throw new BadRequestException(
      `Field length exceeds maximum of ${maxLength} characters.`,
    );
  }
  return trimmed;
}

function parseBool(raw: unknown, fallback: boolean, field: string): boolean {
  if (raw === undefined) return fallback;
  if (typeof raw !== 'boolean') {
    throw new BadRequestException(`Field "${field}" must be a boolean.`);
  }
  return raw;
}

function parsePhoneOrEmpty(raw: unknown, fallback: string): string {
  if (raw === undefined) return fallback;
  if (raw === null) return '';
  if (typeof raw !== 'string') {
    throw new BadRequestException('WhatsApp number must be a string.');
  }
  const normalized = raw.replace(/[\s()-]+/g, '').replace(/^\+/, '');
  if (normalized.length === 0) return '';
  if (!/^\d{7,15}$/.test(normalized)) {
    throw new BadRequestException(
      'WhatsApp number must contain 7-15 digits (with country code, e.g. 2010xxxxxxxx).',
    );
  }
  return normalized;
}

function parseHttpsUrlOrEmpty(
  raw: unknown,
  fallback: string,
  field: string,
): string {
  if (raw === undefined) return fallback;
  if (raw === null) return '';
  if (typeof raw !== 'string') {
    throw new BadRequestException(`Field "${field}" must be a string.`);
  }
  const trimmed = raw.trim();
  if (trimmed.length === 0) return '';
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'https:') {
      throw new Error('Must use https');
    }
    return parsed.toString();
  } catch {
    throw new BadRequestException(`Field "${field}" must be a valid HTTPS URL.`);
  }
}

function parseAnnouncementStyle(
  raw: unknown,
  fallback: AnnouncementStyle,
): AnnouncementStyle {
  if (raw === undefined) return fallback;
  if (raw === 'info' || raw === 'warning' || raw === 'success') {
    return raw;
  }
  throw new BadRequestException(
    'Field "announcement.style" must be "info", "warning", or "success".',
  );
}

export { SAMPLE_TOPIC_KEYS };
