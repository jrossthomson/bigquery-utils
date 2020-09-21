#standardSQL
CREATE OR REPLACE PROCEDURE `bq-stats-test.TestData.t_test`(subquery_1 STRING, x_1 STRING, subquery_2 STRING, x_2 STRING)
OPTIONS (strict_mode=false)
BEGIN

-- TODO: maybe this subquery parser should be its own procedure?

IF REGEXP_CONTAINS(subquery_1, r'(?im)(select\s)') THEN
    -- If we see a SELECT clause, we have a subquery and need to wrap in parens
    SET subquery_1 = CONCAT('(', CONCAT(subquery_1, ')t'));
ELSEIF REGEXP_CONTAINS(subquery_1, r'\W') AND NOT REGEXP_CONTAINS(subquery_1, r'^\s*`.*`\s*$') THEN
    -- Otherwise, make sure to wrap the table identifier in backticks if needed
    SET subquery_1 = CONCAT('`', CONCAT(subquery_1, '`'));
END IF;

IF REGEXP_CONTAINS(subquery_2, r'(?im)(select\s)') THEN
    -- If we see a SELECT clause, we have a subquery and need to wrap in parens
    SET subquery_2 = CONCAT('(', CONCAT(subquery_2, ')t'));
ELSEIF REGEXP_CONTAINS(subquery_2, r'\W') AND NOT REGEXP_CONTAINS(subquery_2, r'^\s*`.*`\s*$') THEN
    -- Otherwise, make sure to wrap the table identifier in backticks if needed
    SET subquery_2 = CONCAT('`', CONCAT(subquery_2, '`'));
END IF;

EXECUTE IMMEDIATE format("""
WITH
t1 AS (SELECT `%s` AS x FROM %s),
t2 AS (SELECT `%s` AS x FROM %s),
pop1 AS (
    SELECT STDDEV(x) st1, Avg(x) x1, Count(x) n1
  FROM t1
),
pop2 AS (
	SELECT STDDEV(x) st2, Avg(x) x2, Count(x) n2
  FROM t2
)
SELECT
	(x1 - x2) / Sqrt((st1 * st1 / N1) + (st2 * st2/ N2)) AS t,
	n1+n2-2 AS df
FROM pop1 CROSS JOIN pop2
""",
x_1, subquery_1, x_2, subquery_2
);

END;