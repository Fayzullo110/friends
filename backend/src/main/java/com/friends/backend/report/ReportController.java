package com.friends.backend.report;

import com.friends.backend.report.dto.CreateReportRequest;
import com.friends.backend.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reports")
public class ReportController {
  private final ReportRepository reportRepository;

  public ReportController(ReportRepository reportRepository) {
    this.reportRepository = reportRepository;
  }

  @PostMapping
  public ResponseEntity<Void> create(
      @Valid @RequestBody CreateReportRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

    final String type = req == null || req.targetType == null ? "" : req.targetType.trim().toLowerCase();
    final Long targetId = req == null ? null : req.targetId;
    final String reason = req == null || req.reason == null ? "" : req.reason.trim().toLowerCase();
    final String details = req == null || req.details == null ? null : req.details.trim();

    if (type.isEmpty()) {
      throw new IllegalArgumentException("targetType is required");
    }
    if (targetId == null || targetId <= 0) {
      throw new IllegalArgumentException("targetId is required");
    }
    if (reason.isEmpty()) {
      throw new IllegalArgumentException("reason is required");
    }

    final ReportEntity r = new ReportEntity();
    r.setReporterId(principal.getUserId());
    r.setTargetType(type);
    r.setTargetId(targetId);
    r.setReason(reason);
    r.setDetails(details == null || details.isEmpty() ? null : details);
    reportRepository.save(r);

    return ResponseEntity.noContent().build();
  }
}
