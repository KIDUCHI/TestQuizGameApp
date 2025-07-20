import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/app/app_localization.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/bid/cubits/completedBidsCubit.dart';
import 'package:flutterquiz/features/bid/cubits/bidsCubit.dart';
import 'package:flutterquiz/features/bid/bidRepository.dart';
import 'package:flutterquiz/features/bid/models/bid.dart';
import 'package:flutterquiz/features/bid/models/bidResult.dart';
import 'package:flutterquiz/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:flutterquiz/ui/screens/bid/bid_result_screen.dart';
import 'package:flutterquiz/ui/screens/bid/widgets/bidKeyBottomSheetContainer.dart';
import 'package:flutterquiz/ui/widgets/bannerAdContainer.dart';
import 'package:flutterquiz/ui/widgets/circularProgressContainer.dart';
import 'package:flutterquiz/ui/widgets/customAppbar.dart';
import 'package:flutterquiz/ui/widgets/errorContainer.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';
import 'package:flutterquiz/utils/datetime_utils.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class BidsScreen extends StatefulWidget {
  const BidsScreen({super.key});

  @override
  State<BidsScreen> createState() => _BidsScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<BidsCubit>(create: (_) => BidsCubit(ExamRepository())),
          BlocProvider<CompletedBidsCubit>(
            create: (_) => CompletedBidsCubit(ExamRepository()),
          ),
        ],
        child: const BidsScreen(),
      ),
    );
  }
}

class _BidsScreenState extends State<BidsScreen> {
  int currentSelectedQuestionIndex = 0;

  late final _completedExamScrollController = ScrollController()
    ..addListener(hasMoreResultScrollListener);

  ///
  late final String userId;
  late final String languageId;

