import 'package:flutterquiz/features/bid/bidException.dart';
import 'package:flutterquiz/features/bid/bidLocalDataSource.dart';
import 'package:flutterquiz/features/bid/bidRemoteDataSource.dart';
import 'package:flutterquiz/features/bid/models/bid.dart';
import 'package:flutterquiz/features/bid/models/bidResult.dart';
import 'package:flutterquiz/features/tender/models/question.dart';

class BidRepository {
  static final BidRepository _bidRepository = BidRepository._internal();
  late BidRemoteDataSource _bidRemoteDataSource;
  late BidLocalDataSource _bidLocalDataSource;

  factory BidRepository() {
    _bidRepository._bidRemoteDataSource = BidRemoteDataSource();
    _bidRepository._bidLocalDataSource = BidLocalDataSource();
    return _bidRepository;
  }

  BidRepository._internal();

  BidLocalDataSource get bidLocalDataSource => _bidLocalDataSource;

  Future<List<Bid>> getBids(
      {required String userId, required String languageId}) async {
    try {
      final result = (await _bidRemoteDataSource.getBids(
          limit: "",
          offset: "",
          userId: userId,
          languageId: languageId,
          type: "1"))['data'] as List;
      return result.map((e) => Bid.fromJson(e)).toList();
    } catch (e) {
      throw BidException(errorMessageCode: e.toString());
    }
  }

  Future<Map<String, dynamic>> getCompletedBids(
      {required String userId,
      required String languageId,
      required String offset,
      required String limit}) async {
    try {
      final result = await _bidRemoteDataSource.getBids(
        userId: userId,
        languageId: languageId,
        type: "2",
        limit: limit,
        offset: offset,
      );
      return {
        "total": result['total'],
        "results": (result['data'] as List)
            .map((e) => BidResult.fromJson(e))
            .toList(),
      };
    } catch (e) {
      throw BidException(errorMessageCode: e.toString());
    }
  }

  Future<List<Question>> getBidMouduleQuestions(
      {required String bidModuleId}) async {
    try {
      final result = await _bidRemoteDataSource.getQuestionForBid(
          bidModuleId: bidModuleId);
      return result.map((e) => Question.fromJson(Map.from(e))).toList();
    } catch (e) {
      throw BidException(errorMessageCode: e.toString());
    }
  }

  Future<void> updateBidStatusToInBid(
      {required String bidModuleId, required String userId}) async {
    try {
      await _bidRemoteDataSource.updateBidStatusToInBid(
          bidModuleId: bidModuleId, userId: userId);
    } catch (e) {
      throw BidException(errorMessageCode: e.toString());
    }
  }

  Future<void> submitBidResult({
    required String obtainedMarks,
    required String bidModuleId,
    required String userId,
    required String totalDuration,
    required List<Map<String, dynamic>> statistics,
    required bool rulesViolated,
    required List<String> capturedQuestionIds,
  }) async {
    try {
      await _bidRemoteDataSource.submitBidResult(
          capturedQuestionIds: capturedQuestionIds,
          rulesViolated: rulesViolated,
          bidModuleId: bidModuleId,
          userId: userId,
          totalDuration: totalDuration,
          statistics: statistics,
          obtainedMarks: obtainedMarks);
    } catch (e) {
      print(e.toString());
      //throw BidException(errorMessageCode: e.toString());
    }
  }

  Future<void> completePendingBids({required String userId}) async {
    //
    List<String> pendingBidIds = _bidLocalDataSource.getAllBidModuleIds();
    for (var element in pendingBidIds) {
      submitBidResult(
        bidModuleId: element,
        userId: userId,
        totalDuration: "0",
        statistics: [],
        obtainedMarks: "0",
        rulesViolated: false,
        capturedQuestionIds: [],
      );
    }

    //delete bids
    for (var element in pendingBidIds) {
      _bidLocalDataSource.removeBidModuleId(element);
    }
  }
}
