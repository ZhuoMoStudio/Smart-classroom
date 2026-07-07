/// 积分变动历史记录 — v1.30
class ScoreChangeRecord {
  final String memberName;
  final String groupName;
  final String className;
  final double oldScore;
  final double newScore;
  final double delta;
  final DateTime timestamp;

  const ScoreChangeRecord({
    required this.memberName,
    required this.groupName,
    required this.className,
    required this.oldScore,
    required this.newScore,
    required this.delta,
    required this.timestamp,
  });

  bool get isPositive => delta > 0;
  bool get isNegative => delta < 0;
}

/// 积分历史管理器
class ScoreHistoryManager {
  final List<ScoreChangeRecord> _records = [];
  static const int _maxRecords = 200;

  ScoreHistoryManager();

  List<ScoreChangeRecord> get records => List.unmodifiable(_records);
  List<ScoreChangeRecord> get recentRecords => _records.take(50).toList();

  void addRecord(ScoreChangeRecord record) {
    _records.insert(0, record);
    if (_records.length > _maxRecords) {
      _records.removeLast();
    }
  }

  ScoreChangeRecord? undoLast() {
    if (_records.isEmpty) return null;
    return _records.removeAt(0);
  }

  void clear() => _records.clear();
}
