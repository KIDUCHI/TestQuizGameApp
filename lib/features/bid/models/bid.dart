class Bid {
  Bid({
    required this.id,
    required this.languageId,
    required this.title,
    required this.date,
    required this.bidKey,
    required this.duration,
    required this.status,
    required this.noOfQue,
    required this.answerAgain,
    required this.bidStatus, //(status: 1-Not in Bid, 2-In bid, 3-Completed)
  });

  late final String id;
  late final String languageId;
  late final String title;
  late final String date;
  late final String bidKey;
  late final String duration;
  late final String status;
  late final String noOfQue;
  late final String bidStatus;
  late final String totalMarks;
  late final String answerAgain;

  Bid.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    languageId = json['language_id'];
    title = json['title'];
    date = json['date'];
    bidKey = json['bid_key'];
    duration = json['duration'];
    status = json['status'];
    noOfQue = json['no_of_que'];
    bidStatus = json['bid_status'];
    totalMarks = json['total_marks'];
    answerAgain = json['answer_again'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'language_id': languageId,
        'title': title,
        'date': date,
        'bid_key': bidKey,
        'duration': duration,
        'status': status,
        'no_of_que': noOfQue,
        'bid_status': bidStatus,
        'total_marks': totalMarks,
        'answer_again': answerAgain,
      };
}
