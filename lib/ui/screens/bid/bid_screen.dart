import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:flutterquiz/app/app_localization.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/bid/cubits/bidCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:flutterquiz/features/quiz/models/quizType.dart';
import 'package:flutterquiz/ui/screens/bid/widgets/bidQuestionStatusBottomSheetContainer.dart';
import 'package:flutterquiz/ui/screens/bid/widgets/bidTimerContainer.dart';
import 'package:flutterquiz/ui/screens/quiz/widgets/questionContainer.dart';
import 'package:flutterquiz/ui/widgets/customAppbar.dart';
import 'package:flutterquiz/ui/widgets/exitGameDialog.dart';
import 'package:flutterquiz/ui/widgets/optionContainer.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:ios_insecure_screen_detector/ios_insecure_screen_detector.dart';
import 'package:wakelock/wakelock.dart';

class BidScreen extends StatefulWidget {
  const BidScreen({super.key});

  @override
  State<BidScreen> createState() => _BidScreenState();

  static Route<BidScreen> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (context) => const BidScreen());
  }
}

class _BidScreenState extends State<BidScreen> with WidgetsBindingObserver {
  final timerKey = GlobalKey<BidTimerContainerState>();

  late final pageController = PageController();

  Timer? canGiveBidAgainTimer;
  bool canGiveBidAgain = true;

  int canGiveBidAgainTimeInSeconds = 5;

  bool isExitDialogOpen = false;
  bool userLeftTheBid = false;

  bool showYouLeftTheBid = false;
  bool isBidQuestionStatusBottomSheetOpen = false;

  int currentQuestionIndex = 0;

  IosInsecureScreenDetector? _iosInsecureScreenDetector;
  late bool isScreenRecordingInIos = false;

  List<String> iosCapturedScreenshotQuestionIds = [];

  @override
  void initState() {
    super.initState();

    //wake lock enable so phone will not lock automatically after sometime

    Wakelock.enable();

    WidgetsBinding.instance.addObserver(this);

    if (Platform.isIOS) {
      initScreenshotAndScreenRecordDetectorInIos();
    } else {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }

    //start timer
    Future.delayed(Duration.zero, () {
      timerKey.currentState?.startTimer();
    });
  }

  void initScreenshotAndScreenRecordDetectorInIos() async {
    _iosInsecureScreenDetector = IosInsecureScreenDetector();
    await _iosInsecureScreenDetector?.initialize();
    _iosInsecureScreenDetector?.addListener(
        iosScreenshotCallback, iosScreenRecordCallback);
  }

  void iosScreenshotCallback() {
    print("User took screenshot");
    iosCapturedScreenshotQuestionIds.add(
        context.read<BidCubit>().getQuestions()[currentQuestionIndex].id!);
  }

  void iosScreenRecordCallback(bool isRecording) {
    setState(() => isScreenRecordingInIos = isRecording);
  }

