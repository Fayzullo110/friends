package com.friends.backend.report.dto;

public class CreateReportRequest {
  public String targetType; // user | post | comment | story | story_comment | message
  public Long targetId;
  public String reason;
  public String details;
}
