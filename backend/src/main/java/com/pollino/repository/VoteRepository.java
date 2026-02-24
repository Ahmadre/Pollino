package com.pollino.repository;

import com.pollino.model.Vote;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VoteRepository extends MongoRepository<Vote, String> {

    List<Vote> findByPollId(String pollId);

    List<Vote> findByPollIdAndVoterName(String pollId, String voterName);

    List<Vote> findByPollIdAndOptionIdAndVoterName(String pollId, String optionId, String voterName);

    boolean existsByPollIdAndVoterName(String pollId, String voterName);

    boolean existsByPollIdAndOptionIdAndVoterName(String pollId, String optionId, String voterName);

    List<Vote> findByPollIdAndOptionId(String pollId, String optionId);

    void deleteByPollId(String pollId);

    long countByPollId(String pollId);
}
