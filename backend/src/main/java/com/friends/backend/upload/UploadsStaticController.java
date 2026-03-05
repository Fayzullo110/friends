package com.friends.backend.upload;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Path;
import org.springframework.http.MediaType;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/uploads")
public class UploadsStaticController {
  private final UploadStorage uploadStorage;

  public UploadsStaticController(UploadStorage uploadStorage) {
    this.uploadStorage = uploadStorage;
  }

  @GetMapping("/{filename:.+}")
  public ResponseEntity<Resource> get(@PathVariable String filename)
      throws MalformedURLException, IOException {
    final Path uploadDir = uploadStorage.getUploadDir();
    final Path file = uploadDir.resolve(filename).normalize();
    if (!file.startsWith(uploadDir)) {
      return ResponseEntity.notFound().build();
    }
    final Resource resource = new UrlResource(file.toUri());
    if (!resource.exists()) {
      return ResponseEntity.notFound().build();
    }

    String contentType = null;
    try {
      contentType = java.nio.file.Files.probeContentType(file);
    } catch (Exception ignored) {
      contentType = null;
    }

    if (contentType == null || contentType.trim().isEmpty()) {
      return ResponseEntity.ok(resource);
    }
    return ResponseEntity.ok().contentType(MediaType.parseMediaType(contentType)).body(resource);
  }
}
