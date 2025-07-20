import 'dart:async';

import 'package:flutter/material.dart';

class BidTimerContainer extends StatefulWidget {
  final int bidDurationInMinutes;
  final Function navigateToResultScreen;

  const BidTimerContainer({
    super.key,
    required this.bidDurationInMinutes,
    required this.navigateToResultScreen,
  });

  @override
  State<BidTimerContainer> createState() => BidTimerContainerState();
}

class BidTimerContainerState extends State<BidTimerContainer> {
  late int minutesLeft = widget.bidDurationInMinutes - 1;
  late int secondsLeft = 59;

  void startTimer() {
    bidTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (minutesLeft == 0 && secondsLeft == 0) {
        timer.cancel();
        widget.navigateToResultScreen();
      } else {
        if (secondsLeft == 0) {
          secondsLeft = 59;
          minutesLeft--;
        } else {
          secondsLeft--;
        }
        setState(() {});
      }
    });
  }

  Timer? bidTimer;

  int getCompletedBidDuration() {
    print("Bid completed in ${(widget.bidDurationInMinutes - minutesLeft)}");
    return (widget.bidDurationInMinutes - minutesLeft);
  }

  void cancelTimer() {
    print("Cancel timer");
    bidTimer?.cancel();
  }

  @override
  void dispose() {
    cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String hours = (minutesLeft ~/ 60).toString().length == 1
        ? "0${(minutesLeft ~/ 60)}"
        : (minutesLeft ~/ 60).toString();

    String minutes = (minutesLeft % 60).toString().length == 1
        ? "0${(minutesLeft % 60)}"
        : (minutesLeft % 60).toString();
    hours = hours == "00" ? "" : hours;

    String seconds = secondsLeft < 10 ? "0$secondsLeft" : "$secondsLeft";
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.4),
          width: 4,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        hours.isEmpty ? "$minutes:$seconds" : "$hours:$minutes:$seconds",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
