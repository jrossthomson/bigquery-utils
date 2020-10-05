#standardSQL
CREATE OR REPLACE PROCEDURE `bqutil.procedure.linear_regression`(subquery STRING, x_col STRING, y_col STRING)
OPTIONS (strict_mode=false)
BEGIN

IF REGEXP_CONTAINS(subquery, r'(?im)(select\s)') THEN
    -- If we see a SELECT clause, we have a subquery and need to wrap in parens
    SET subquery = CONCAT('(', CONCAT(subquery, ')t'));
ELSEIF REGEXP_CONTAINS(subquery, r'\W') AND NOT REGEXP_CONTAINS(subquery, r'^\s*`.*`\s*$') THEN
    -- Otherwise, make sure to wrap the table identifier in backticks if needed
    SET subquery = CONCAT('`', CONCAT(subquery, '`'));
END IF;

SELECT subquery;

EXECUTE IMMEDIATE format("""
    SELECT
  ((Sy * Sxx) - (Sx * Sxy)) / ((N * (Sxx)) - (Sx * Sx)) AS a,
    ((N * Sxy) - (Sx * Sy))  / ((N * Sxx) - (Sx * Sx)) AS b,
    ((N * Sxy) - (Sx * Sy)) / SQRT( (((N * Sxx) - (Sx * Sx)) * ((N * Syy - (Sy * Sy))))) AS r

    FROM
      (
      SELECT SUM(x) AS Sx, SUM(y) AS Sy,
        SUM(x * x) AS Sxx,
        SUM(x * y) AS Sxy,
        SUM(y * y) AS Syy,
        COUNT(*) AS N
        FROM (
            SELECT `%s` AS x, `%s` AS y FROM %s
        )
    )t


""",

x_col, y_col, subquery);
END;