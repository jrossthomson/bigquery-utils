

CREATE OR REPLACE FUNCTION st.t_test(pop1 ANY TYPE, pop2 ANY TYPE) AS ((
    WITH
        pop1_stats AS (
            SELECT STDDEV(x) st1, Avg(x) x1, Count(x) n1
          FROM UNNEST(pop1) AS x
        ),
        pop2_stats AS (
            SELECT STDDEV(x) st2, Avg(x) x2, Count(x) n2
          FROM UNNEST(pop2) AS x
        )
    SELECT
        STRUCT(
            (x1 - x2) / Sqrt((st1 * st1 / N1) + (st2 * st2/ N2)) AS t,
            n1+n2-2 AS df
        )
    FROM pop1_stats CROSS JOIN pop2_stats
));