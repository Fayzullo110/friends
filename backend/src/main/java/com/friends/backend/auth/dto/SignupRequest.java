package com.friends.backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class SignupRequest {
  @NotBlank
  @Email
  public String email;

  @NotBlank
  @Size(min = 3, max = 50)
  public String username;

  @NotBlank
  @Size(min = 6, max = 100)
  public String password;

  public String firstName;
  public String lastName;
  public Integer age;
}
