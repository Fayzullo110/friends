package com.friends.backend.story.stickers;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StoryStickerQuestionAnswerRepository extends JpaRepository<StoryStickerQuestionAnswerEntity, StoryStickerQuestionAnswerId> {
  @Query(value = "select sticker_id, count(*) from story_sticker_question_answers where sticker_id in (:stickerIds) group by sticker_id", nativeQuery = true)
  List<Object[]> countForStickers(@Param("stickerIds") List<Long> stickerIds);

  @Query(value = "select sticker_id, user_id, answer_text from story_sticker_question_answers where sticker_id in (:stickerIds)", nativeQuery = true)
  List<Object[]> findAnswersForStickers(@Param("stickerIds") List<Long> stickerIds);
}
