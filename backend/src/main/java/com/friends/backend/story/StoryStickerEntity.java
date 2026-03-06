package com.friends.backend.story;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_stickers")
public class StoryStickerEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "story_id", nullable = false)
  private Long storyId;

  @Column(nullable = false)
  private String type;

  @Column(name = "pos_x", nullable = false)
  private double posX;

  @Column(name = "pos_y", nullable = false)
  private double posY;

  @Column(name = "data_json", columnDefinition = "TEXT")
  private String dataJson;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public Long getId() { return id; }
  public Long getStoryId() { return storyId; }
  public void setStoryId(Long storyId) { this.storyId = storyId; }
  public String getType() { return type; }
  public void setType(String type) { this.type = type; }
  public double getPosX() { return posX; }
  public void setPosX(double posX) { this.posX = posX; }
  public double getPosY() { return posY; }
  public void setPosY(double posY) { this.posY = posY; }
  public String getDataJson() { return dataJson; }
  public void setDataJson(String dataJson) { this.dataJson = dataJson; }
  public Instant getCreatedAt() { return createdAt; }
}
