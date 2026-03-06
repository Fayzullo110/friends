package com.friends.backend.report;

import com.friends.backend.common.PagedResponse;
import com.friends.backend.report.dto.ReportResponse;
import com.friends.backend.security.UserPrincipal;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/reports")
public class AdminReportController {
  private final ReportRepository reportRepository;
  private final Set<Long> adminUserIds;

  public AdminReportController(
      ReportRepository reportRepository,
      @Value("${app.admin.userIds:}") String adminUserIdsCsv) {
    this.reportRepository = reportRepository;
    final String[] parts = (adminUserIdsCsv == null || adminUserIdsCsv.trim().isEmpty())
        ? new String[0]
        : adminUserIdsCsv.split(",");
    this.adminUserIds = Arrays.stream(parts)
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .map(Long::parseLong)
        .collect(Collectors.toSet());
  }

  private void requireAdmin(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (!adminUserIds.contains(principal.getUserId())) {
      throw new IllegalArgumentException("Forbidden");
    }
  }

  @GetMapping
  public List<ReportResponse> list(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      @RequestParam(name = "targetType", required = false) String targetType,
      Authentication authentication) {
    requireAdmin(authentication);

    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final String type = targetType == null ? null : targetType.trim().toLowerCase();
    final List<ReportEntity> rows;
    if (type == null || type.isEmpty()) {
      rows = reportRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit));
    } else {
      rows = reportRepository.findByTargetTypeOrderByCreatedAtDesc(type, PageRequest.of(safePage, safeLimit));
    }

    return rows.stream().map(this::toResponse).toList();
  }

  @GetMapping("/paged")
  public PagedResponse<ReportResponse> listPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      @RequestParam(name = "targetType", required = false) String targetType,
      Authentication authentication) {
    requireAdmin(authentication);

    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final String type = targetType == null ? null : targetType.trim().toLowerCase();
    final List<ReportEntity> rows;
    if (type == null || type.isEmpty()) {
      rows = reportRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit + 1));
    } else {
      rows = reportRepository.findByTargetTypeOrderByCreatedAtDesc(type, PageRequest.of(safePage, safeLimit + 1));
    }

    final boolean hasMore = rows.size() > safeLimit;
    final List<ReportEntity> pageRows = hasMore ? rows.subList(0, safeLimit) : rows;
    final List<ReportResponse> items = pageRows.stream().map(this::toResponse).toList();
    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  private ReportResponse toResponse(ReportEntity r) {
    return new ReportResponse(
        r.getId(),
        r.getReporterId(),
        r.getTargetType(),
        r.getTargetId(),
        r.getReason(),
        r.getDetails(),
        r.getCreatedAt() == null ? null : r.getCreatedAt().toString());
  }
}
