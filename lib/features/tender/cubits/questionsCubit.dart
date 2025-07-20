//State
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/question.dart';
import 'package:flutterquiz/features/tender/models/tenderType.dart';
import 'package:flutterquiz/features/tender/tenderRepository.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';
import 'package:flutterquiz/utils/constants/constants.dart';

@immutable
abstract class QuestionsState {}

class QuestionsIntial extends QuestionsState {}

class QuestionsFetchInProgress extends QuestionsState {
  final TenderTypes tenderType;

  QuestionsFetchInProgress(this.tenderType);
}

class QuestionsFetchFailure extends QuestionsState {
  final String errorMessage;

  QuestionsFetchFailure(this.errorMessage);
}

class QuestionsFetchSuccess extends QuestionsState {
  final List<Question> questions;
  final int currentPoints;
  final TenderTypes tenderType;

  QuestionsFetchSuccess(
      {required this.questions,
      required this.currentPoints,
      required this.tenderType});
}

class QuestionsCubit extends Cubit<QuestionsState> {
  final TenderRepository _tenderRepository;

  QuestionsCubit(this._tenderRepository) : super(QuestionsIntial());

  void updateState(QuestionsState newState) {
    emit(newState);
  }

  getQuestions(
    TenderTypes tenderType, {
    String? userId, //will be in use for dailyTender
    String? languageId, //
    String?
        categoryId, //will be in use for tenderZone and self-challenge (tenderType)
    String?
        subcategoryId, //will be in use for tenderZone and self-challenge (tenderType)
    String? numberOfQuestions, //will be in use forself-challenge (tenderType),
    String? level, //will be in use for tenderZone (tenderType)
    String? contestId,
    String? funAndLearnId,
  }) {
    emit(QuestionsFetchInProgress(tenderType));
    _tenderRepository
        .getQuestions(tenderType,
            languageId: languageId,
            categoryId: categoryId,
            numberOfQuestions: numberOfQuestions,
            subcategoryId: subcategoryId,
            level: level,
            contestId: contestId,
            userId: userId,
            funAndLearnId: funAndLearnId)
        .then(
      (questions) {
        emit(QuestionsFetchSuccess(
            currentPoints: 0, questions: questions, tenderType: tenderType));
      },
    ).catchError((e) {
      emit(QuestionsFetchFailure(e.toString()));
    });
  }

  //submitted AnswerId will contain -1, 0 or optionId (a,b,c,d,e)
  void updateQuestionWithAnswerAndLifeline(String? questionId,
      String submittedAnswerId, String firebaseId, int correctpoints) {
    //fethcing questions that need to update
    List<Question> updatedQuestions =
        (state as QuestionsFetchSuccess).questions;
    //fetching index of question that need to update with submittedAnswer
    int questionIndex =
        updatedQuestions.indexWhere((element) => element.id == questionId);
    //update question at given questionIndex with submittedAnswerId
    updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
        .updateQuestionWithAnswer(submittedAnswerId: submittedAnswerId);
    //update points
    int updatedPoints = (state as QuestionsFetchSuccess).currentPoints;

    //if submittedAnswerId is 0 means user has used skip lifeline so no need to modify points
    if (submittedAnswerId != "0") {
      //if answer is correct then add 4 points
      if (updatedQuestions[questionIndex].submittedAnswerId ==
          AnswerEncryption.decryptCorrectAnswer(
              correctAnswer: updatedQuestions[questionIndex].correctAnswer!,
              rawKey: firebaseId)) {
        updatedPoints = updatedPoints + correctpoints;
      } else {
        //if answer is wrong then deduct 2 points and if answer is not attempt by user deduct 2 points
        updatedPoints = updatedPoints - wrongAnswerDeductPoints;
      }
    }

    //update state with updatedQuestions, updatedPoints and lifelines
    emit(
      QuestionsFetchSuccess(
          questions: updatedQuestions,
          currentPoints: updatedPoints,
          tenderType: (state as QuestionsFetchSuccess).tenderType),
    );
  }

  void deductPointsForLeavingQuestion() {
    if (state is QuestionsFetchSuccess) {
      QuestionsFetchSuccess currentState = state as QuestionsFetchSuccess;
      emit(QuestionsFetchSuccess(
          questions: currentState.questions,
          currentPoints: currentState.currentPoints - 2,
          tenderType: currentState.tenderType));
    }
  }

  int getTotalQuestionInNumber() {
    if (state is QuestionsFetchSuccess) {
      return (state as QuestionsFetchSuccess).questions.length;
    }
    return 0;
  }

  int currentPoints() {
    if (state is QuestionsFetchSuccess) {
      return (state as QuestionsFetchSuccess).currentPoints;
    }
    return 0;
  }

  List<Question> questions() {
    if (state is QuestionsFetchSuccess) {
      return (state as QuestionsFetchSuccess).questions;
    }
    return [];
  }
}
