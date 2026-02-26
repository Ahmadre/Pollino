package com.pollino.repository;

import com.pollino.model.FeedbackResponse;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FeedbackResponseRepository extends MongoRepository<FeedbackResponse, String> {

    List<FeedbackResponse> findByPollId(String pollId);

    long countByPollId(String pollId);

    boolean existsByPollIdAndRespondentName(String pollId, String respondentName);

    void deleteByPollId(String pollId);
}
