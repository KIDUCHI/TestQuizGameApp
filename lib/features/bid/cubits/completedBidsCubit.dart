import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bid/bidRepository.dart';
import 'package:flutterquiz/features/bid/models/bidResult.dart';

abstract class CompletedBidsState {}

class CompletedBidsInitial extends CompletedBidsState {}

class CompletedBidsFetchInProgress extends CompletedBidsState {}

class CompletedBidsFetchSuccess extends CompletedBidsState {
  final List<BidResult> completedBids;
  final int totalResultCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  CompletedBidsFetchSuccess({
    required this.completedBids,
    required this.totalResultCount,
    required this.hasMoreFetchError,
    required this.hasMore,
  });
}

class CompletedBidsFetchFailure extends CompletedBidsState {
  final String errorMessage;

  CompletedBidsFetchFailure(this.errorMessage);
}

class CompletedBidsCubit extends Cubit<CompletedBidsState> {
  final BidRepository _bidRepository;

  CompletedBidsCubit(this._bidRepository) : super(CompletedBidsInitial());

  final int limit = 15;

  void getCompletedBids(
      {required String userId, required String languageId}) async {
    try {
      //
      final result = await _bidRepository.getCompletedBids(
          userId: userId,
          languageId: languageId,
          limit: limit.toString(),
          offset: "0");
      emit(CompletedBidsFetchSuccess(
        completedBids: result['results'],
        totalResultCount: int.parse(result['total']),
        hasMoreFetchError: false,
        hasMore: (result['results'] as List<BidResult>).length <
            int.parse(result['total']),
      ));
    } catch (e) {
      emit(CompletedBidsFetchFailure(e.toString()));
    }
  }

  bool hasMoreResult() {
    if (state is CompletedBidsFetchSuccess) {
      return (state as CompletedBidsFetchSuccess).hasMore;
    }
    return false;
  }

  void getMoreResult({
    required String userId,
    required String languageId,
  }) async {
    if (state is CompletedBidsFetchSuccess) {
      try {
        //
        final result = await _bidRepository.getCompletedBids(
          userId: userId,
          languageId: languageId,
          limit: limit.toString(),
          offset: (state as CompletedBidsFetchSuccess)
              .completedBids
              .length
              .toString(),
        );
        List<BidResult> updatedResults =
            (state as CompletedBidsFetchSuccess).completedBids;
        updatedResults.addAll(result['results'] as List<BidResult>);
        emit(CompletedBidsFetchSuccess(
          completedBids: updatedResults,
          totalResultCount: int.parse(result['total']),
          hasMoreFetchError: false,
          hasMore: updatedResults.length < int.parse(result['total']),
        ));
        //
      } catch (e) {
        //in case of any error
        emit(CompletedBidsFetchSuccess(
          completedBids: (state as CompletedBidsFetchSuccess).completedBids,
          hasMoreFetchError: true,
          totalResultCount:
              (state as CompletedBidsFetchSuccess).totalResultCount,
          hasMore: (state as CompletedBidsFetchSuccess).hasMore,
        ));
      }
    }
  }
}
