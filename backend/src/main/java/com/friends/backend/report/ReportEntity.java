package com.friends.backend.report;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "reports")
public class ReportEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "reporter_id", nullable = false)
  private Long reporterId;

  @Column(name = "target_type", nullable = false)
  private String targetType;

  @Column(name = "target_id", nullable = false)
  private Long targetId;

  @Column(nullable = false)
  private String reason;

  @Column(columnDefinition = "TEXT")
  private String details;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public Long getId() { return id; }
  public Long getReporterId() { return reporterId; }
  public void setReporterId(Long reporterId) { this.reporterId = reporterId; }
  public String getTargetType() { return targetType; }
  public void setTargetType(String targetType) { this.targetType = targetType; }
  public Long getTargetId() { return targetId; }
  public void setTargetId(Long targetId) { this.targetId = targetId; }
  public String getReason() { return reason; }
  public void setReason(String reason) { this.reason = reason; }
  public String getDetails() { return details; }
  public void setDetails(String details) { this.details = details; }
  public Instant getCreatedAt() { return createdAt; }
}
