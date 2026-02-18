package com.friends.backend.upload;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/uploads")
public class UploadController {
  private final Path uploadDir = Paths.get(System.getProperty("java.io.tmpdir"), "friends-uploads");

  @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public ResponseEntity<Map<String, String>> upload(@RequestPart("file") MultipartFile file)
      throws IOException {
    Files.createDirectories(uploadDir);

    final String original = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
    final String ext = original.contains(".") ? original.substring(original.lastIndexOf('.')) : "";
    final String name = UUID.randomUUID().toString().replace("-", "") + ext;

    final Path target = uploadDir.resolve(name);
    Files.write(target, file.getBytes());

    final String url = "/uploads/" + name;
    return ResponseEntity.ok(Map.of("url", url));
  }
}
