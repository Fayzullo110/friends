package com.friends.backend.story.stickers;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StoryStickerPollVoteRepository extends JpaRepository<StoryStickerPollVoteEntity, StoryStickerPollVoteId> {
  @Query(value = "select option_index, count(*) from story_sticker_poll_votes where sticker_id = :stickerId group by option_index", nativeQuery = true)
  List<Object[]> countByOption(@Param("stickerId") long stickerId);

  @Query(value = "select sticker_id, user_id, option_index from story_sticker_poll_votes where sticker_id in (:stickerIds)", nativeQuery = true)
  List<Object[]> findVotesForStickers(@Param("stickerIds") List<Long> stickerIds);
}
