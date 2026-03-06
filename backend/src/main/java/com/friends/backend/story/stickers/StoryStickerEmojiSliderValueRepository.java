package com.friends.backend.story.stickers;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StoryStickerEmojiSliderValueRepository extends JpaRepository<StoryStickerEmojiSliderValueEntity, StoryStickerEmojiSliderValueId> {
  @Query(value = "select sticker_id, avg(value_int) as avg_value, count(*) as cnt from story_sticker_emoji_slider_values where sticker_id in (:stickerIds) group by sticker_id", nativeQuery = true)
  List<Object[]> avgForStickers(@Param("stickerIds") List<Long> stickerIds);

  @Query(value = "select sticker_id, user_id, value_int from story_sticker_emoji_slider_values where sticker_id in (:stickerIds)", nativeQuery = true)
  List<Object[]> findValuesForStickers(@Param("stickerIds") List<Long> stickerIds);
}
