-- Script to assign random like counts to all existing posts
-- Range: 10 to 500 (inclusive)

UPDATE posts
SET like_count = floor(random() * 491 + 10)::int;
