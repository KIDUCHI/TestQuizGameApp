import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/tenderRepository.dart';

@immutable
abstract class UnlockedLevelState {}

class UnlockedLevelInitial extends UnlockedLevelState {}

class UnlockedLevelFetchInProgress extends UnlockedLevelState {}

class UnlockedLevelFetchSuccess extends UnlockedLevelState {
  final int unlockedLevel;
  final String? categoryId;
  final String? subcategoryId;

  UnlockedLevelFetchSuccess(
      this.categoryId, this.subcategoryId, this.unlockedLevel);
}

class UnlockedLevelFetchFailure extends UnlockedLevelState {
  final String errorMessage;
  UnlockedLevelFetchFailure(this.errorMessage);
}

class UnlockedLevelCubit extends Cubit<UnlockedLevelState> {
  final TenderRepository _tenderRepository;
  UnlockedLevelCubit(this._tenderRepository) : super(UnlockedLevelInitial());

  void fetchUnlockLevel(
      String? userId, String? category, String? subCategory) async {
    emit(UnlockedLevelFetchInProgress());
    _tenderRepository
        .getUnlockedLevel(userId, category, subCategory)
        .then(
          (val) =>
              emit((UnlockedLevelFetchSuccess(category, subCategory, val))),
        )
        .catchError((e) {
      emit(UnlockedLevelFetchFailure(e.toString()));
    });
  }
}
