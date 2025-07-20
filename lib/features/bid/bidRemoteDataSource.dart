import 'dart:convert';
import 'dart:io';

import 'package:flutterquiz/features/bid/bidException.dart';
import 'package:flutterquiz/utils/constants/api_body_parameter_labels.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';

import 'package:http/http.dart' as http;

class BidRemoteDataSource {
  Future<dynamic> getBids(
      {required String userId,
      required String languageId,
      required String type,
      required String limit,
      required String offset}) async {
    try {
      //body of post request
      final body = {
        accessValueKey: accessValue,
        userIdKey: userId,
        languageIdKey: languageId,
        typeKey: type, // 1 for today , 2 for completed
        limitKey: limit,
        offsetKey: offset,
      };

      if (languageId.isEmpty) {
        body.remove(languageIdKey);
      }
      if (limit.isEmpty) {
        body.remove(limitKey);
      }

      if (offset.isEmpty) {
        body.remove(offsetKey);
      }
      print("bid error msg $body");
      final response = await http.post(Uri.parse(getBidModuleUrl),
          body: body, headers: await ApiUtils.getHeaders());

      final responseJson = jsonDecode(response.body);

      print(responseJson);

      if (responseJson['error']) {
        throw BidException(
          errorMessageCode: responseJson['message'].toString() == "102"
              ? type == "1"
                  ? noBidForTodayCode
                  : haveNotCompletedBidCode
              : responseJson['message'],
        );
      }

      return responseJson;
    } on SocketException catch (_) {
      throw BidException(errorMessageCode: noInternetCode);
    } on BidException catch (e) {
      throw BidException(errorMessageCode: e.toString());
    } catch (e) {
      throw BidException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  Future<List<dynamic>> getQuestionForBid(
      {required String bidModuleId}) async {
    try {
      //body of post request
      final body = {
        accessValueKey: accessValue,
        bidModuleIdKey: bidModuleId,
      };

      final response = await http.post(Uri.parse(getBidModuleQuestionsUrl),
          body: body, headers: await ApiUtils.getHeaders());
      final responseJson = jsonDecode(response.body);

      if (responseJson['error']) {
        throw BidException(errorMessageCode: responseJson['message']);
      }
      return responseJson['data'];
    } on SocketException catch (_) {
      throw BidException(errorMessageCode: noInternetCode);
    } on BidException catch (e) {
      throw BidException(errorMessageCode: e.toString());
    } catch (e) {
      throw BidException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  Future<dynamic> updateBidStatusToInBid({
    required String bidModuleId,
    required String userId,
  }) async {
    try {
      //body of post request
      final body = {
        accessValueKey: accessValue,
        bidModuleIdKey: bidModuleId,
        userIdKey: userId,
      };

      final response = await http.post(Uri.parse(setBidModuleResultUrl),
          body: body, headers: await ApiUtils.getHeaders());
      final responseJson = jsonDecode(response.body);

      if (responseJson['error']) {
        print(responseJson);
        throw BidException(
            errorMessageCode: responseJson['message'].toString() == "103"
                ? alreadyInBidCode
                : responseJson['message']);
      }
      return responseJson['data'];
    } on SocketException catch (_) {
      throw BidException(errorMessageCode: noInternetCode);
    } on BidException catch (e) {
      throw BidException(errorMessageCode: e.toString());
    } catch (e) {
      throw BidException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  Future<dynamic> submitBidResult({
    required String bidModuleId,
    required String userId,
    required String totalDuration,
    required List<Map<String, dynamic>> statistics,
    required String obtainedMarks,
    required bool rulesViolated,
    required List<String> capturedQuestionIds,
  }) async {
    try {
      //body of post request
      final body = {
        accessValueKey: accessValue,
        bidModuleIdKey: bidModuleId,
        userIdKey: userId,
        statisticsKey: json.encode(statistics),
        totalDurationKey: totalDuration,
        obtainedMarksKey: obtainedMarks,
        rulesViolatedKey: rulesViolated ? "1" : "0",
        capturedQuestionIdsKey: json.encode(capturedQuestionIds),
      };

      print(body);

      final response = await http.post(
        Uri.parse(setBidModuleResultUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body);

      if (responseJson['error']) {
        throw BidException(errorMessageCode: responseJson['message']);
      }

      return responseJson['message'];
    } on SocketException catch (_) {
      throw BidException(errorMessageCode: noInternetCode);
    } on BidException catch (e) {
      throw BidException(errorMessageCode: e.toString());
    } catch (e) {
      throw BidException(errorMessageCode: defaultErrorMessageCode);
    }
  }
}