  void hasMoreResultScrollListener() {
    if (_completedExamScrollController.position.maxScrollExtent ==
        _completedExamScrollController.offset) {
      log("At the end of the list");

      ///
      if (context.read<CompletedBidsCubit>().hasMoreResult()) {
        context.read<CompletedBidsCubit>().getMoreResult(
              userId: userId,
              languageId: languageId,
            );
      } else {
        log("No more result");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    userId = context.read<UserDetailsCubit>().userId();
    languageId = UiUtils.getCurrentQuestionLanguageId(context);

    getBids();
    getCompletedBids();
  }

  @override
  void dispose() {
    _completedExamScrollController.removeListener(hasMoreResultScrollListener);
    _completedExamScrollController.dispose();
    super.dispose();
  }

  void getBids() {
    Future.delayed(Duration.zero, () {
      context
          .read<BidsCubit>()
          .getBids(userId: userId, languageId: languageId);
    });
  }

  void getCompletedBids() {
    Future.delayed(Duration.zero, () {
      context
          .read<CompletedBidsCubit>()
          .getCompletedBids(userId: userId, languageId: languageId);
    });
  }

  void showExamKeyBottomSheet(BuildContext context, Exam bid) {
    showModalBottomSheet(
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: UiUtils.bottomSheetTopRadius,
      ),
      builder: (_) => ExamKeyBottomSheetContainer(
        navigateToExamScreen: navigateToExamScreen,
        bid: bid,
      ),
    );
  }

  // void showExamResultBottomSheet(BuildContext context, ExamResult bidResult) {
  //   showModalBottomSheet(
  //     isScrollControlled: true,
  //     elevation: 5.0,
  //     context: context,
  //     enableDrag: true,
  //     isDismissible: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: UiUtils.bottomSheetTopRadius,
  //     ),
  //     builder: (_) => ExamResultBottomSheetContainer(bidResult: bidResult),
  //   );
  // }

  void navigateToExamScreen() async {
    Navigator.of(context).pop();

    Navigator.of(context).pushNamed(Routes.bid).then((value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          print("Fetch bid details again");
          //fetch bids again with fresh status
          context
              .read<BidsCubit>()
              .getBids(userId: userId, languageId: languageId);
          //fetch completed bid again with fresh status
          context
              .read<CompletedBidsCubit>()
              .getCompletedBids(userId: userId, languageId: languageId);
        }
      });
    });
  }

  Widget _buildExamResults() {
    return BlocConsumer<CompletedBidsCubit, CompletedBidsState>(
      listener: (context, state) {
        if (state is CompletedBidsFetchFailure) {
          if (state.errorMessage == unauthorizedAccessCode) {
            UiUtils.showAlreadyLoggedInDialog(context: context);
          }
        }
      },
      bloc: context.read<CompletedBidsCubit>(),
      builder: (context, state) {
        if (state is CompletedBidsFetchInProgress ||
            state is CompletedBidsInitial) {
          return const Center(child: CircularProgressContainer());
        }
        if (state is CompletedBidsFetchFailure) {
          return Center(
            child: ErrorContainer(
                errorMessageColor: Theme.of(context).primaryColor,
                errorMessage: AppLocalization.of(context)!.getTranslatedValues(
                    convertErrorCodeToLanguageKey(state.errorMessage)),
                onTapRetry: getCompletedBids,
                showErrorImage: true),
          );
        }
        return ListView.builder(
          controller: _completedExamScrollController,
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.width * UiUtils.vtMarginPct,
            horizontal: MediaQuery.of(context).size.width * UiUtils.hzMarginPct,
          ),
          itemCount:
              (state as CompletedBidsFetchSuccess).completedBids.length,
          itemBuilder: (context, index) {
            return _buildResultContainer(
              bidResult: state.completedBids[index],
              hasMoreResultFetchError: state.hasMoreFetchError,
              index: index,
              totalExamResults: state.completedBids.length,
              hasMore: state.hasMore,
            );
          },
        );
      },
    );
  }

  Widget _buildTodayBids() {
    return BlocConsumer<BidsCubit, BidsState>(
      listener: (_, state) {
        if (state is BidsFetchFailure) {
          if (state.errorMessage == unauthorizedAccessCode) {
            UiUtils.showAlreadyLoggedInDialog(context: context);
          }
        }
      },
      bloc: context.read<BidsCubit>(),
      builder: (context, state) {
        if (state is BidsFetchInProgress || state is BidsInitial) {
          return const Center(child: CircularProgressContainer());
        }
        if (state is BidsFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessageColor: Theme.of(context).primaryColor,
              errorMessage: AppLocalization.of(context)!.getTranslatedValues(
                  convertErrorCodeToLanguageKey(state.errorMessage)),
              onTapRetry: getBids,
              showErrorImage: true,
            ),
          );
        }

        final bids = (state as BidsFetchSuccess).bids;

        if (bids.isEmpty) {
          return Center(
            child: Text(
              AppLocalization.of(context)!
                  .getTranslatedValues("allBidsCompleteLbl")!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiary,
                fontSize: 20.0,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * UiUtils.vtMarginPct,
            horizontal: MediaQuery.of(context).size.width * UiUtils.hzMarginPct,
          ),
          itemCount: bids.length,
          itemBuilder: (_, i) => _buildTodayExamContainer(bids[i]),
          separatorBuilder: (_, i) => const SizedBox(height: 10),
        );
      },
    );
  }

  Widget _buildTodayExamContainer(Exam bid) {
    final formattedDate = DateTimeUtils.dateFormat.format(
      DateTime.parse(bid.date),
    );
    print("Exam Duration: ${bid.duration}");
    return GestureDetector(
      onTap: () => showExamKeyBottomSheet(context, bid),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8.0),
        ),
        height: MediaQuery.of(context).size.height * 0.1,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Exam title
                  Text(
                    bid.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  /// Date & Duration
                  Text(
                    "$formattedDate  |  ${bid.duration} min",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onTertiary
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            /// Marks
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.transparent,
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.onTertiary.withOpacity(0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Text(
                "${bid.totalMarks} ${AppLocalization.of(context)!.getTranslatedValues(markKey)!}",
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onTertiary.withOpacity(0.6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContainer({
    required ExamResult bidResult,
    required int index,
    required int totalExamResults,
    required bool hasMoreResultFetchError,
    required bool hasMore,
  }) {
    if (index == totalExamResults - 1) {
      //check if hasMore
      if (hasMore) {
        if (hasMoreResultFetchError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: IconButton(
                onPressed: () {
                  context.read<CompletedBidsCubit>().getMoreResult(
                        userId: userId,
                        languageId: languageId,
                      );
                },
                icon: Icon(
                  Icons.error,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: CircularProgressContainer(),
            ),
          );
        }
      }
    }

    final formattedDate = DateTimeUtils.dateFormat.format(
      DateTime.parse(bidResult.date),
    );
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => ExamResultScreen(bidResult: bidResult),
        ));
        // showExamResultBottomSheet(context, bidResult);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8.0),
        ),
        height: MediaQuery.of(context).size.height * .1,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  width: MediaQuery.of(context).size.width * (0.5),
                  child: Text(
                    bidResult.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: MediaQuery.of(context).size.width * (0.5),
                  child: Text(
                    formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onTertiary
                          .withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.transparent,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  "${bidResult.obtainedMarks()}/${bidResult.totalMarks} ${AppLocalization.of(context)!.getTranslatedValues(markKey)!} ",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: QAppBar(
          title:
              Text(AppLocalization.of(context)!.getTranslatedValues("bid")!),
          bottom: TabBar(
            tabs: [
              Tab(
                text:
                    AppLocalization.of(context)!.getTranslatedValues(dailyLbl)!,
              ),
              Tab(
                text: AppLocalization.of(context)!
                    .getTranslatedValues(completedLbl)!,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildTodayBids(),
                _buildExamResults(),
              ],
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BannerAdContainer(),
            ),
          ],
        ),
      ),
    );
  }
}
