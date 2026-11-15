import 'dart:math';

import '../domain/models/question.dart';
import '../domain/repositories/question_repository.dart';

/// Pre-populated prototype questions for development and testing.
///
/// CAUTION: These questions are for prototyping only and have NOT been
/// approved by qualified religious or family counselors.
const List<Question> prototypeQuestions = [
  // Communication - Introductory
  Question(
    id: 'comm-intro-1',
    text: 'إيه اللي بيساعدك تتكلم براحة عن يومك؟',
    topic: Topic.communication,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'comm-intro-2',
    text: 'إيه الطريقة اللي بتحب حد يسمعك بيها؟',
    topic: Topic.communication,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'comm-intro-3',
    text: 'لما تكون مشغول، إزاي تحب نحدد وقت مناسب للكلام؟',
    topic: Topic.communication,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),

  // Communication - Deeper
  Question(
    id: 'comm-deep-1',
    text: 'لو اختلفنا في الرأي، إيه اللي يساعدنا نسمع بعض؟',
    topic: Topic.communication,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'comm-deep-2',
    text: 'إزاي تحب نوضح سوء الفهم لما يحصل؟',
    topic: Topic.communication,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'comm-deep-3',
    text: 'إيه الطريقة المناسبة لطلب وقت للتفكير أثناء الحوار؟',
    topic: Topic.communication,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),

  // Daily Life - Introductory
  Question(
    id: 'daily-intro-1',
    text: 'إيه العادات اليومية اللي بتحب تحافظ عليها؟',
    topic: Topic.dailyLife,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'daily-intro-2',
    text: 'بتفضل ترتب يومك مسبقًا ولا تسيب مساحة للمرونة؟',
    topic: Topic.dailyLife,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'daily-intro-3',
    text: 'إيه الأنشطة البسيطة اللي بتستمتع بيها في وقت فراغك؟',
    topic: Topic.dailyLife,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),

  // Daily Life - Deeper
  Question(
    id: 'daily-deep-1',
    text: 'إيه توقعاتك من تنظيم المسؤوليات اليومية بعد الزواج؟',
    topic: Topic.dailyLife,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'daily-deep-2',
    text: 'لو اختلفت أولوياتنا في جدول الأسبوع، إزاي نقدر ننظم وقتنا؟',
    topic: Topic.dailyLife,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'daily-deep-3',
    text: 'إيه الأمور اللي تحب نتفق عليها بخصوص الخصوصية في البيت؟',
    topic: Topic.dailyLife,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),

  // Family Relations - Introductory
  Question(
    id: 'fam-intro-1',
    text: 'إيه التقاليد العائلية اللي بتحب تحافظ عليها في المناسبات؟',
    topic: Topic.familyRelations,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fam-intro-2',
    text: 'إزاي تحب ننسق الزيارات الأسبوعية للأهل؟',
    topic: Topic.familyRelations,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fam-intro-3',
    text: 'إيه الطريقة المناسبة لمشاركة الأخبار العائلية بهدوء؟',
    topic: Topic.familyRelations,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),

  // Family Relations - Deeper
  Question(
    id: 'fam-deep-1',
    text: 'إزاي نقدر نحافظ على استقلالية وخصوصية بيتنا مع بر الأهل؟',
    topic: Topic.familyRelations,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fam-deep-2',
    text: 'لو حصل اختلاف في وجهات النظر مع الأهل، إزاي نتعامل معاه كفريق؟',
    topic: Topic.familyRelations,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fam-deep-3',
    text: 'إيه الحدود الصحية اللي تحب نتفق عليها بخصوص التدخلات الخارجية؟',
    topic: Topic.familyRelations,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),

  // Finances - Introductory
  Question(
    id: 'fin-intro-1',
    text: 'إيه أسلوبك المفضل في إدارة المصروف الشهري؟',
    topic: Topic.finances,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fin-intro-2',
    text: 'بتحب الادخار لهدف محدد ولا بتفضل المرونة؟',
    topic: Topic.finances,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fin-intro-3',
    text: 'إيه الأولويات المالية اللي بتشوفها مهمة في أول سنة زواج؟',
    topic: Topic.finances,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),

  // Finances - Deeper
  Question(
    id: 'fin-deep-1',
    text: 'إزاي تحب نخطط للميزانية المشتركة ومصروفات الطوارئ؟',
    topic: Topic.finances,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fin-deep-2',
    text: 'لو واجهتنا أزمة مالية غير متوقعة، إيه الخطوات اللي نتخذها بهدوء؟',
    topic: Topic.finances,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'fin-deep-3',
    text: 'إيه رؤيتك للاستثمار والقرارات المالية الكبيرة على المدى الطويل؟',
    topic: Topic.finances,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),

  // Values - Introductory
  Question(
    id: 'val-intro-1',
    text: 'إيه أهم مبدأ اتعلمته في حياتك وبتحرص تطبقه دائمًا؟',
    topic: Topic.coreValues,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'val-intro-2',
    text: 'إيه الصفات اللي بتشوفها أساسية لبناء الثقة بين أي اتنين؟',
    topic: Topic.coreValues,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'val-intro-3',
    text: 'إزاي بتحب نقضي المناسبات والأعياد الدينية والاجتماعية؟',
    topic: Topic.coreValues,
    depth: Depth.introductory,
    isDevelopmentOnly: true,
  ),

  // Values - Deeper
  Question(
    id: 'val-deep-1',
    text: 'إيه الرؤية أو الهدف الأكبر اللي تحب نحققه مع بعض في حياتنا؟',
    topic: Topic.coreValues,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'val-deep-2',
    text: 'لما نمر بظرف صعب، إيه المعاني الإيمانية أو القيمية اللي بتثبتك؟',
    topic: Topic.coreValues,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
  Question(
    id: 'val-deep-3',
    text: 'إزاي نقدر نربي أولادنا في المستقبل على الصدق والمسؤولية؟',
    topic: Topic.coreValues,
    depth: Depth.deeper,
    isDevelopmentOnly: true,
  ),
];

/// In-memory repository implementing [QuestionRepository].
class InMemoryQuestionRepository implements QuestionRepository {
  InMemoryQuestionRepository({List<Question>? questions, Random? random})
    : _questions = List.unmodifiable(questions ?? prototypeQuestions),
      _random = random ?? Random();

  final List<Question> _questions;
  final Random _random;

  /// Synchronous retrieval for lightweight UI rendering without async delays.
  List<Question> getQuestionsSync({
    Topic? topic,
    required Depth depth,
    ConversationMode? mode,
  }) {
    return _questions.where((q) {
      if (topic != null && q.topic != topic) return false;
      if (q.depth != depth) return false;
      if (mode != null && !q.suitableModes.contains(mode)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Question>> getQuestions({
    Topic? topic,
    required Depth depth,
    ConversationMode? mode,
  }) async {
    return getQuestionsSync(topic: topic, depth: depth, mode: mode);
  }

  @override
  Future<QuestionQueryResult> queryQuestions(QuestionFilter filter) async {
    final matched = getQuestionsSync(
      topic: filter.topic,
      depth: filter.depth,
      mode: filter.mode,
    );

    final total = matched.length;
    if (total == 0) {
      return const QuestionQueryResult(questions: [], totalAvailable: 0);
    }

    // Partition candidates into unseen vs seen in recent sessions
    final unseen =
        matched.where((q) => !filter.excludeQuestionIds.contains(q.id)).toList()
          ..shuffle(_random);
    final seen =
        matched.where((q) => filter.excludeQuestionIds.contains(q.id)).toList()
          ..shuffle(_random);

    final limit = filter.limit ?? total;
    final targetCount = limit.clamp(0, total);

    // Prioritize unseen questions; supplement from seen if needed
    final selected = <Question>[...unseen];
    if (selected.length < targetCount) {
      selected.addAll(seen.take(targetCount - selected.length));
    }

    final finalSelection = selected.take(targetCount).toList();

    return QuestionQueryResult(
      questions: finalSelection,
      totalAvailable: total,
    );
  }
}
