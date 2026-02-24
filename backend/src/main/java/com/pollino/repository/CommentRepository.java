package com.pollino.repository;

import com.pollino.model.Comment;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends MongoRepository<Comment, String> {

    List<Comment> findByPollId(String pollId, Sort sort);

    long countByPollId(String pollId);

    void deleteByPollId(String pollId);
}
