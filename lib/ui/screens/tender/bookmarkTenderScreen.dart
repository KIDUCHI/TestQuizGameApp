import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/app/app_localization.dart';
import 'package:flutterquiz/features/bookmark/bookmarkRepository.dart';
import 'package:flutterquiz/features/bookmark/cubits/audioQuestionBookmarkCubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/bookmarkCubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/guessTheWordBookmarkCubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/updateBookmarkCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:flutterquiz/features/tender/cubits/guessTheWordTenderCubit.dart';
import 'package:flutterquiz/features/tender/cubits/questionsCubit.dart';
import 'package:flutterquiz/features/tender/models/tender.dart';
import 'package:flutterquiz/features/tender/tender.dart';
import 'package:flutterquiz/features/systemConfig/cubits/systemConfigCubit.dart';
import 'package:flutterquiz/ui/screens/tender/widgets/audioQuestionContainer.dart';
import 'package:flutterquiz/ui/screens/tender/widgets/guessTheWordQuestionContainer.dart';
import 'package:flutterquiz/ui/widgets/customAppbar.dart';
import 'package:flutterquiz/ui/widgets/customRoundedButton.dart';
import 'package:flutterquiz/ui/widgets/errorContainer.dart';
import 'package:flutterquiz/ui/widgets/exitGameDialog.dart';
import 'package:flutterquiz/ui/widgets/questionsContainer.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class BookmarkTenderScreen extends StatefulWidget {
  final TenderTypes tenderType;

  const BookmarkTenderScreen({super.key, required this.tenderType});

  @override
  _BookmarkTenderScreenState createState() => _BookmarkTenderScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<QuestionsCubit>(
            create: (_) => QuestionsCubit(TenderRepository()),
          ),
          BlocProvider<GuessTheWordTenderCubit>(
            create: (_) => GuessTheWordTenderCubit(TenderRepository()),
          ),
          BlocProvider<UpdateBookmarkCubit>(
            create: (_) => UpdateBookmarkCubit(BookmarkRepository()),
          ),
        ],
        child: BookmarkTenderScreen(
          tenderType: routeSettings.arguments as TenderTypes,
        ),
      ),
    );
  }
}

