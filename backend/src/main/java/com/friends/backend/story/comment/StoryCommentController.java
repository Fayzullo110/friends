package com.friends.backend.story.comment;

import com.friends.backend.security.UserPrincipal;
import com.friends.backend.story.StoryEntity;
import com.friends.backend.story.StoryRepository;
import com.friends.backend.story.comment.dto.CreateStoryCommentRequest;
import com.friends.backend.story.comment.dto.StoryCommentResponse;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stories/{storyId}/comments")
public class StoryCommentController {
  private final StoryCommentRepository storyCommentRepository;
  private final StoryRepository storyRepository;
  private final UserRepository userRepository;

  public StoryCommentController(
      StoryCommentRepository storyCommentRepository,
      StoryRepository storyRepository,
      UserRepository userRepository) {
    this.storyCommentRepository = storyCommentRepository;
    this.storyRepository = storyRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<StoryCommentResponse> list(@PathVariable long storyId) {
    return storyCommentRepository.findByStoryIdOrderByCreatedAtDesc(storyId)
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping
  public StoryCommentResponse create(
      @PathVariable long storyId,
      @Valid @RequestBody CreateStoryCommentRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final StoryEntity story = storyRepository.findById(storyId)
        .orElseThrow(() -> new IllegalArgumentException("Story not found"));

    final StoryCommentEntity c = new StoryCommentEntity();
    c.setStoryId(storyId);
    c.setAuthorId(me.getId());
    c.setText(req.text.trim());

    return toResponse(storyCommentRepository.save(c));
  }

  @DeleteMapping("/{commentId}")
  public ResponseEntity<Void> delete(
      @PathVariable long storyId,
      @PathVariable long commentId,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final StoryCommentEntity comment = storyCommentRepository.findById(commentId)
        .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

    if (!comment.getStoryId().equals(storyId)) {
      throw new IllegalArgumentException("Comment not in story");
    }
    if (!comment.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the author can delete this comment");
    }

    storyCommentRepository.deleteById(commentId);
    return ResponseEntity.noContent().build();
  }

  private StoryCommentResponse toResponse(StoryCommentEntity c) {
    final String authorUsername = userRepository.findById(c.getAuthorId())
        .map(UserEntity::getUsername)
        .orElse("user");
    return new StoryCommentResponse(
        c.getId(),
        c.getStoryId(),
        c.getAuthorId(),
        authorUsername,
        c.getText(),
        c.getCreatedAt());
  }
}
