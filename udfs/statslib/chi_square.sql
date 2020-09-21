
CREATE OR REPLACE FUNCTION st.chi_square(data ARRAY<STRUCT<X FLOAT64, Y FLOAT64>>) AS ((
   WITH counts AS (
        SELECT
            d.X as independent_var,
            d.Y as dependent_var,
            COUNT(*) as `count`
        FROM
            UNNEST(data) AS d
       GROUP BY d.X, d.Y
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
            independent_total * dependent_total / count as count
        FROM `contingency_table`
    )
    SELECT STRUCT (
           SUM(POW(contingency_table.count - expected_table.count, 2) / expected_table.count) as chi_square,
               (COUNT(DISTINCT contingency_table.independent_var) - 1)
               * (COUNT(DISTINCT contingency_table.dependent_var) - 1) AS degrees_freedom
           )
    FROM contingency_table
    INNER JOIN expected_table
        ON expected_table.independent_var = contingency_table.independent_var
        AND expected_table.dependent_var = contingency_table.dependent_var
));