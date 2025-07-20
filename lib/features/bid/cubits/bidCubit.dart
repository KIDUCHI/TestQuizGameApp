import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bid/bidRepository.dart';
import 'package:flutterquiz/features/bid/models/bid.dart';
import 'package:flutterquiz/features/bid/models/bidResult.dart';
import 'package:flutterquiz/features/quiz/models/question.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';

abstract class BidState {}

class BidInitial extends BidState {}

class BidFetchInProgress extends BidState {}

class BidFetchFailure extends BidState {
  final String errorMessage;

  BidFetchFailure(this.errorMessage);
}

class BidFetchSuccess extends BidState {
  final List<Question> questions;
  final Bid bid;

  BidFetchSuccess({required this.bid, required this.questions});
}

class BidCubit extends Cubit<BidState> {
  final BidRepository _bidRepository;

  BidCubit(this._bidRepository) : super(BidInitial());

  void updateState(BidState newState) {
    emit(newState);
  }

  void startBid({required Bid bid, required String userId}) async {
    emit(BidFetchInProgress());
    //
    try {
      //fetch question

      List<Question> questions =
          await _bidRepository.getBidMouduleQuestions(bidModuleId: bid.id);

      //

      //check if user can give bid or not
      //if user is in bid then it will throw 103 error means fill all data
      await _bidRepository.updateBidStatusToInBid(
          bidModuleId: bid.id, userId: userId);
      await _bidRepository.bidLocalDataSource.addBidModuleId(bid.id);
      emit(
          BidFetchSuccess(bid: bid, questions: arrangeQuestions(questions)));
    } catch (e) {
      emit(BidFetchFailure(e.toString()));
    }
  }

  List<Question> arrangeQuestions(List<Question> questions) {
    List<Question> arrangedQuestions = [];

    List<String> marks =
        questions.map((question) => question.marks!).toSet().toList();
    //sort marks
    marks.sort((first, second) => first.compareTo(second));

    //arrange questions from low to high mrak
    for (var questionMark in marks) {
      arrangedQuestions.addAll(
          questions.where((element) => element.marks == questionMark).toList());
    }

    return arrangedQuestions;
  }

  int getQuetionIndexById(String questionId) {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess)
          .questions
          .indexWhere((element) => element.id == questionId);
    }
    return 0;
  }

  //submitted AnswerId will contain -1, 0 or optionId (a,b,c,d,e)
  void updateQuestionWithAnswer(String questionId, String submittedAnswerId) {
    if (state is BidFetchSuccess) {
      //fethcing questions that need to update
      List<Question> updatedQuestions = (state as BidFetchSuccess).questions;
      //fetching index of question that need to update with submittedAnswer
      int questionIndex =
          updatedQuestions.indexWhere((element) => element.id == questionId);
      //update question at given questionIndex with submittedAnswerId
      updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
          .updateQuestionWithAnswer(submittedAnswerId: submittedAnswerId);

      emit(BidFetchSuccess(
          bid: (state as BidFetchSuccess).bid, questions: updatedQuestions));
    }
  }

  List<Question> getQuestions() {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess).questions;
    }
    return [];
  }

  Bid getBid() {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess).bid;
    }
    return Bid.fromJson({});
  }

  bool canUserSubmitAnswerAgainInBid() {
    return getBid().answerAgain == "1";
  }

  void submitResult({
    required String userId,
    required String totalDuration,
    required bool rulesViolated,
    required List<String> capturedQuestionIds,
  }) {
    if (state is BidFetchSuccess) {
      List<Statistics> markStatistics = [];

      getUniqueQuestionMark().forEach((mark) {
        List<Question> questions = getQuestionsByMark(mark);
        int correctAnswers = questions
            .where((element) =>
                element.submittedAnswerId ==
                AnswerEncryption.decryptCorrectAnswer(
                    rawKey: userId, correctAnswer: element.correctAnswer!))
            .toList()
            .length;
        Statistics statistics = Statistics(
            mark: mark,
            correctAnswer: correctAnswers.toString(),
            incorrect: (questions.length - correctAnswers).toString());
        markStatistics.add(statistics);
      });

      //
      for (var element in markStatistics) {
        print(element.toJson());
      }

      _bidRepository.submitBidResult(
          capturedQuestionIds: capturedQuestionIds,
          rulesViolated: rulesViolated,
          obtainedMarks: obtainedMarks(userId).toString(),
          bidModuleId: (state as BidFetchSuccess).bid.id,
          userId: userId,
          totalDuration: totalDuration,
          statistics: markStatistics.map((e) => e.toJson()).toList());

      _bidRepository.bidLocalDataSource
          .removeBidModuleId((state as BidFetchSuccess).bid.id);
    }
  }

  int correctAnswers(String userId) {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess)
          .questions
          .where((element) =>
              element.submittedAnswerId ==
              AnswerEncryption.decryptCorrectAnswer(
                  rawKey: userId, correctAnswer: element.correctAnswer!))
          .toList()
          .length;
    }
    return 0;
  }

  int incorrectAnswers(String userId) {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess).questions.length -
          correctAnswers(userId);
    }
    return 0;
  }

  int obtainedMarks(String userId) {
    if (state is BidFetchSuccess) {
      final correctAnswers = (state as BidFetchSuccess)
          .questions
          .where((element) =>
              element.submittedAnswerId ==
              AnswerEncryption.decryptCorrectAnswer(
                  rawKey: userId, correctAnswer: element.correctAnswer!))
          .toList();
      int obtainedMark = 0;

      for (var element in correctAnswers) {
        obtainedMark = obtainedMark + int.parse(element.marks ?? "0");
      }

      return obtainedMark;
    }
    return 0;
  }

  List<Question> getQuestionsByMark(String questionMark) {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess)
          .questions
          .where((question) => question.marks == questionMark)
          .toList();
    }
    return [];
  }

  List<String> getUniqueQuestionMark() {
    if (state is BidFetchSuccess) {
      return (state as BidFetchSuccess)
          .questions
          .map((question) => question.marks!)
          .toSet()
          .toList();
    }
    return [];
  }

  void completePendingBids({required String userId}) {
    _bidRepository.completePendingBids(userId: userId);
  }
}
