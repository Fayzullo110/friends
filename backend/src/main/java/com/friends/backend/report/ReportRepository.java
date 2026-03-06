package com.friends.backend.report;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

public interface ReportRepository extends JpaRepository<ReportEntity, Long> {
  List<ReportEntity> findByReporterIdOrderByCreatedAtDesc(long reporterId, Pageable pageable);

  List<ReportEntity> findByReporterIdAndTargetTypeOrderByCreatedAtDesc(
      long reporterId,
      String targetType,
      Pageable pageable);

  List<ReportEntity> findAllByOrderByCreatedAtDesc(Pageable pageable);

  List<ReportEntity> findByTargetTypeOrderByCreatedAtDesc(String targetType, Pageable pageable);

  Optional<ReportEntity> findTop1ByReporterIdAndTargetTypeAndTargetIdOrderByCreatedAtDesc(
      long reporterId,
      String targetType,
      long targetId);
}