  void setCanGiveBidTimer() {
    canGiveBidAgainTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (canGiveBidAgainTimeInSeconds == 0) {
          timer.cancel();

          //can give Bid again false
          canGiveBidAgain = false;

          //show user left the bid
          setState(() => showYouLeftTheBid = true);
          //submit result
          submitResult();
        } else {
          canGiveBidAgainTimeInSeconds--;
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(appState) {
    if (appState == AppLifecycleState.paused) {
      setCanGiveBidTimer();
    } else if (appState == AppLifecycleState.resumed) {
      canGiveBidAgainTimer?.cancel();
      //if user can give bid again
      if (canGiveBidAgain) {
        canGiveBidAgainTimeInSeconds = 5;
      }
    }
  }

  @override
  void dispose() {
    canGiveBidAgainTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    Wakelock.disable();
    _iosInsecureScreenDetector?.dispose();
    if (Platform.isAndroid) {
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
    super.dispose();
  }

  void showBidQuestionStatusBottomSheet() {
    isBidQuestionStatusBottomSheetOpen = true;
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: UiUtils.bottomSheetTopRadius,
      ),
      builder: (_) => BidQuestionStatusBottomSheetContainer(
        navigateToResultScreen: navigateToResultScreen,
        pageController: pageController,
      ),
    ).then((_) => isBidQuestionStatusBottomSheetOpen = false);
  }

  bool hasSubmittedAnswerForCurrentQuestion() {
    return context
        .read<BidCubit>()
        .getQuestions()[currentQuestionIndex]
        .attempted;
  }

  void submitResult() {
    context.read<BidCubit>().submitResult(
          capturedQuestionIds: iosCapturedScreenshotQuestionIds,
          rulesViolated: iosCapturedScreenshotQuestionIds.isNotEmpty,
          userId: context.read<UserDetailsCubit>().getUserFirebaseId(),
          totalDuration:
              timerKey.currentState?.getCompletedBidDuration().toString() ??
                  "0",
        );
  }

  void submitAnswer(String submittedAnswerId) {
    var bidCubit = context.read<BidCubit>();
    if (hasSubmittedAnswerForCurrentQuestion()) {
      if (bidCubit.canUserSubmitAnswerAgainInBid()) {
        bidCubit.updateQuestionWithAnswer(
            bidCubit.getQuestions()[currentQuestionIndex].id!,
            submittedAnswerId);
      }
    } else {
      bidCubit.updateQuestionWithAnswer(
          bidCubit.getQuestions()[currentQuestionIndex].id!,
          submittedAnswerId);
    }
  }

  void navigateToResultScreen() {
    if (isExitDialogOpen) {
      Navigator.of(context).pop();
    }

    if (isBidQuestionStatusBottomSheetOpen) {
      Navigator.of(context).pop();
    }

    submitResult();

    final userFirebaseId = context.read<UserDetailsCubit>().getUserFirebaseId();
    final bidCubit = context.read<BidCubit>();
    Navigator.of(context).pushReplacementNamed(
      Routes.result,
      arguments: {
        "quizType": QuizTypes.bid,
        "bid": bidCubit.getBid(),
        "obtainedMarks": bidCubit.obtainedMarks(userFirebaseId),
        "bidCompletedInMinutes":
            timerKey.currentState?.getCompletedBidDuration(),
        "correctBidAnswers": bidCubit.correctAnswers(userFirebaseId),
        "incorrectBidAnswers": bidCubit.incorrectAnswers(userFirebaseId),
        "numberOfPlayer": 1,
      },
    );
  }

  Widget _buildBottomMenu() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * UiUtils.hzMarginPct,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.onTertiary.withOpacity(0.2),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Opacity(
              opacity: currentQuestionIndex != 0 ? 1.0 : 0.5,
              child: IconButton(
                onPressed: () {
                  if (currentQuestionIndex != 0) {
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              color: Theme.of(context).colorScheme.onTertiary,
            ),
            padding: const EdgeInsets.only(left: 42, right: 48),
            child: IconButton(
              onPressed: () {
                showBidQuestionStatusBottomSheet();
              },
              icon: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Theme.of(context).colorScheme.background,
                size: 40,
              ),
            ),
          ),
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    Theme.of(context).colorScheme.onTertiary.withOpacity(0.2),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            child: Opacity(
              opacity: (context.read<BidCubit>().getQuestions().length - 1) !=
                      currentQuestionIndex
                  ? 1.0
                  : 0.5,
              child: IconButton(
                onPressed: () {
                  if (context.read<BidCubit>().getQuestions().length - 1 !=
                      currentQuestionIndex) {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouLeftTheBid() {
    if (showYouLeftTheBid) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          child: AlertDialog(
            content: Text(
              AppLocalization.of(context)!
                  .getTranslatedValues(youLeftTheBidKey)!,
              style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalization.of(context)!.getTranslatedValues(okayLbl)!,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildQuestions() {
    return BlocBuilder<BidCubit, BidState>(
      bloc: context.read<BidCubit>(),
      builder: (context, state) {
        if (state is BidFetchSuccess) {
          return PageView.builder(
            onPageChanged: (index) {
              setState(() => currentQuestionIndex = index);
            },
            controller: pageController,
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    QuestionContainer(
                      isMathQuestion: false,
                      questionColor: Theme.of(context).colorScheme.onTertiary,
                      questionNumber: index + 1,
                      question: state.questions[index],
                    ),
                    const SizedBox(height: 25),
                    ...state.questions[index].answerOptions!
                        .map(
                          (option) => OptionContainer(
                            quizType: QuizTypes.bid,
                            showAnswerCorrectness: false,
                            showAudiencePoll: false,
                            hasSubmittedAnswerForCurrentQuestion:
                                hasSubmittedAnswerForCurrentQuestion,
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * (0.85),
                              maxHeight: MediaQuery.of(context).size.height *
                                  UiUtils.questionContainerHeightPercentage,
                            ),
                            answerOption: option,
                            correctOptionId:
                                AnswerEncryption.decryptCorrectAnswer(
                              rawKey: context
                                  .read<UserDetailsCubit>()
                                  .getUserFirebaseId(),
                              correctAnswer:
                                  state.questions[index].correctAnswer!,
                            ),
                            submitAnswer: submitAnswer,
                            submittedAnswerId:
                                state.questions[index].submittedAnswerId,
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (showYouLeftTheBid) {
          return Future.value(true);
        }

        onTapBackButton();
        return Future.value(false);
      },
      child: Scaffold(
        appBar: QAppBar(
          roundedAppBar: false,
          title: BidTimerContainer(
            navigateToResultScreen: navigateToResultScreen,
            bidDurationInMinutes:
                int.parse(context.read<BidCubit>().getBid().duration),
            key: timerKey,
          ),
          onTapBackButton: () {
            onTapBackButton();
            return Future.value(false);
          },
        ),
        body: Stack(
          children: [
            _buildQuestions(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomMenu(),
            ),
            _buildYouLeftTheBid(),
            if (isScreenRecordingInIos)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: const ColoredBox(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  void onTapBackButton() {
    isExitDialogOpen = true;
    showDialog(
      context: context,
      builder: (_) => ExitGameDialog(
        onTapYes: () {
          submitResult();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    ).then((_) => isExitDialogOpen = false);
  }
}
