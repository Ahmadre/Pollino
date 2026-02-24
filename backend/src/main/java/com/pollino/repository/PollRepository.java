package com.pollino.repository;

import com.pollino.model.Poll;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface PollRepository extends MongoRepository<Poll, String> {

    /**
     * Find active, non-anonymous polls that are either not expired or not set to auto-delete.
     * Used for the public home page listing.
     */
    @Query("{ 'active': true, 'anonymous': false, " +
            "$or: [ " +
            "  { 'expiresAt': null }, " +
            "  { 'expiresAt': { $gt: ?0 } }, " +
            "  { $and: [ { 'expiresAt': { $lte: ?0 } }, { 'autoDeleteAfterExpiry': false } ] } " +
            "] }")
    Page<Poll> findVisiblePolls(Instant now, Pageable pageable);

    /**
     * Count visible polls for pagination.
     */
    @Query(value = "{ 'active': true, 'anonymous': false, " +
            "$or: [ " +
            "  { 'expiresAt': null }, " +
            "  { 'expiresAt': { $gt: ?0 } }, " +
            "  { $and: [ { 'expiresAt': { $lte: ?0 } }, { 'autoDeleteAfterExpiry': false } ] } " +
            "] }", count = true)
    long countVisiblePolls(Instant now);

    /**
     * Find expired polls that should be auto-deleted.
     */
    @Query("{ 'expiresAt': { $ne: null, $lt: ?0 }, 'autoDeleteAfterExpiry': true }")
    List<Poll> findExpiredAutoDeletePolls(Instant now);
}
