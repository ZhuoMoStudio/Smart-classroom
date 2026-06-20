import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_bank.dart';

class QuestionState {
  final List<QuestionBank> banks;
  final String? selectedBankUid;
  final bool mixMode, isDirty;
  const QuestionState({this.banks = const [], this.selectedBankUid, this.mixMode = false, this.isDirty = false});

  QuestionBank? get selectedBank => selectedBankUid == null ? null
      : banks.cast<QuestionBank?>().firstWhere((b) => b!.uid == selectedBankUid, orElse: () => null);
  List<QuestionBank> get mixedBanks => mixMode ? banks : (selectedBank != null ? [selectedBank!] : []);
  List<Question> get allQuestions => mixedBanks.expand((b) => b.questions).toList();

  QuestionState copyWith({List<QuestionBank>? banks, String? selectedBankUid, bool? mixMode, bool? isDirty}) =>
      QuestionState(banks: banks ?? this.banks, selectedBankUid: selectedBankUid ?? this.selectedBankUid,
          mixMode: mixMode ?? this.mixMode, isDirty: isDirty ?? this.isDirty);
}

class QuestionNotifier extends StateNotifier<QuestionState> {
  QuestionNotifier() : super(const QuestionState());

  void loadFromData(List<QuestionBank> banks) => state = state.copyWith(banks: banks, isDirty: false);
  void addBank(QuestionBank bank) => state = state.copyWith(
      banks: [...state.banks, bank], selectedBankUid: bank.uid, isDirty: true);
  void selectBank(String? uid) => state = state.copyWith(selectedBankUid: uid);
  void toggleMixMode() => state = state.copyWith(mixMode: !state.mixMode);

  void markUsed(String bid, String qid) {
    state = state.copyWith(banks: state.banks.map((b) => b.uid == bid
        ? b.copyWith(questions: b.questions.map((q) => q.uid == qid ? q.copyWith(used: true) : q).toList()) : b).toList(), isDirty: true);
  }

  void resetAllUsed(String bid) {
    state = state.copyWith(banks: state.banks.map((b) => b.uid == bid
        ? b.copyWith(questions: b.questions.map((q) => q.copyWith(used: false)).toList()) : b).toList(), isDirty: true);
  }

  Question? getRandomUnusedNonRisk() {
    final pool = state.allQuestions.where((q) => !q.used && !q.isRisk).toList();
    if (pool.isEmpty) return null; pool.shuffle(); return pool.first;
  }

  void clearDirty() => state = state.copyWith(isDirty: false);
}

final questionProvider = StateNotifierProvider<QuestionNotifier, QuestionState>((ref) => QuestionNotifier());
