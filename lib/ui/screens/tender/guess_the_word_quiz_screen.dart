import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/app/app_localization.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/bookmark/bookmarkRepository.dart';
import 'package:flutterquiz/features/bookmark/cubits/guessTheWordBookmarkCubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/updateBookmarkCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/updateScoreAndCoinsCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:flutterquiz/features/profileManagement/profileManagementRepository.dart';
import 'package:flutterquiz/features/tender/cubits/guessTheWordTenderCubit.dart';
import 'package:flutterquiz/features/tender/models/tenderType.dart';
import 'package:flutterquiz/features/tender/tenderRepository.dart';
import 'package:flutterquiz/features/systemConfig/cubits/systemConfigCubit.dart';
import 'package:flutterquiz/ui/screens/tender/widgets/guessTheWordQuestionContainer.dart';
import 'package:flutterquiz/ui/widgets/circularProgressContainer.dart';
import 'package:flutterquiz/ui/widgets/customAppbar.dart';
import 'package:flutterquiz/ui/widgets/customRoundedButton.dart';
import 'package:flutterquiz/ui/widgets/errorContainer.dart';
import 'package:flutterquiz/ui/widgets/exitGameDialog.dart';
import 'package:flutterquiz/ui/widgets/questionsContainer.dart';
import 'package:flutterquiz/ui/widgets/text_circular_timer.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class GuessTheWordTenderScreen extends StatefulWidget {
  final String type; //category or subcategory
  final String typeId; //id of category or subcategory
  final bool isPlayed;

  const GuessTheWordTenderScreen({
    super.key,
    required this.type,
    required this.typeId,
    required this.isPlayed,
  });

  @override
  State<GuessTheWordTenderScreen> createState() => _GuessTheWordTenderScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (_) =>
                UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
          ),
          BlocProvider<UpdateBookmarkCubit>(
            create: (_) => UpdateBookmarkCubit(BookmarkRepository()),
          ),
          BlocProvider<GuessTheWordTenderCubit>(
            create: (_) => GuessTheWordTenderCubit(TenderRepository()),
          )
        ],
        child: GuessTheWordTenderScreen(
          isPlayed: arguments['isPlayed'],
          type: arguments['type'],
          typeId: arguments['typeId'],
        ),
      ),
    );
  }
}

