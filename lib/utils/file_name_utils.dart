String generateFileName() {
  final n = DateTime.now();
  return '灵动课堂数据_${n.year}-${_p(n.month)}-${_p(n.day)}_${_p(n.hour)}-${_p(n.minute)}-${_p(n.second)}.json';
}

String _p(int n) => n.toString().padLeft(2, '0');
