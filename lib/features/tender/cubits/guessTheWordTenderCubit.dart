import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/guessTheWordQuestion.dart';

import 'package:flutterquiz/features/tender/tenderRepository.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

abstract class GuessTheWordTenderState {}

class GuessTheWordTenderIntial extends GuessTheWordTenderState {}

class GuessTheWordTenderFetchInProgress extends GuessTheWordTenderState {}

class GuessTheWordTenderFetchFailure extends GuessTheWordTenderState {
  final String errorMessage;

  GuessTheWordTenderFetchFailure(this.errorMessage);
}

class GuessTheWordTenderFetchSuccess extends GuessTheWordTenderState {
  final List<GuessTheWordQuestion> questions;
  final int currentPoints;

  GuessTheWordTenderFetchSuccess(
      {required this.questions, required this.currentPoints});
}

class GuessTheWordTenderCubit extends Cubit<GuessTheWordTenderState> {
  final TenderRepository _tenderRepository;

  GuessTheWordTenderCubit(this._tenderRepository) : super(GuessTheWordTenderIntial());

  void getQuestion({
    required String questionLanguageId,
    required String type, //category or subcategory
    required String typeId, //id of the category or subcategory
  }) {
    emit(GuessTheWordTenderFetchInProgress());
    _tenderRepository
        .getGuessTheWordQuestions(
      languageId: questionLanguageId,
      type: type,
      typeId: typeId,
    )
        .then(
      (questions) {
        emit(GuessTheWordTenderFetchSuccess(
            questions: questions, currentPoints: 0));
      },
    ).catchError((e) {
      emit(GuessTheWordTenderFetchFailure(e.toString()));
    });
  }

  void updateAnswer(String answer, int answerIndex, String questionId) {
    if (state is GuessTheWordTenderFetchSuccess) {
      var questions = (state as GuessTheWordTenderFetchSuccess).questions;
      var questionIndex =
          questions.indexWhere((element) => element.id == questionId);
      var question = questions[questionIndex];
      var updatedAnswer = question.submittedAnswer;
      updatedAnswer[answerIndex] = answer;
      questions[questionIndex] =
          question.copyWith(updatedAnswer: updatedAnswer);

      emit(GuessTheWordTenderFetchSuccess(
          questions: questions,
          currentPoints:
              (state as GuessTheWordTenderFetchSuccess).currentPoints));
    }
  }

  List<GuessTheWordQuestion> getQuestions() {
    if (state is GuessTheWordTenderFetchSuccess) {
      return (state as GuessTheWordTenderFetchSuccess).questions;
    }
    return [];
  }

  int getCurrentPoints() {
    if (state is GuessTheWordTenderFetchSuccess) {
      return (state as GuessTheWordTenderFetchSuccess).currentPoints;
    }
    return 0;
  }

  void submitAnswer(String questionId, List<String> answer) {
    //update hasAnswer and current points

    if (state is GuessTheWordTenderFetchSuccess) {
      var currentState = (state as GuessTheWordTenderFetchSuccess);
      var questions = currentState.questions;
      var questionIndex =
          questions.indexWhere((element) => element.id == questionId);
      var question = questions[questionIndex];
      var updatedPoints = currentState.currentPoints;

      questions[questionIndex] =
          question.copyWith(hasAnswerGiven: true, updatedAnswer: answer);

      //check correctness of answer and update current points
      if (UiUtils.buildGuessTheWordQuestionAnswer(answer) == question.answer) {
        updatedPoints = updatedPoints + guessTheWordCorrectAnswerPoints;
      } else {
        updatedPoints = updatedPoints - guessTheWordWrongAnswerDeductPoints;
      }

      emit(GuessTheWordTenderFetchSuccess(
          questions: questions, currentPoints: updatedPoints));
    }
  }

  void updateState(GuessTheWordTenderState updatedState) {
    emit(updatedState);
  }
}