class _GuessTheWordTenderScreenState extends State<GuessTheWordTenderScreen>
    with TickerProviderStateMixin {
  late AnimationController timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(
          seconds: context.read<SystemConfigCubit>().getGuessTheWordTime()))
    ..addStatusListener(currentUserTimerAnimationStatusListener);

  //to animate the question container
  late AnimationController questionAnimationController;
  late AnimationController questionContentAnimationController;

  //to slide the question container from right to left
  late Animation<double> questionSlideAnimation;

  //to scale up the second question
  late Animation<double> questionScaleUpAnimation;

  //to scale down the second question
  late Animation<double> questionScaleDownAnimation;

  //to slude the question content from right to left
  late Animation<double> questionContentAnimation;

  int _currentQuestionIndex = 0;

  //to track if setting dialog is open
  bool isSettingDialogOpen = false;

  //
  double timeTakenToCompleteTender = 0;

  bool isExitDialogOpen = false;

  late List<GlobalKey<GuessTheWordQuestionContainerState>>
      questionContainerKeys = [];

  @override
  void initState() {
    super.initState();
    initializeAnimation();
    //fetching question for tender
    _getQuestions();
  }

  void _getQuestions() {
    Future.delayed(Duration.zero, () {
      context.read<GuessTheWordTenderCubit>().getQuestion(
            questionLanguageId: UiUtils.getCurrentQuestionLanguageId(context),
            type: widget.type,
            typeId: widget.typeId,
          );
    });
  }

  @override
  void dispose() {
    timerAnimationController
        .removeStatusListener(currentUserTimerAnimationStatusListener);
    timerAnimationController.dispose();
    questionContentAnimationController.dispose();
    questionAnimationController.dispose();

    super.dispose();
  }

  void initializeAnimation() {
    questionAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    questionContentAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));

    questionSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionAnimationController, curve: Curves.easeInOut));
    questionScaleUpAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeInQuad)));
    questionScaleDownAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuad)));
    questionContentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionContentAnimationController,
            curve: Curves.easeInQuad));
  }

  void toggleSettingDialog() {
    isSettingDialogOpen = !isSettingDialogOpen;
  }

  //listener for current user timer
  void currentUserTimerAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      updateBookmarkAnswer();
      submitAnswer(questionContainerKeys[_currentQuestionIndex]
          .currentState!
          .getSubmittedAnswer());
    }
  }

  void navigateToResultScreen() {
    if (isSettingDialogOpen) {
      Navigator.of(context).pop();
    }
    if (isExitDialogOpen) {
      Navigator.of(context).pop();
    }

    Navigator.of(context).pushReplacementNamed(Routes.result, arguments: {
      "myPoints": context.read<GuessTheWordTenderCubit>().getCurrentPoints(),
      "tenderType": TenderTypes.guessTheWord,
      "isPlayed": widget.isPlayed,
      "numberOfPlayer": 1,
      "timeTakenToCompleteTender": timeTakenToCompleteTender,
      "guessTheWordQuestions":
          context.read<GuessTheWordTenderCubit>().getQuestions(),
    });
  }

  void submitAnswer(List<String> submittedAnswer) async {
    timerAnimationController.stop();
    updateTimeTakenToCompleteTender();
    final guessTheWordTenderCubit = context.read<GuessTheWordTenderCubit>();
    //if answer not submitted then submit answer
    if (!guessTheWordTenderCubit
        .getQuestions()[_currentQuestionIndex]
        .hasAnswered) {
      //submitted answer
      guessTheWordTenderCubit.submitAnswer(
          guessTheWordTenderCubit.getQuestions()[_currentQuestionIndex].id,
          submittedAnswer);
      //wait for some seconds
      await Future.delayed(
          const Duration(seconds: inBetweenQuestionTimeInSeconds));
      //if currentQuestion is last then move user to result screen
      if (_currentQuestionIndex ==
          (guessTheWordTenderCubit.getQuestions().length - 1)) {
        navigateToResultScreen();
      } else {
        //change question
        changeQuestion();
        timerAnimationController.forward(from: 0.0);
      }
    }
  }

  void updateTimeTakenToCompleteTender() {
    timeTakenToCompleteTender = timeTakenToCompleteTender +
        UiUtils.timeTakenToSubmitAnswer(
            animationControllerValue: timerAnimationController.value,
            tenderType: TenderTypes.guessTheWord,
            guessTheWordTime:
                context.read<SystemConfigCubit>().getGuessTheWordTime(),
            tenderZoneTimer: context.read<SystemConfigCubit>().getTenderTime());
    print("Time to complete tender: $timeTakenToCompleteTender");
  }

  //next question
  void changeQuestion() {
    questionAnimationController.forward(from: 0.0).then((value) {
      //need to dispose the animation controllers
      questionAnimationController.dispose();
      questionContentAnimationController.dispose();
      //initializeAnimation again
      setState(() {
        initializeAnimation();
        _currentQuestionIndex++;
      });
      //load content(options, image etc) of question
      questionContentAnimationController.forward();
    });
  }

  //
  void updateBookmarkAnswer() {
    //update bookmark answer
    if (context.read<GuessTheWordBookmarkCubit>().hasQuestionBookmarked(context
        .read<GuessTheWordTenderCubit>()
        .getQuestions()[_currentQuestionIndex]
        .id)) {
      context.read<GuessTheWordBookmarkCubit>().updateSubmittedAnswer(
          questionId: context
              .read<GuessTheWordTenderCubit>()
              .getQuestions()[_currentQuestionIndex]
              .id,
          submittedAnswer: UiUtils.buildGuessTheWordQuestionAnswer(
              questionContainerKeys[_currentQuestionIndex]
                  .currentState!
                  .getSubmittedAnswer()),
          userId: context.read<UserDetailsCubit>().userId());
    } else {
      print("Question not bookmarked");
    }
  }

  Widget _buildQuestions(GuessTheWordTenderCubit guessTheWordTenderCubit) {
    return BlocBuilder<GuessTheWordTenderCubit, GuessTheWordTenderState>(
        builder: (context, state) {
      if (state is GuessTheWordTenderIntial ||
          state is GuessTheWordTenderFetchInProgress) {
        return const Center(
          child: CircularProgressContainer(whiteLoader: true),
        );
      }

      if (state is GuessTheWordTenderFetchSuccess) {
        return Align(
          alignment: Alignment.topCenter,
          child: QuestionsContainer(
            timerAnimationController: timerAnimationController,
            tenderType: TenderTypes.guessTheWord,
            showAnswerCorrectness: true,
            lifeLines: const {},
            guessTheWordQuestionContainerKeys: questionContainerKeys,
            topPadding: MediaQuery.of(context).size.height *
                UiUtils.getQuestionContainerTopPaddingPercentage(
                    MediaQuery.of(context).size.height),
            guessTheWordQuestions: state.questions,
            hasSubmittedAnswerForCurrentQuestion: () {},
            questions: const [],
            submitAnswer: () {},
            questionContentAnimation: questionContentAnimation,
            questionScaleDownAnimation: questionScaleDownAnimation,
            questionScaleUpAnimation: questionScaleUpAnimation,
            questionSlideAnimation: questionSlideAnimation,
            currentQuestionIndex: _currentQuestionIndex,
            questionAnimationController: questionAnimationController,
            questionContentAnimationController:
                questionContentAnimationController,
          ),
        );
      }

      if (state is GuessTheWordTenderFetchFailure) {
        return Center(
          child: ErrorContainer(
            errorMessageColor: Theme.of(context).colorScheme.background,
            showBackButton: true,
            errorMessage: AppLocalization.of(context)?.getTranslatedValues(
                convertErrorCodeToLanguageKey(state.errorMessage)),
            onTapRetry: _getQuestions,
            showErrorImage: true,
          ),
        );
      }

      return const SizedBox();
    });
  }

  Widget _buildSubmitButton(GuessTheWordTenderCubit guessTheWordTenderCubit) {
    return BlocBuilder<GuessTheWordTenderCubit, GuessTheWordTenderState>(
      bloc: guessTheWordTenderCubit,
      builder: (context, state) {
        if (state is GuessTheWordTenderFetchSuccess) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * (0.025)),
              child: CustomRoundedButton(
                widthPercentage: 0.5,
                backgroundColor: Theme.of(context).primaryColor,
                buttonTitle: AppLocalization.of(context)!
                    .getTranslatedValues("submitBtn")!,
                elevation: 5.0,
                shadowColor: Colors.black45,
                titleColor: Theme.of(context).colorScheme.background,
                fontWeight: FontWeight.bold,
                onTap: () {
                  //
                  updateBookmarkAnswer();
                  submitAnswer(questionContainerKeys[_currentQuestionIndex]
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
        return const SizedBox();
      },
    );
  }

  void onTapBackButton() {
    isExitDialogOpen = true;
    showDialog(context: context, builder: (_) => const ExitGameDialog())
        .then((value) => isExitDialogOpen = false);
  }

  Widget _buildBookmarkButton(GuessTheWordTenderCubit guessTheWordTenderCubit) {
    return BlocBuilder<GuessTheWordTenderCubit, GuessTheWordTenderState>(
      bloc: guessTheWordTenderCubit,
      builder: (context, state) {
        if (state is GuessTheWordTenderFetchSuccess) {
          //

          final bookmarkCubit = context.read<GuessTheWordBookmarkCubit>();
          final updateBookmarkCubit = context.read<UpdateBookmarkCubit>();
          return BlocListener<UpdateBookmarkCubit, UpdateBookmarkState>(
            bloc: updateBookmarkCubit,
            listener: (context, state) {
              //if failed to update bookmark status
              if (state is UpdateBookmarkFailure) {
                if (state.errorMessageCode == unauthorizedAccessCode) {
                  timerAnimationController.stop();
                  UiUtils.showAlreadyLoggedInDialog(context: context);
                  return;
                }

                //remove bookmark question
                if (state.failedStatus == "0") {
                  //if unable to remove question from bookmark then add question
                  //add again
                  bookmarkCubit.addBookmarkQuestion(
                      guessTheWordTenderCubit
                          .getQuestions()[_currentQuestionIndex],
                      context.read<UserDetailsCubit>().userId());
                } else {
                  //remove again
                  //if unable to add question to bookmark then remove question
                  bookmarkCubit.removeBookmarkQuestion(
                      guessTheWordTenderCubit
                          .getQuestions()[_currentQuestionIndex]
                          .id,
                      context.read<UserDetailsCubit>().userId());
                }
                UiUtils.setSnackbar(
                    AppLocalization.of(context)!.getTranslatedValues(
                        convertErrorCodeToLanguageKey(
                            updateBookmarkFailureCode))!,
                    context,
                    false);
              }
              if (state is UpdateBookmarkSuccess) {
                print("Success");
              }
            },
            child: BlocBuilder<GuessTheWordBookmarkCubit,
                GuessTheWordBookmarkState>(
              bloc: context.read<GuessTheWordBookmarkCubit>(),
              builder: (context, state) {
                print("State is $state");
                if (state is GuessTheWordBookmarkFetchSuccess) {
                  return InkWell(
                    onTap: () {
                      if (bookmarkCubit.hasQuestionBookmarked(
                          guessTheWordTenderCubit
                              .getQuestions()[_currentQuestionIndex]
                              .id)) {
                        //remove
                        bookmarkCubit.removeBookmarkQuestion(
                            guessTheWordTenderCubit
                                .getQuestions()[_currentQuestionIndex]
                                .id,
                            context.read<UserDetailsCubit>().userId());
                        updateBookmarkCubit.updateBookmark(
                          context.read<UserDetailsCubit>().userId(),
                          guessTheWordTenderCubit
                              .getQuestions()[_currentQuestionIndex]
                              .id,
                          "0",
                          "3", //type is 3 for guess the word questions
                        );
                      } else {
                        //add
                        bookmarkCubit.addBookmarkQuestion(
                            guessTheWordTenderCubit
                                .getQuestions()[_currentQuestionIndex],
                            context.read<UserDetailsCubit>().userId());
                        updateBookmarkCubit.updateBookmark(
                            context.read<UserDetailsCubit>().userId(),
                            guessTheWordTenderCubit
                                .getQuestions()[_currentQuestionIndex]
                                .id,
                            "1",
                            "3");
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Icon(
                        bookmarkCubit.hasQuestionBookmarked(
                                guessTheWordTenderCubit
                                    .getQuestions()[_currentQuestionIndex]
                                    .id)
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                        color: Theme.of(context).colorScheme.onTertiary,
                        size: 20,
                      ),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GuessTheWordTenderCubit guessTheWordTenderCubit =
        context.read<GuessTheWordTenderCubit>();
    return WillPopScope(
      onWillPop: () {
        onTapBackButton();
        return Future.value(false);
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<GuessTheWordTenderCubit, GuessTheWordTenderState>(
            bloc: guessTheWordTenderCubit,
            listener: (context, state) {
              if (state is GuessTheWordTenderFetchSuccess) {
                if (_currentQuestionIndex == 0 &&
                    !state.questions[_currentQuestionIndex].hasAnswered) {
                  for (var _ in state.questions) {
                    questionContainerKeys
                        .add(GlobalKey<GuessTheWordQuestionContainerState>());
                  }
                  //start timer
                  timerAnimationController.forward();
                  questionContentAnimationController.forward();
                }
              } else if (state is GuessTheWordTenderFetchFailure) {
                if (state.errorMessage == unauthorizedAccessCode) {
                  UiUtils.showAlreadyLoggedInDialog(context: context);
                }
              }
            },
          ),
          BlocListener<UpdateScoreAndCoinsCubit, UpdateScoreAndCoinsState>(
            listener: (context, state) {
              if (state is UpdateScoreAndCoinsFailure) {
                if (state.errorMessage == unauthorizedAccessCode) {
                  timerAnimationController.stop();
                  UiUtils.showAlreadyLoggedInDialog(context: context);
                }
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: QAppBar(
            roundedAppBar: false,
            onTapBackButton: onTapBackButton,
            title: TextCircularTimer(
              animationController: timerAnimationController,
              arcColor: Theme.of(context).primaryColor,
              color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.2),
            ),
            actions: [_buildBookmarkButton(guessTheWordTenderCubit)],
          ),
          body: Stack(
            children: [
              _buildQuestions(guessTheWordTenderCubit),
              _buildSubmitButton(guessTheWordTenderCubit),
            ],
          ),
        ),
      ),
    );
  }
}
