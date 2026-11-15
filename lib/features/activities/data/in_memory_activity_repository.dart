import '../../sessions/session_data.dart';
import '../domain/models/activity.dart';
import '../domain/repositories/activity_repository.dart';

/// In-memory repository containing development prototype activities.
///
/// NOTE: In accordance with project policy, all prototype activities are
/// explicitly marked with [isDevelopmentOnly: true] and have not undergone
/// certified religious or family counseling review.
class InMemoryActivityRepository implements ActivityRepository {
  InMemoryActivityRepository([List<Activity>? activities])
    : _activities = activities ?? prototypes;

  final List<Activity> _activities;

  static const List<Activity> prototypes = [
    Activity(
      id: 'act_scen_comm_01',
      type: ActivityType.scenario,
      topic: Topic.communication,
      title: 'موقف للنقاش: زيارة عائلية مفاجئة',
      situation: 'اتصل أحد أفراد العائلة لإعلامكم برغبته في الزيارة اليوم بعد ساعتين، بينما كان اليوم مخصصًا للراحة أو لارتباط خاص بينكما.',
      prompts: [
        'كيف يفضل كل منا التعامل مع التغييرات المفاجئة في المواعيد؟',
        'ما الطريقة المثالية للتنسيق والاتفاق بيننا قبل تأكيد أي موعد خارجي؟',
        'ما هو الحل الوسط الذي يجمع بين الترحيب بالعائلة واحترام وقتنا الخاص؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_scen_daily_01',
      type: ActivityType.scenario,
      topic: Topic.dailyLife,
      title: 'موقف للنقاش: التزام مالي غير متوقع',
      situation: 'ظهر ظرف مالي طارئ في منتصف الشهر يتطلب إعادة ترتيب بعض المصروفات الشخصية أو المنزلية لتغطيته.',
      prompts: [
        'ما هي أول خطوة تراها مناسبة عند مواجهة ظرف مالي مفاجئ؟',
        'كيف نتحاور في الأمور المالية بشفافية وهدوء دون توتر؟',
        'ما هي الجوانب التي يمكننا إظهار مرونة تجاهها في الميزانية عند الحاجة؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_prio_comm_01',
      type: ActivityType.priorityOrdering,
      topic: Topic.communication,
      title: 'أولويات مشتركة: أسلوب إدارة النقاش الحساس',
      situation: 'لكل منا طريقة مختلفة للشعور بالأمان والراحة أثناء النقاش. تأملا العناصر التالية وناقشا ترتيبها وأهميتها بالنسبة لكما:',
      options: [
        'أخذ وقت هادئ للتفكير قبل الرد أو مواصلة الحديث',
        'التحدث المباشر والسريع لتبديد أي سوء فهم فورًا',
        'التأكيد على الاحترام والمشاعر الإيجابية قبل مناقشة التفاصيل',
        'التركيز على خطوات وحلول عملية متفق عليها للمستقبل',
      ],
      prompts: [
        'ما هو العنصر الأكثر أهمية بالنسبة لك ليشعر عقلك وقلبك بالارتياح؟',
        'كيف يمكننا التوفيق بين أسلوبينا عندما يختلف ما يحتاجه كل منا؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_scen_fam_01',
      type: ActivityType.scenario,
      topic: Topic.familyRelations,
      title: 'موقف للنقاش: مناسبة عائلية بالتزامن مع التزام مسبق',
      situation: 'تمت دعوتكما لمناسبة عائلية مهمة لأحد الأطراف في نفس التوقيت الذي تم فيه الترتيب المسبق لالتزام شخصي أو راحة ضرورية للطرف الآخر.',
      prompts: [
        'كيف نزن بين تلبية الواجبات العائلية واحترام خططنا الخاصة؟',
        'ما هي الحلول المرنة التي تظهر تقدير العائلة دون إرهاق أي طرف؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_prio_fin_01',
      type: ActivityType.priorityOrdering,
      topic: Topic.finances,
      title: 'أولويات مشتركة: إدارة الدخل والادخار',
      situation: 'تأملا الجوانب المالية التالية في بداية الحياة المشتركة وناقشا ترتيب أولوياتها بالنسبة لكما:',
      options: [
        'بناء صندوق مالي مخصص للطوارئ والظروف المفاجئة',
        'الاستثمار في راحة البيت والاحتياجات الأساسية بجودة جيدة',
        'تخصيص جزء للترويح والأنشطة المشتركة والسفر',
        'الادخار المنتظم طويل المدى لتحقيق أهداف مستقبلية كبرى',
      ],
      prompts: [
        'ما هو الجانب الذي يمنحك شعورًا أكبر بالأمان المالي؟',
        'كيف نصل إلى ميزانية متوازنة ترضي الطرفين وتراعي الواقع؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_scen_val_01',
      type: ActivityType.scenario,
      topic: Topic.coreValues,
      title: 'موقف للنقاش: قرار مصيري يتطلب التضحية',
      situation: 'عُرضت فرصة عمل أو دراسة متميزة خارج المدينة لأحد الطرفين، وتتطلب إعادة ترتيب نمط الحياة اليومي بالكامل لفترة محددة.',
      prompts: [
        'ما هي القيم والمبادئ الأساسية التي نستند إليها في تقييم مثل هذه الفرص؟',
        'كيف نتأكد أن مصلحة بيتنا المشترك هي البوصلة الأولى في أي قرار؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_prio_daily_01',
      type: ActivityType.priorityOrdering,
      topic: Topic.dailyLife,
      title: 'أولويات مشتركة: إدارة الوقت في عطلة نهاية الأسبوع',
      situation: 'تأملا الخيارات التالية لقضاء العطلة الأسبوعية وناقشا ترتيبها وأهميتها بالنسبة لكما:',
      options: [
        'تخصيص وقت كامل للراحة والاسترخاء الهادئ داخل البيت',
        'الزيارات العائلية والتواصل مع الأهل والأقارب',
        'الخروج في نزهة أو نشاط ترفيهي مشترك خارج البيت',
        'إنجاز الترتيبات المنزلية وشراء احتياجات الأسبوع',
      ],
      prompts: [
        'كيف نصل إلى جدول أسبوعي يجمع بين الراحة والتواصل دون ضغط؟',
        'ما هو الحد الأدنى من وقت الهدوء الذي يحتاجه كل منا لشحن طاقته؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_scen_comm_02',
      type: ActivityType.scenario,
      topic: Topic.communication,
      title: 'موقف للنقاش: عودة مرهقة من يوم شاق',
      situation: 'عاد أحدكما من العمل أو الدراسة مرهقًا ومحبطًا من موقف صعب، بينما كان الطرف الآخر ينتظر هذا اللقاء للحديث في موضوع مهم ومشوق.',
      prompts: [
        'ما الإشارة أو التصرف الذي يساعدنا على فهم مزاج الطرف الآخر فور لقائه؟',
        'كيف نوازن بين الحاجة إلى الفضفضة، وبين تأجيل الموضوعات المهمة لوقت أهدأ؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_prio_fam_01',
      type: ActivityType.priorityOrdering,
      topic: Topic.familyRelations,
      title: 'أولويات مشتركة: بناء علاقة متوازنة ودافئة مع العائلتين',
      situation: 'تأملا المعايير التالية لبناء علاقة راقية ومستقرة مع الأهل ورتباها بحسب أولويتكما:',
      options: [
        'الحرص الدائم على الاحترام المتبادل والكلمة الطيبة في كل المواقف',
        'حفظ خصوصية القرارات الزوجية داخل البيت وعدم إشراك أطراف خارجية',
        'التواصل الدوري وصلة الرحم والاهتمام بمناسبات العائلتين',
        'المرونة والتغافل عن أي عتاب أو حساسية غير مقصودة',
      ],
      prompts: [
        'ما هو المبدأ الأكثر أهمية لحماية استقرار بيتنا واستمرار محبة الأهل؟',
        'كيف نتصرف كفريق واحد عندما يواجهنا موقف عائلي يتطلب الحكمة؟',
      ],
      isDevelopmentOnly: true,
    ),
    Activity(
      id: 'act_prio_val_01',
      type: ActivityType.priorityOrdering,
      topic: Topic.coreValues,
      title: 'أولويات مشتركة: بوصلة اتخاذ القرارات الكبرى',
      situation: 'عند اتخاذ قرار مصيري (مثل اختيار السكن، تغيير العمل، أو تربية الأبناء)، ما الترتيب الذي تراه مناسبًا لمعايير الاختيار التالية:',
      options: [
        'التوافق مع المبادئ الأخلاقية والقيم الدينية التي نؤمن بها',
        'تحقيق الراحة النفسية والاستقرار الأسري المشترك',
        'الجدوى الاقتصادية والأمان المالي طويل الأمد',
        'ملاءمة القرار للظروف العائلية والاجتماعية المحيطة',
      ],
      prompts: [
        'إذا تعارض معياران في قرار مهم، كيف نتفق على المعيار الحاسم بهدوء؟',
        'ما الذي يعنيه لك أن نكون شركاء حقيقيين في صناعة القرار؟',
      ],
      isDevelopmentOnly: true,
    ),
  ];

  @override
  Future<List<Activity>> getActivities({
    Topic? topic,
    ActivityType? type,
    int? limit,
  }) async {
    var results = _activities.where((activity) {
      if (topic != null && activity.topic != topic) return false;
      if (type != null && activity.type != type) return false;
      return true;
    }).toList();

    if (limit != null && limit > 0 && results.length > limit) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (_) {
      return null;
    }
  }
}
