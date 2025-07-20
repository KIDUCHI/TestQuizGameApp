import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/bid/bidRepository.dart';
import 'package:flutterquiz/features/bid/models/bid.dart';

abstract class BidsState {}

class BidsInitial extends BidsState {}

class BidsFetchInProgress extends BidsState {}

class BidsFetchSuccess extends BidsState {
  final List<Bid> bids;

  BidsFetchSuccess(this.bids);
}

class BidsFetchFailure extends BidsState {
  final String errorMessage;

  BidsFetchFailure(this.errorMessage);
}

class BidsCubit extends Cubit<BidsState> {
  final BidRepository _bidRepository;

  BidsCubit(this._bidRepository) : super(BidsInitial());

  void getBids({required String userId, required String languageId}) async {
    emit(BidsFetchInProgress());
    try {
      //today's all bid but unattempted
      //(status: 1-Not in Bid, 2-In bid, 3-Completed)
      List<Bid> bids = (await _bidRepository.getBids(
              userId: userId, languageId: languageId))
          .where((element) => element.bidStatus == "1")
          .toList(); //

      emit(BidsFetchSuccess(bids));
    } catch (e) {
      emit(BidsFetchFailure(e.toString()));
    }
  }
}
