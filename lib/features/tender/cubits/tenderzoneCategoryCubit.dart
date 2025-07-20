import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/category.dart';
import '../tenderRepository.dart';

@immutable
abstract class TenderzoneCategoryState {}

class TenderzoneCategoryInitial extends TenderzoneCategoryState {}

class TenderzoneCategoryProgress extends TenderzoneCategoryState {}

class TenderzoneCategorySuccess extends TenderzoneCategoryState {
  final List<Category> categories;
  TenderzoneCategorySuccess(this.categories);
}

class TenderzoneCategoryFailure extends TenderzoneCategoryState {
  final String errorMessage;
  TenderzoneCategoryFailure(this.errorMessage);
}

class TenderzoneCategoryCubit extends Cubit<TenderzoneCategoryState> {
  final TenderzRepository _tenderRepository;
  TenderzoneCategoryCubit(this._tenderRepository) : super(TenderzoneCategoryInitial());

  void getTenderzCategoryWithUserId({
    required String languageId,
    required String userId,
  }) async {
    emit(TenderzoneCategoryProgress());
    _tenderRepository
        .getCategory(languageId: languageId, type: "1", userId: userId)
        .then(
      (v) {
        emit(TenderzoneCategorySuccess(v));
      },
    ).catchError(
      (e) {
        emit(TenderzoneCategoryFailure(e.toString()));
      },
    );
  }

  void getTenderzCategory({required String languageId}) async {
    emit(TenderzoneCategoryProgress());
    _tenderRepository
        .getCategorywithoutuser(languageId: languageId, type: "1")
        .then((v) => emit(TenderzoneCategorySuccess(v)))
        .catchError((e) => emit(TenderzoneCategoryFailure(e.toString())));
  }

  void updateState(TenderzoneCategoryState updatedState) {
    emit(updatedState);
  }

  getCat() {
    if (state is TenderzoneCategorySuccess) {
      return (state as TenderzoneCategorySuccess).categories;
    }
    return "";
  }
}
