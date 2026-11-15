import 'domain/models/question.dart';

export 'data/in_memory_question_repository.dart';
export 'data/json_asset_question_repository.dart';
export 'data/question_history_storage.dart';
export 'data/session_storage.dart';
export 'domain/models/question.dart';
export 'domain/models/saved_session_state.dart';
export 'domain/models/session_progress.dart';
export 'domain/repositories/question_history_storage.dart';
export 'domain/repositories/question_repository.dart';
export 'domain/repositories/session_storage.dart';

/// Legacy sample questions mapping retained for backwards compatibility.
///
/// Use [InMemoryQuestionRepository] or [QuestionRepository] for new features.
const sampleQuestions = <Topic, Map<Depth, List<String>>>{
  Topic.communication: {
    Depth.introductory: [
      'إيه اللي بيساعدك تتكلم براحة عن يومك؟',
      'إيه الطريقة اللي بتحب حد يسمعك بيها؟',
      'لما تكون مشغول، إزاي تحب نحدد وقت مناسب للكلام؟',
    ],
    Depth.deeper: [
      'لو اختلفنا في الرأي، إيه اللي يساعدنا نسمع بعض؟',
      'إزاي تحب نوضح سوء الفهم لما يحصل؟',
      'إيه الطريقة المناسبة لطلب وقت للتفكير أثناء الحوار؟',
    ],
  },
  Topic.dailyLife: {
    Depth.introductory: [
      'إيه العادات اليومية اللي بتحب تحافظ عليها؟',
      'بتفضل ترتب يومك مسبقًا ولا تسيب مساحة للمرونة؟',
      'إيه الأنشطة البسيطة اللي بتستمتع بيها في وقت فراغك؟',
    ],
    Depth.deeper: [
      'إيه توقعاتك من تنظيم المسؤوليات اليومية بعد الزواج؟',
      'لو اختلفت أولوياتنا في جدول الأسبوع، إزاي نقدر ننظم وقتنا؟',
      'إيه الأمور اللي تحب نتفق عليها بخصوص الخصوصية في البيت؟',
    ],
  },
  Topic.familyRelations: {
    Depth.introductory: [
      'إيه التقاليد العائلية اللي بتحب تحافظ عليها في المناسبات؟',
      'إزاي تحب ننسق الزيارات الأسبوعية للأهل؟',
      'إيه الطريقة المناسبة لمشاركة الأخبار العائلية بهدوء؟',
    ],
    Depth.deeper: [
      'إزاي نقدر نحافظ على استقلالية وخصوصية بيتنا مع بر الأهل؟',
      'لو حصل اختلاف في وجهات النظر مع الأهل، إزاي نتعامل معاه كفريق؟',
      'إيه الحدود الصحية اللي تحب نتفق عليها بخصوص التدخلات الخارجية؟',
    ],
  },
  Topic.finances: {
    Depth.introductory: [
      'إيه أسلوبك المفضل في إدارة المصروف الشهري؟',
      'بتحب الادخار لهدف محدد ولا بتفضل المرونة؟',
      'إيه الأولويات المالية اللي بتشوفها مهمة في أول سنة زواج؟',
    ],
    Depth.deeper: [
      'إزاي تحب نخطط للميزانية المشتركة ومصروفات الطوارئ؟',
      'لو واجهتنا أزمة مالية غير متوقعة، إيه الخطوات اللي نتخذها بهدوء؟',
      'إيه رؤيتك للاستثمار والقرارات المالية الكبيرة على المدى الطويل؟',
    ],
  },
  Topic.coreValues: {
    Depth.introductory: [
      'إيه أهم مبدأ اتعلمته في حياتك وبتحرص تطبقه دائمًا؟',
      'إيه الصفات اللي بتشوفها أساسية لبناء الثقة بين أي اتنين؟',
      'إزاي بتحب نقضي المناسبات والأعياد الدينية والاجتماعية؟',
    ],
    Depth.deeper: [
      'إيه الرؤية أو الهدف الأكبر اللي تحب نحققه مع بعض في حياتنا؟',
      'لما نمر بظرف صعب، إيه المعاني الإيمانية أو القيمية اللي بتثبتك؟',
      'إزاي نقدر نربي أولادنا في المستقبل على الصدق والمسؤولية؟',
    ],
  },
};
