package com.pollino.repository;

import com.pollino.model.AiSummary;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AiSummaryRepository extends MongoRepository<AiSummary, String> {

    Optional<AiSummary> findByPollId(String pollId);

    void deleteByPollId(String pollId);
}
