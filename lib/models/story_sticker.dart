class StorySticker {
  final String id;
  final String type;
  final double posX;
  final double posY;
  final String? dataJson;

  final Map<int, int>? pollCounts;
  final int? myPollChoice;

  final int? questionAnswerCount;
  final String? myQuestionAnswer;

  final double? emojiSliderAvg;
  final int? emojiSliderCount;
  final int? myEmojiSliderValue;

  StorySticker({
    required this.id,
    required this.type,
    required this.posX,
    required this.posY,
    this.dataJson,
    this.pollCounts,
    this.myPollChoice,
    this.questionAnswerCount,
    this.myQuestionAnswer,
    this.emojiSliderAvg,
    this.emojiSliderCount,
    this.myEmojiSliderValue,
  });

  static Map<int, int>? _parseCounts(dynamic raw) {
    if (raw is! Map) return null;
    final out = <int, int>{};
    raw.forEach((k, v) {
      final key = int.tryParse(k.toString());
      final value = (v as num?)?.toInt();
      if (key == null || value == null) return;
      out[key] = value;
    });
    return out;
  }

  factory StorySticker.fromJson(Map<String, dynamic> data) {
    return StorySticker(
      id: data['id'].toString(),
      type: data['type'] as String? ?? '',
      posX: (data['posX'] as num?)?.toDouble() ?? 0.5,
      posY: (data['posY'] as num?)?.toDouble() ?? 0.5,
      dataJson: data['dataJson'] as String?,
      pollCounts: _parseCounts(data['pollCounts']),
      myPollChoice: (data['myPollChoice'] as num?)?.toInt(),
      questionAnswerCount: (data['questionAnswerCount'] as num?)?.toInt(),
      myQuestionAnswer: data['myQuestionAnswer'] as String?,
      emojiSliderAvg: (data['emojiSliderAvg'] as num?)?.toDouble(),
      emojiSliderCount: (data['emojiSliderCount'] as num?)?.toInt(),
      myEmojiSliderValue: (data['myEmojiSliderValue'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'posX': posX,
      'posY': posY,
      'dataJson': dataJson,
      'pollCounts': pollCounts,
      'myPollChoice': myPollChoice,
      'questionAnswerCount': questionAnswerCount,
      'myQuestionAnswer': myQuestionAnswer,
      'emojiSliderAvg': emojiSliderAvg,
      'emojiSliderCount': emojiSliderCount,
      'myEmojiSliderValue': myEmojiSliderValue,
    };
  }
}
