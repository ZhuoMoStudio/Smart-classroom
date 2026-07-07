class RankSystem {
  static const List<String> rankNames = [
    '倔强青铜',
    '秩序白银',
    '荣耀黄金',
    '尊贵铂金',
    '永恒钻石',
    '至尊星耀',
    '最强王者',
    '荣耀王者',
  ];
  static const List<String> subRanks = ['V', 'IV', 'III', 'II', 'I'];

  static (String, int) getRank(double score) {
    int level = (score / 10).floor();
    if (level < 0) level = 0;
    if (level >= 35) return (rankNames[7], 35);
    if (level >= 30) return (rankNames[6], level);
    int tier = level ~/ 5;
    int sub = level % 5;
    if (tier >= 7) tier = 6;
    if (sub >= 5) sub = 4;
    return ('${rankNames[tier]} ${subRanks[sub]}', level);
  }
}

class Member {
  final String uid;
  final String name;
  final double score;
  const Member({required this.uid, required this.name, this.score = 0.0});

  Member copyWith({String? name, double? score}) =>
      Member(uid: uid, name: name ?? this.name, score: score ?? this.score);
}

class Group {
  final String uid;
  final String name;
  final List<Member> members;
  const Group({required this.uid, required this.name, this.members = const []});

  double get totalScore => members.fold(0, (s, m) => s + m.score);
  int get memberCount => members.length;

  Group copyWith({String? name, List<Member>? members}) => Group(
    uid: uid,
    name: name ?? this.name,
    members: members ?? this.members,
  );
}

class Classroom {
  final String uid;
  final String name;
  final List<Group> groups;
  const Classroom({
    required this.uid,
    required this.name,
    this.groups = const [],
  });

  List<Member> get allMembers => groups.expand((g) => g.members).toList();

  Classroom copyWith({String? name, List<Group>? groups}) => Classroom(
    uid: uid,
    name: name ?? this.name,
    groups: groups ?? this.groups,
  );
}
