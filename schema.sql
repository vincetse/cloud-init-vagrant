DROP TABLE IF EXISTS github_events;
CREATE TABLE github_events
(
    event_id bigint,
    event_type text,
    event_public boolean,
    repo_id bigint,
    payload jsonb,
    repo jsonb,
    user_id bigint,
    org jsonb,
    created_at timestamp
);

DROP TABLE IF EXISTS github_users;
CREATE TABLE github_users
(
    user_id bigint,
    url text,
    login text,
    avatar_url text,
    gravatar_id text,
    display_login text
);

CREATE INDEX event_type_index ON github_events (event_type);
CREATE INDEX payload_index ON github_events USING GIN (payload jsonb_path_ops);

SELECT create_distributed_table('github_events', 'user_id');
SELECT create_distributed_table('github_users', 'user_id');

\copy github_events FROM PROGRAM 'zcat events.csv.gz' CSV;
\copy github_users FROM PROGRAM 'zcat users.csv.gz' CSV;

SELECT count(*) FROM github_events;

SELECT date_trunc('hour', created_at) AS hour,
       sum((payload->>'distinct_size')::int) AS num_commits
    FROM   github_events
    WHERE  event_type = 'PushEvent'
    GROUP BY hour
    ORDER BY hour;

SELECT login, count(*)
FROM github_events ge
JOIN github_users gu
ON ge.user_id = gu.user_id
WHERE event_type = 'CreateEvent' AND
payload @> '{"ref_type": "repository"}'
GROUP BY login
ORDER BY count(*) DESC;


SELECT nodename, count(*)
FROM pg_dist_shard_placement
GROUP BY nodename;
