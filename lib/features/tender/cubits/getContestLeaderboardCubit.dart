import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/contestLeaderboard.dart';
import '../tenderRepository.dart';

@immutable
abstract class GetContestLeaderboardState {}

class GetContestLeaderboardInitial extends GetContestLeaderboardState {}

class GetContestLeaderboardProgress extends GetContestLeaderboardState {}

class GetContestLeaderboardSuccess extends GetContestLeaderboardState {
  final List<ContestLeaderboard> getContestLeaderboardList;

  GetContestLeaderboardSuccess(this.getContestLeaderboardList);
}

class GetContestLeaderboardFailure extends GetContestLeaderboardState {
  final String errorMessage;

  GetContestLeaderboardFailure(this.errorMessage);
}

class GetContestLeaderboardCubit extends Cubit<GetContestLeaderboardState> {
  final TenderRepository _tenderRepository;

  GetContestLeaderboardCubit(this._tenderRepository)
      : super(GetContestLeaderboardInitial());

  getContestLeaderboard({String? userId, String? contestId}) async {
    emit(GetContestLeaderboardProgress());
    _tenderRepository
        .getContestLeaderboard(userId: userId, contestId: contestId)
        .then((val) => emit(GetContestLeaderboardSuccess(val)))
        .catchError((e) => emit(GetContestLeaderboardFailure(e.toString())));
  }
}
