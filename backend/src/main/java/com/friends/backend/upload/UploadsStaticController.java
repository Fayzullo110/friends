package com.friends.backend.upload;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/uploads")
public class UploadsStaticController {
  private final Path uploadDir = Paths.get(System.getProperty("java.io.tmpdir"), "friends-uploads");

  @GetMapping("/{filename}")
  public ResponseEntity<Resource> get(@PathVariable String filename) throws MalformedURLException {
    final Path file = uploadDir.resolve(filename);
    final Resource resource = new UrlResource(file.toUri());
    if (!resource.exists()) {
      return ResponseEntity.notFound().build();
    }
    return ResponseEntity.ok(resource);
  }
}
