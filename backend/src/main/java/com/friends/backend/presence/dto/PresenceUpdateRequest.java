package com.friends.backend.presence.dto;

import jakarta.validation.constraints.NotNull;

public class PresenceUpdateRequest {
  @NotNull
  public Boolean online;
}
