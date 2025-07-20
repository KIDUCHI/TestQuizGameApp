import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/tender/models/category.dart';
import '../tenderRepository.dart';

@immutable
abstract class TenderCategoryState {}

class TenderCategoryInitial extends TenderCategoryState {}

class TenderCategoryProgress extends TenderCategoryState {}

class TenderCategorySuccess extends TenderCategoryState {
  final List<Category> categories;
  TenderCategorySuccess(this.categories);
}

class TenderCategoryFailure extends TenderCategoryState {
  final String errorMessage;
  TenderCategoryFailure(this.errorMessage);
}

class TenderCategoryCubit extends Cubit<TenderCategoryState> {
  final TenderRepository _tenderRepository;
  TenderCategoryCubit(this._tenderRepository) : super(TenderCategoryInitial());

  void getTenderCategoryWithUserId({
    required String languageId,
    required String type,
    required String userId,
  }) async {
    emit(TenderCategoryProgress());
    _tenderRepository
        .getCategory(languageId: languageId, type: type, userId: userId)
        .then((v) => emit(TenderCategorySuccess(v)))
        .catchError((e) => emit(TenderCategoryFailure(e.toString())));
  }

  void getTenderCategory({
    required String languageId,
    required String type,
  }) async {
    emit(TenderCategoryProgress());
    _tenderRepository
        .getCategorywithoutuser(languageId: languageId, type: type)
        .then((v) => emit(TenderCategorySuccess(v)))
        .catchError((e) => emit(TenderCategoryFailure(e.toString())));
  }

  void updateState(TenderCategoryState updatedState) {
    emit(updatedState);
  }

  getCat() {
    if (state is TenderCategorySuccess) {
      return (state as TenderCategorySuccess).categories;
    }
    return "";
  }
}
