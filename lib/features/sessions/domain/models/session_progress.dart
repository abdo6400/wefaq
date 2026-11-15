/// Domain state representing an in-memory session.
///
/// Progress is in-memory only per the current specification:
/// exiting or terminating the app discards progress without saving answer data.
class SessionProgress<T> {
  SessionProgress(
    List<T> questions, {
    int initialIndex = 0,
    Set<int> initialSkipped = const {},
  }) : questions = List.unmodifiable(questions),
       index = questions.isEmpty
           ? 0
           : initialIndex.clamp(0, questions.length - 1) {
    if (questions.isEmpty) {
      throw ArgumentError('A session needs questions');
    }
    _skipped.addAll(initialSkipped);
  }

  final List<T> questions;
  final Set<int> _skipped = {};
  int index;
  bool complete = false;

  Set<int> get skippedIndices => Set.unmodifiable(_skipped);
  int get skippedCount => _skipped.length;
  int get discussedCount => questions.length - skippedCount;
  bool get hasPrevious => !complete && index > 0;
  bool get isLastQuestion => index == questions.length - 1;

  void advance({required bool skipped}) {
    if (complete) return;
    if (skipped) {
      _skipped.add(index);
    } else {
      _skipped.remove(index);
    }
    if (isLastQuestion) {
      complete = true;
    } else {
      index++;
    }
  }

  void previous() {
    if (!complete && index > 0) {
      index--;
    }
  }
}
