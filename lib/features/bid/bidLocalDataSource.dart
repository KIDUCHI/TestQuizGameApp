import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:hive_flutter/adapters.dart';

class BidLocalDataSource {
  Future<void> addBidModuleId(String bidModuleId) async {
    await Hive.box(bidBox).put(bidModuleId, bidModuleId);
  }

  Future<void> removeBidModuleId(String bidModuleId) async {
    await Hive.box(bidBox).delete(bidModuleId);
  }

  List<String> getAllBidModuleIds() {
    List<String> bidModuleIds = [];
    //get all bid module ids
    for (var i = 0; i < Hive.box(bidBox).length; i++) {
      bidModuleIds.add(Hive.box(bidBox).getAt(i));
    }
    print("Total pending bids are : ${bidModuleIds.length}");
    return bidModuleIds;
  }
}
