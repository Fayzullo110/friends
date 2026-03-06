package com.friends.backend.report;

import com.friends.backend.chat.ChatMessageRepository;
import com.friends.backend.comment.CommentRepository;
import com.friends.backend.common.PagedResponse;
import com.friends.backend.post.PostRepository;
import com.friends.backend.report.dto.CreateReportRequest;
import com.friends.backend.report.dto.ReportResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.story.StoryRepository;
import com.friends.backend.story.comment.StoryCommentRepository;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reports")
public class ReportController {
  private final ReportRepository reportRepository;

  private final UserRepository userRepository;
  private final PostRepository postRepository;
  private final CommentRepository commentRepository;
  private final StoryRepository storyRepository;
  private final StoryCommentRepository storyCommentRepository;
  private final ChatMessageRepository chatMessageRepository;

  private static final Set<String> ALLOWED_TYPES = Set.of(
      "user",
      "post",
      "comment",
      "story",
      "story_comment",
      "message"
  );

  private static final Duration DEDUPE_WINDOW = Duration.ofMinutes(5);

  public ReportController(
      ReportRepository reportRepository,
      UserRepository userRepository,
      PostRepository postRepository,
      CommentRepository commentRepository,
      StoryRepository storyRepository,
      StoryCommentRepository storyCommentRepository,
      ChatMessageRepository chatMessageRepository) {
    this.reportRepository = reportRepository;
    this.userRepository = userRepository;
    this.postRepository = postRepository;
    this.commentRepository = commentRepository;
    this.storyRepository = storyRepository;
    this.storyCommentRepository = storyCommentRepository;
    this.chatMessageRepository = chatMessageRepository;
  }

  @GetMapping
  public List<ReportResponse> myReports(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      @RequestParam(name = "targetType", required = false) String targetType,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final String type = targetType == null ? null : targetType.trim().toLowerCase();
    final List<ReportEntity> rows;
    if (type == null || type.isEmpty()) {
      rows = reportRepository.findByReporterIdOrderByCreatedAtDesc(
          principal.getUserId(),
          PageRequest.of(safePage, safeLimit));
    } else {
      if (!ALLOWED_TYPES.contains(type)) {
        throw new IllegalArgumentException("Unsupported targetType");
      }
      rows = reportRepository.findByReporterIdAndTargetTypeOrderByCreatedAtDesc(
          principal.getUserId(),
          type,
          PageRequest.of(safePage, safeLimit));
    }

    return rows.stream().map(this::toResponse).toList();
  }

  @GetMapping("/paged")
  public PagedResponse<ReportResponse> myReportsPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      @RequestParam(name = "targetType", required = false) String targetType,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final String type = targetType == null ? null : targetType.trim().toLowerCase();
    final List<ReportEntity> rows;
    if (type == null || type.isEmpty()) {
      rows = reportRepository.findByReporterIdOrderByCreatedAtDesc(
          principal.getUserId(),
          PageRequest.of(safePage, safeLimit + 1));
    } else {
      if (!ALLOWED_TYPES.contains(type)) {
        throw new IllegalArgumentException("Unsupported targetType");
      }
      rows = reportRepository.findByReporterIdAndTargetTypeOrderByCreatedAtDesc(
          principal.getUserId(),
          type,
          PageRequest.of(safePage, safeLimit + 1));
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
    if (!ALLOWED_TYPES.contains(type)) {
      throw new IllegalArgumentException("Unsupported targetType");
    }
    if (targetId == null || targetId <= 0) {
      throw new IllegalArgumentException("targetId is required");
    }
    if (reason.isEmpty()) {
      throw new IllegalArgumentException("reason is required");
    }

    final boolean exists = switch (type) {
      case "user" -> userRepository.existsById(targetId);
      case "post" -> postRepository.existsById(targetId);
      case "comment" -> commentRepository.existsById(targetId);
      case "story" -> storyRepository.existsById(targetId);
      case "story_comment" -> storyCommentRepository.existsById(targetId);
      case "message" -> chatMessageRepository.existsById(targetId);
      default -> false;
    };
    if (!exists) {
      throw new IllegalArgumentException("Target not found");
    }

    reportRepository
        .findTop1ByReporterIdAndTargetTypeAndTargetIdOrderByCreatedAtDesc(
            principal.getUserId(),
            type,
            targetId)
        .ifPresent(prev -> {
          final Instant createdAt = prev.getCreatedAt();
          if (createdAt != null) {
            final Duration since = Duration.between(createdAt, Instant.now());
            if (!since.isNegative() && since.compareTo(DEDUPE_WINDOW) < 0) {
              throw new DuplicateReportException();
            }
          }
        });

    final ReportEntity r = new ReportEntity();
    r.setReporterId(principal.getUserId());
    r.setTargetType(type);
    r.setTargetId(targetId);
    r.setReason(reason);
    r.setDetails(details == null || details.isEmpty() ? null : details);
    reportRepository.save(r);

    return ResponseEntity.noContent().build();
  }

  private static class DuplicateReportException extends RuntimeException {}

  @ExceptionHandler(DuplicateReportException.class)
  public ResponseEntity<Void> handleDuplicateReport() {
    return ResponseEntity.noContent().build();
  }
}
