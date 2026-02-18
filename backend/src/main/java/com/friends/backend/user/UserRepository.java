package com.friends.backend.user;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<UserEntity, Long> {
  boolean existsByEmail(String email);

  boolean existsByUsername(String username);

  Optional<UserEntity> findByEmail(String email);

  Optional<UserEntity> findByUsername(String username);

  @Query("select u from UserEntity u where lower(u.username) like lower(concat('%', :q, '%')) or lower(u.email) like lower(concat('%', :q, '%'))")
  List<UserEntity> search(@Param("q") String q);

  @Query("select u from UserEntity u where u.id <> :excludeId order by u.id desc")
  List<UserEntity> listRecent(@Param("excludeId") long excludeId);
}
