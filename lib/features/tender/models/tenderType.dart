import 'package:fluttertender/utils/constants/string_labels.dart';

enum TenderTypes {
  dailyTender,
  contest,
  groupPlay,
  practiceSection,
  battle,
  funAndLearn,
  trueAndFalse,
  selfChallenge,
  guessTheWord,
  tenderZone,
  bookmarkTender,
  mathMania,
  audioQuestions,
  bid,
}

TenderTypes getTenderTypeEnumFromTitle(String? title) {
  if (title == "contest") {
    return TenderTypes.contest;
  } else if (title == "dailyTender") {
    return TenderTypes.dailyTender;
  } else if (title == "groupPlay") {
    return TenderTypes.groupPlay;
  } else if (title == "battleTender") {
    return TenderTypes.battle;
  } else if (title == "funAndLearn") {
    return TenderTypes.funAndLearn;
  } else if (title == "guessTheWord") {
    return TenderTypes.guessTheWord;
  } else if (title == "trueAndFalse") {
    return TenderTypes.trueAndFalse;
  } else if (title == "selfChallenge") {
    return TenderTypes.selfChallenge;
  } else if (title == "tenderZone") {
    return TenderTypes.tenderZone;
  } else if (title == mathManiaKey) {
    return TenderTypes.mathMania;
  } else if (title == audioQuestionsKey) {
    return TenderTypes.audioQuestions;
  } else if (title == bidKey) {
    return TenderTypes.bid;
  }

  return TenderTypes.practiceSection;
}

class TenderType {
  late final String title, image;
  late bool active;
  late TenderTypes tenderTypeEnum;
  late String description;

  TenderType({
    required this.title,
    required this.image,
    required this.active,
    required this.description,
  }) {
    image = "assets/images/$image";
    tenderTypeEnum = getTenderTypeEnumFromTitle(title);
  }

/*
  static TenderType fromJson(Map<String, dynamic> parsedJson) {
    return new TenderType(
      title: parsedJson["TITLE"],
      image: parsedJson["IMAGE"],
      active: true,
    );
  }
  */
}
