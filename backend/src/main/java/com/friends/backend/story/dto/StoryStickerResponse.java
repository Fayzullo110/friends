package com.friends.backend.story.dto;

import java.util.List;
import java.util.Map;

public class StoryStickerResponse {
  public long id;
  public String type;
  public double posX;
  public double posY;
  public String dataJson;

  // Aggregated results (optional depending on sticker type)
  public Map<Integer, Long> pollCounts;
  public Integer myPollChoice;

  public Long questionAnswerCount;
  public String myQuestionAnswer;

  public Double emojiSliderAvg;
  public Long emojiSliderCount;
  public Integer myEmojiSliderValue;

  public StoryStickerResponse(
      long id,
      String type,
      double posX,
      double posY,
      String dataJson,
      Map<Integer, Long> pollCounts,
      Integer myPollChoice,
      Long questionAnswerCount,
      String myQuestionAnswer,
      Double emojiSliderAvg,
      Long emojiSliderCount,
      Integer myEmojiSliderValue) {
    this.id = id;
    this.type = type;
    this.posX = posX;
    this.posY = posY;
    this.dataJson = dataJson;
    this.pollCounts = pollCounts;
    this.myPollChoice = myPollChoice;
    this.questionAnswerCount = questionAnswerCount;
    this.myQuestionAnswer = myQuestionAnswer;
    this.emojiSliderAvg = emojiSliderAvg;
    this.emojiSliderCount = emojiSliderCount;
    this.myEmojiSliderValue = myEmojiSliderValue;
  }
}
