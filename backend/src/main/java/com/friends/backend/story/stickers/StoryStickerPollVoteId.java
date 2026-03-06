package com.friends.backend.story.stickers;

import jakarta.persistence.*;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class StoryStickerPollVoteId implements Serializable {
  @Column(name = "sticker_id")
  private Long stickerId;

  @Column(name = "user_id")
  private Long userId;

  public StoryStickerPollVoteId() {}

  public StoryStickerPollVoteId(Long stickerId, Long userId) {
    this.stickerId = stickerId;
    this.userId = userId;
  }

  public Long getStickerId() { return stickerId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof StoryStickerPollVoteId that)) return false;
    return Objects.equals(stickerId, that.stickerId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(stickerId, userId);
  }
}
