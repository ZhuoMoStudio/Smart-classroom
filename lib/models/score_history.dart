/// 积分变动历史记录
///
/// 除了名字之外还记录 uid。
/// 旧实现只用「班级名 + 小组名 + 姓名」来定位要撤销的成员，
/// 于是同名同学会互相撤销，改名之后则彻底找不到目标，
/// 但记录已经被 `undoLast()` 从队列里吃掉 —— 结果是「撤销失败，且这条历史也没了」。
class ScoreChangeRecord {
  final String memberName;
  final String groupName;
  final String className;
  final double oldScore;
  final double newScore;
  final double delta;
  final DateTime timestamp;

  /// 精确定位用。为 null 时（理论上不会出现）回退到按名字匹配。
  final String? memberUid;
  final String? groupUid;
  final String? classUid;

  const ScoreChangeRecord({
    required this.memberName,
    required this.groupName,
    required this.className,
    required this.oldScore,
    required this.newScore,
    required this.delta,
    required this.timestamp,
    this.memberUid,
    this.groupUid,
    this.classUid,
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
  int get length => _records.length;
  bool get isEmpty => _records.isEmpty;

  void addRecord(ScoreChangeRecord record) {
    _records.insert(0, record);
    if (_records.length > _maxRecords) {
      _records.removeLast();
    }
  }

  /// 只看最近一条，不动队列。
  ///
  /// 撤销必须「先确认能定位到人，再移除记录」，
  /// 否则就会出现「记录没了、分也没改回来」。
  ScoreChangeRecord? peekLast() => _records.isEmpty ? null : _records.first;

  ScoreChangeRecord? undoLast() {
    if (_records.isEmpty) return null;
    return _records.removeAt(0);
  }

  void clear() => _records.clear();
}