class _BookmarkTenderScreenState extends State<BookmarkTenderScreen>
    with TickerProviderStateMixin {
  late AnimationController questionAnimationController;
  late AnimationController questionContentAnimationController;
  late AnimationController timerAnimationController = AnimationController(
      vsync: this,
      duration:
          Duration(seconds: context.read<SystemConfigCubit>().getTenderTime()))
    ..addStatusListener(currentUserTimerAnimationStatusListener);
  late Animation<double> questionSlideAnimation;
  late Animation<double> questionScaleUpAnimation;
  late Animation<double> questionScaleDownAnimation;
  late Animation<double> questionContentAnimation;
  late AnimationController animationController;
  late AnimationController topContainerAnimationController;
  int currentQuestionIndex = 0;

  bool completedTender = false;

  //to track if setting dialog is open
  bool isSettingDialogOpen = false;

  bool isExitDialogOpen = false;

  late List<GlobalKey<GuessTheWordQuestionContainerState>>
      guessTheWordQuestionContainerKeys = [];

  late List<GlobalKey<AudioQuestionContainerState>> audioQuestionContainerKeys =
      [];

  late AnimationController showOptionAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  void _getQuestions() {
    Future.delayed(Duration.zero, () {
      //emitting success as we do not need to fetch questios from cloud and here only questions is important
      //other parameters can be ignored
      //other parameters need to pass so cubit functionlity does not break

      if (widget.tenderType == TenderTypes.audioQuestions) {
        context.read<QuestionsCubit>().updateState(QuestionsFetchSuccess(
            questions: List.from(
                context.read<AudioQuestionBookmarkCubit>().questions()),
            currentPoints: 0,
            tenderType: TenderTypes.bookmarkTender));

        context
            .read<AudioQuestionBookmarkCubit>()
            .questions()
            .forEach((element) {
          audioQuestionContainerKeys
              .add(GlobalKey<AudioQuestionContainerState>());
        });
      } else if (widget.tenderType == TenderTypes.tenderZone) {
        context.read<QuestionsCubit>().updateState(QuestionsFetchSuccess(
            questions: List.from(context.read<BookmarkCubit>().questions()),
            currentPoints: 0,
            tenderType: TenderTypes.bookmarkTender));
        timerAnimationController.forward();
      } else {
        context
            .read<GuessTheWordTenderCubit>()
            .updateState(GuessTheWordTenderFetchSuccess(
              questions: List.from(
                  context.read<GuessTheWordBookmarkCubit>().questions()),
              currentPoints: 0,
            ));

        context.read<GuessTheWordTenderCubit>().getQuestions().forEach((element) {
          guessTheWordQuestionContainerKeys
              .add(GlobalKey<GuessTheWordQuestionContainerState>());
        });
        timerAnimationController.forward();
      }
    });
  }

  @override
  void initState() {
    initializeAnimation();
    _getQuestions();
    super.initState();
  }

  void initializeAnimation() {
    questionContentAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250))
      ..forward();
    questionAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 525));
    questionSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionAnimationController, curve: Curves.easeInOut));
    questionScaleUpAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeInQuad)));
    questionContentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionContentAnimationController,
            curve: Curves.easeInQuad));
    questionScaleDownAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuad)));
  }

  void toggleSettingDialog() {
    isSettingDialogOpen = !isSettingDialogOpen;
  }

  //change to next Question
  void changeQuestion() {
    questionAnimationController.forward(from: 0.0).then((value) {
      //need to dispose the animation controllers
      questionAnimationController.dispose();
      questionContentAnimationController.dispose();
      //initializeAnimation again
      setState(() {
        initializeAnimation();
        currentQuestionIndex++;
      });
      //load content(options, image etc) of question
      questionContentAnimationController.forward();
    });
  }

  //if user has submitted the answer for current question
  bool hasSubmittedAnswerForCurrentQuestion() {
    return widget.tenderType == TenderTypes.guessTheWord
        ? false
        : context
            .read<QuestionsCubit>()
            .questions()[currentQuestionIndex]
            .attempted;
  }

  void submitAnswer(String submittedAnswer) async {
    timerAnimationController.stop();
    if (!context
        .read<QuestionsCubit>()
        .questions()[currentQuestionIndex]
        .attempted) {
      context.read<QuestionsCubit>().updateQuestionWithAnswerAndLifeline(
          context.read<QuestionsCubit>().questions()[currentQuestionIndex].id,
          submittedAnswer,
          context.read<UserDetailsCubit>().getUserFirebaseId(),
          context.read<SystemConfigCubit>().getPlayScore()); //change question
      await Future.delayed(
          const Duration(seconds: inBetweenQuestionTimeInSeconds));
      if (currentQuestionIndex !=
          (context.read<QuestionsCubit>().questions().length - 1)) {
        changeQuestion();
        if (widget.tenderType == TenderTypes.tenderZone) {
          timerAnimationController.forward(from: 0.0);
        } else {
          timerAnimationController.value = 0.0;
        }
      } else {
        setState(() {
          completedTender = true;
        });
      }
    }
  }

  void submitGuessTheWordAnswer(List<String> submittedAnswer) async {
    timerAnimationController.stop();
    final guessTheWordTenderCubit = context.read<GuessTheWordTenderCubit>();
    //if answer not submitted then submit answer
    if (!guessTheWordTenderCubit
        .getQuestions()[currentQuestionIndex]
        .hasAnswered) {
      //submitted answer
      guessTheWordTenderCubit.submitAnswer(
          guessTheWordTenderCubit.getQuestions()[currentQuestionIndex].id,
          submittedAnswer);
      //wait for some seconds
      await Future.delayed(
          const Duration(seconds: inBetweenQuestionTimeInSeconds));
      //if currentQuestion is last then complete tender to result screen
      if (currentQuestionIndex ==
          (guessTheWordTenderCubit.getQuestions().length - 1)) {
        //
        setState(() {
          completedTender = true;
        });
      } else {
        //change question
        changeQuestion();
        timerAnimationController.forward(from: 0.0);
      }
    }
  }

  //listener for current user timer
  void currentUserTimerAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      submitAnswer("-1");
    }
  }

  @override
  void dispose() {
    timerAnimationController
        .removeStatusListener(currentUserTimerAnimationStatusListener);
    timerAnimationController.dispose();
    questionAnimationController.dispose();
    questionContentAnimationController.dispose();
    showOptionAnimationController.dispose();
    super.dispose();
  }

  void onTapBackButton() {
    isExitDialogOpen = true;
    showDialog(context: context, builder: (context) => const ExitGameDialog())
        .then((value) => isExitDialogOpen = false);
  }

  Widget _buildQuestions() {
    if (widget.tenderType == TenderTypes.guessTheWord) {
      return BlocConsumer<GuessTheWordTenderCubit, GuessTheWordTenderState>(
          bloc: context.read<GuessTheWordTenderCubit>(),
          listener: (context, state) {},
          builder: (context, state) {
            if (state is GuessTheWordTenderFetchInProgress ||
                state is GuessTheWordTenderIntial) {
              return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor)),
              );
            }
            if (state is GuessTheWordTenderFetchFailure) {
              return Center(
                child: ErrorContainer(
                  showBackButton: true,
                  errorMessage: AppLocalization.of(context)!
                      .getTranslatedValues(
                          convertErrorCodeToLanguageKey(state.errorMessage)),
                  onTapRetry: () {
                    _getQuestions();
                  },
                  showErrorImage: true,
                ),
              );
            }
            final questions = (state as GuessTheWordTenderFetchSuccess).questions;

            return Align(
                alignment: Alignment.topCenter,
                child: QuestionsContainer(
                  showGuessTheWordHint: false,
                  timerAnimationController: timerAnimationController,
                  tenderType: widget.tenderType,
                  topPadding: MediaQuery.of(context).size.height *
                      UiUtils.getQuestionContainerTopPaddingPercentage(
                          MediaQuery.of(context).size.height),
                  showAnswerCorrectness: true,
                  lifeLines: const {},
                  hasSubmittedAnswerForCurrentQuestion: () {},
                  questions: const [],
                  submitAnswer: () {},
                  questionContentAnimation: questionContentAnimation,
                  questionScaleDownAnimation: questionScaleDownAnimation,
                  questionScaleUpAnimation: questionScaleUpAnimation,
                  questionSlideAnimation: questionSlideAnimation,
                  currentQuestionIndex: currentQuestionIndex,
                  questionAnimationController: questionAnimationController,
                  questionContentAnimationController:
                      questionContentAnimationController,
                  guessTheWordQuestions: questions,
                  guessTheWordQuestionContainerKeys:
                      guessTheWordQuestionContainerKeys,
                ));
          });
    }
    return BlocConsumer<QuestionsCubit, QuestionsState>(
        bloc: context.read<QuestionsCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is QuestionsFetchInProgress || state is QuestionsIntial) {
            return Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor)),
            );
          }
          if (state is QuestionsFetchFailure) {
            return Center(
              child: ErrorContainer(
                showBackButton: true,
                errorMessage: AppLocalization.of(context)!.getTranslatedValues(
                    convertErrorCodeToLanguageKey(state.errorMessage)),
                onTapRetry: () {
                  _getQuestions();
                },
                showErrorImage: true,
              ),
            );
          }
          final questions = (state as QuestionsFetchSuccess).questions;

          return Align(
              alignment: Alignment.topCenter,
              child: QuestionsContainer(
                audioQuestionContainerKeys: audioQuestionContainerKeys,
                timerAnimationController: timerAnimationController,
                tenderType: widget.tenderType,
                topPadding: MediaQuery.of(context).size.height *
                    UiUtils.getQuestionContainerTopPaddingPercentage(
                        MediaQuery.of(context).size.height),
                showAnswerCorrectness: true,
                lifeLines: const {},
                hasSubmittedAnswerForCurrentQuestion:
                    hasSubmittedAnswerForCurrentQuestion,
                questions: questions,
                submitAnswer: submitAnswer,
                questionContentAnimation: questionContentAnimation,
                questionScaleDownAnimation: questionScaleDownAnimation,
                questionScaleUpAnimation: questionScaleUpAnimation,
                questionSlideAnimation: questionSlideAnimation,
                currentQuestionIndex: currentQuestionIndex,
                questionAnimationController: questionAnimationController,
                questionContentAnimationController:
                    questionContentAnimationController,
                guessTheWordQuestions: const [],
                guessTheWordQuestionContainerKeys: const [],
              ));
        });
  }

  Widget _buildBottomButton() {
    if (widget.tenderType == TenderTypes.guessTheWord) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * (0.025)),
          child: CustomRoundedButton(
            widthPercentage: 0.5,
            backgroundColor: Theme.of(context).primaryColor,
            buttonTitle: AppLocalization.of(context)!
                .getTranslatedValues("submitBtn")!
                .toUpperCase(),
            elevation: 5.0,
            shadowColor: Colors.black45,
            titleColor: Theme.of(context).colorScheme.background,
            fontWeight: FontWeight.bold,
            onTap: () {
              submitGuessTheWordAnswer(
                  guessTheWordQuestionContainerKeys[currentQuestionIndex]
                      .currentState!
                      .getSubmittedAnswer());
            },
            radius: 10.0,
            showBorder: false,
            height: 45,
          ),
        ),
      );
    }
    if (widget.tenderType == TenderTypes.audioQuestions) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.5))
                  .animate(CurvedAnimation(
                      parent: showOptionAnimationController,
                      curve: Curves.easeInOut)),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * (0.025),
              left: MediaQuery.of(context).size.width * (0.2),
              right: MediaQuery.of(context).size.width * (0.2),
            ),
            child: CustomRoundedButton(
              widthPercentage: MediaQuery.of(context).size.width * (0.5),
              backgroundColor: Theme.of(context).primaryColor,
              buttonTitle: AppLocalization.of(context)!
                  .getTranslatedValues(showOptionsKey)!,
              radius: 5,
              onTap: () {
                if (!showOptionAnimationController.isAnimating) {
                  showOptionAnimationController.reverse();
                  audioQuestionContainerKeys[currentQuestionIndex]
                      .currentState!
                      .changeShowOption();
                  timerAnimationController.forward(from: 0.0);
                }
              },
              titleColor: Theme.of(context).colorScheme.background,
              showBorder: false,
              height: 40.0,
              elevation: 5.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (completedTender) {
          return Future.value(true);
        }
        onTapBackButton();
        return Future.value(false);
      },
      child: Scaffold(
        appBar: const QAppBar(roundedAppBar: false, title: SizedBox()),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: completedTender
                  ? Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${AppLocalization.of(context)!.getTranslatedValues("completeAllQueLbl")!} (:",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 18.0,
                              fontWeight: FontWeights.bold,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * (0.3)),
                            child: CustomRoundedButton(
                              widthPercentage:
                                  MediaQuery.of(context).size.width * (0.3),
                              backgroundColor:
                                  Theme.of(context).colorScheme.background,
                              buttonTitle: AppLocalization.of(context)!
                                  .getTranslatedValues("goBAckLbl")!,
                              titleColor: Theme.of(context).primaryColor,
                              radius: 5.0,
                              showBorder: false,
                              elevation: 5.0,
                              onTap: () {
                                if (isSettingDialogOpen) {
                                  Navigator.of(context).pop();
                                }
                                if (isExitDialogOpen) {
                                  Navigator.of(context).pop();
                                }

                                Navigator.of(context).pop();
                              },
                              height: 35.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildQuestions(),
            ),
            !completedTender ? _buildBottomButton() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
