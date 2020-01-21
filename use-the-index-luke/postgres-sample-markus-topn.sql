DROP INDEX scale_fast;
CREATE INDEX scale_slow ON scale_data (SECTION, ID1, ID2);
ALTER TABLE scale_data CLUSTER ON scale_slow;
CLUSTER scale_data;

SELECT *
  FROM test_scalability('SELECT * '
                      ||  'FROM scale_data '
                      || 'WHERE section=$1 '
                      || 'ORDER BY id2, id1 '
                      || 'FETCH FIRST 100 ROWS ONLY', 10)
       AS (sec INT, seconds INTERVAL, cnt_rows INT);
       
       
CREATE INDEX scale_fast ON scale_data (SECTION, ID2, ID1);
ALTER TABLE scale_data CLUSTER ON scale_fast;
CLUSTER scale_data;

SELECT *
  FROM test_scalability('SELECT * '
                      ||  'FROM scale_data '
                      || 'WHERE section=$1 '
                      || 'ORDER BY id2, id1 '
                      || 'FETCH FIRST 100 ROWS ONLY', 10)
       AS (sec INT, seconds INTERVAL, cnt_rows INT);
       
       
CREATE OR REPLACE
FUNCTION test_topn_scalability (n INT)
 RETURNS SETOF RECORD AS
$$
DECLARE
  strt  TIMESTAMP;
  dur   INTERVAL;
  v_rec RECORD;
  mode  INT; iter  INT; sec   INT;
  lf    RECORD;
  c1    INT[300]; c2 INT[300];

  sql_restart CURSOR (sec int, page int)
           IS SELECT id2, id1   
                FROM scale_data
               WHERE section = sec
               ORDER BY id2,id1
              OFFSET 100*page
               FETCH NEXT 100 ROWS ONLY;

  sql_continue CURSOR (sec int, c2 int, c1 int) 
            IS SELECT id2, id1
                 FROM scale_data
                WHERE section = sec
              --    AND (id2, id1) > (c2, c1)
                  AND id2 >= c2
                  AND (
                         (id2 = c2 AND id1 > c1)
                       OR
                         (id2 > c2)
                      )
                ORDER BY id2,id1
                FETCH NEXT 100 ROWS ONLY;
BEGIN
  FOR iter  IN 1..n LOOP
    FOR mode  IN 0..1 LOOP
      FOR page IN 0..100 LOOP
        FOR sec IN 0..300 LOOP
          strt := CLOCK_TIMESTAMP();

          IF mode = 0 or page = 0 THEN
            FOR lf IN sql_restart(sec, page) LOOP
              c1[sec] := lf.id1; c2[sec] := lf.id2;
            END LOOP;
          ELSE
            FOR lf IN sql_continue(sec, c2[sec], c1[sec]) LOOP
              c1[sec] := lf.id1; c2[sec] := lf.id2;
            END LOOP;
          END IF;

          dur := (CLOCK_TIMESTAMP() - strt);

          SELECT INTO v_rec mode, sec, page, dur;
          RETURN NEXT v_rec;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT sec, mode, page, sum(seconds)
  FROM test_topn_scalability(10) 
    AS (mode INT, sec INT, page int, seconds INTERVAL)
 WHERE sec=10
 GROUP BY sec, mode, page
 ORDER BY sec, mode, page;
