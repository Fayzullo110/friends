package com.friends.backend.report.dto;

public class ReportResponse {
  public long id;
  public long reporterId;
  public String targetType;
  public long targetId;
  public String reason;
  public String details;
  public String createdAt;

  public ReportResponse(
      long id,
      long reporterId,
      String targetType,
      long targetId,
      String reason,
      String details,
      String createdAt) {
    this.id = id;
    this.reporterId = reporterId;
    this.targetType = targetType;
    this.targetId = targetId;
    this.reason = reason;
    this.details = details;
    this.createdAt = createdAt;
  }
}
