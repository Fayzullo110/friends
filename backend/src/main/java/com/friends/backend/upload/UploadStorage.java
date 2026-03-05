package com.friends.backend.upload;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class UploadStorage {
  private final Path uploadDir;

  public UploadStorage(@Value("${app.upload.dir:}") String configuredDir) {
    if (configuredDir != null && !configuredDir.trim().isEmpty()) {
      this.uploadDir = Paths.get(configuredDir.trim());
    } else {
      this.uploadDir = Paths.get(System.getProperty("java.io.tmpdir"), "friends-uploads");
    }
  }

  public Path getUploadDir() throws IOException {
    Files.createDirectories(uploadDir);
    return uploadDir;
  }
}
