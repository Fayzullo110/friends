package com.friends.backend.story.stickers;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_sticker_emoji_slider_values")
public class StoryStickerEmojiSliderValueEntity {
  @EmbeddedId
  private StoryStickerEmojiSliderValueId id;

  @Column(name = "value_int", nullable = false)
  private int valueInt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public StoryStickerEmojiSliderValueEntity() {}

  public StoryStickerEmojiSliderValueEntity(StoryStickerEmojiSliderValueId id, int valueInt) {
    this.id = id;
    this.valueInt = valueInt;
  }

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public StoryStickerEmojiSliderValueId getId() { return id; }
  public int getValueInt() { return valueInt; }
  public void setValueInt(int valueInt) { this.valueInt = valueInt; }
  public Instant getCreatedAt() { return createdAt; }
}
