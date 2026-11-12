enum ConversationMode { together, phone }

enum Topic { communication, dailyLife }

enum Depth { introductory, deeper }

extension ModeLabel on ConversationMode {
  String get label => switch (this) {
    ConversationMode.together => 'مع بعض',
    ConversationMode.phone => 'في مكالمة',
  };
}

extension TopicLabel on Topic {
  String get label => switch (this) {
    Topic.communication => 'التواصل',
    Topic.dailyLife => 'الحياة اليومية',
  };
}

extension DepthLabel on Depth {
  String get label => switch (this) {
    Depth.introductory => 'تمهيدي',
    Depth.deeper => 'أعمق',
  };
}

// Examples for testing only. They must be reviewed before release.
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
};

class SessionProgress {
  SessionProgress(List<String> questions)
    : questions = List.unmodifiable(questions) {
    if (questions.isEmpty) throw ArgumentError('A session needs questions');
  }
  final List<String> questions;
  final Set<int> _skipped = {};
  int index = 0;
  bool complete = false;
  int get skippedCount => _skipped.length;
  int get discussedCount => questions.length - skippedCount;
  void advance({required bool skipped}) {
    if (complete) return;
    if (skipped) {
      _skipped.add(index);
    } else {
      _skipped.remove(index);
    }
    if (index == questions.length - 1) {
      complete = true;
    } else {
      index++;
    }
  }

  void previous() {
    if (!complete && index > 0) index--;
  }
}
