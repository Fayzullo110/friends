package com.friends.backend.story;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryStickerRepository extends JpaRepository<StoryStickerEntity, Long> {
  List<StoryStickerEntity> findByStoryIdOrderByIdAsc(long storyId);
  List<StoryStickerEntity> findByStoryIdInOrderByStoryIdAscIdAsc(List<Long> storyIds);
}
