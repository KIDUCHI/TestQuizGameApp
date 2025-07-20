import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/contest.dart';

import '../tenderRepository.dart';

@immutable
abstract class ContestState {}

class ContestInitial extends ContestState {}

class ContestProgress extends ContestState {}

class ContestSuccess extends ContestState {
  final Contests contestList;

  ContestSuccess(
    this.contestList,
  );
}

class ContestFailure extends ContestState {
  final String errorMessage;
  ContestFailure(this.errorMessage);
}

class ContestCubit extends Cubit<ContestState> {
  final TenderRepository _tenderRepository;
  ContestCubit(this._tenderRepository) : super(ContestInitial());

  getContest(String? userId) async {
    emit(ContestProgress());
    _tenderRepository.getContest(userId).then((val) {
      emit(ContestSuccess(val));
    }).catchError((e) {
      emit(ContestFailure(e.toString()));
    });
  }
}
