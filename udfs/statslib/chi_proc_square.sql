#standardSQL
CREATE OR REPLACE PROCEDURE `bq-stats-test.TestData.chi_square`(subquery STRING, category_1 STRING, category_2 STRING)
OPTIONS (strict_mode=false)
BEGIN
    DECLARE total_count INT64;

    IF REGEXP_CONTAINS(subquery, r'(?im)(select\s)') THEN
        -- If we see a SELECT clause, we have a subquery and need to wrap in parens
        SET subquery = CONCAT('(', CONCAT(subquery, ')t'));
    ELSEIF REGEXP_CONTAINS(subquery, r'\W') AND NOT REGEXP_CONTAINS(subquery, r'^\s*`.*`\s*$') THEN
        -- Otherwise, make sure to wrap the table identifier in backticks if needed
        SET subquery = CONCAT('`', CONCAT(subquery, '`'));
    END IF;

    EXECUTE IMMEDIATE format("""(SELECT COUNT(*) FROM %s)""", subquery) INTO total_count;


    EXECUTE IMMEDIATE format("""
       WITH counts AS (
            SELECT
                `%s` as independent_var,
                `%s` as dependent_var,
                COUNT(*) as `count`
            FROM
                %s
           GROUP BY `%s`, `%s`
        ),
        independent_count AS (
            SELECT independent_var, SUM(`count`) AS independent_total
            FROM counts
            GROUP BY independent_var
        ),
         dependent_count AS (
            SELECT dependent_var, SUM(`count`) AS dependent_total
            FROM counts
            GROUP BY dependent_var
        ),
        contingency_table AS (
            SELECT * FROM counts
            INNER JOIN independent_count USING(independent_var)
            INNER JOIN dependent_count USING(dependent_var)
        ),
         expected_table AS (
            SELECT
                independent_var,
                dependent_var,
                independent_total * dependent_total / %d as count
            FROM `contingency_table`
        )
        SELECT
            SUM(POW(contingency_table.count - expected_table.count, 2) / expected_table.count) as chi_square,
            (COUNT(DISTINCT contingency_table.independent_var) - 1)
                * (COUNT(DISTINCT contingency_table.dependent_var) - 1) AS degrees_freedom
        FROM contingency_table
        INNER JOIN expected_table
            ON expected_table.independent_var = contingency_table.independent_var
            AND expected_table.dependent_var = contingency_table.dependent_var;


    """,
    category_1, category_2, subquery, category_1, category_2, total_count
    );


END;