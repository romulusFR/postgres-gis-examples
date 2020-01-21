CREATE TABLE scale_write_0 AS (
SELECT GENERATE_SERIES::numeric id1
     , (random() * 9000000)::numeric + 10000000 id2
     , (random() * 9000000)::numeric + 10000000 id3
     , (random() * 9000000)::numeric + 10000000 id4
     , (random() * 9000000)::numeric + 10000000 id5
  FROM GENERATE_SERIES(10000000, 19999999)
);



CREATE TABLE scale_write_1
AS (SELECT * from scale_write_0);

CREATE TABLE scale_write_2
AS (SELECT * from scale_write_0);

CREATE TABLE scale_write_3
AS (SELECT * from scale_write_0);

CREATE TABLE scale_write_4
AS (SELECT * from scale_write_0);

CREATE TABLE scale_write_5
AS SELECT * from scale_write_0;



CREATE INDEX scale_write_1_1 on scale_write_1(id1);

CREATE INDEX scale_write_2_1 on scale_write_2(id1);
CREATE INDEX scale_write_2_2 on scale_write_2(id2, id1);

CREATE INDEX scale_write_3_1 on scale_write_3(id1);
CREATE INDEX scale_write_3_2 on scale_write_3(id2, id1);
CREATE INDEX scale_write_3_3 on scale_write_3(id3, id2, id1);

CREATE INDEX scale_write_4_1 on scale_write_4(id1);
CREATE INDEX scale_write_4_2 on scale_write_4(id2, id1);
CREATE INDEX scale_write_4_3 on scale_write_4(id3, id2, id1);
CREATE INDEX scale_write_4_4 on scale_write_4(id4, id3, id2
                                             ,id1);

CREATE INDEX scale_write_5_1 on scale_write_5(id1);
CREATE INDEX scale_write_5_2 on scale_write_5(id2, id1);
CREATE INDEX scale_write_5_3 on scale_write_5(id3, id2, id1);
CREATE INDEX scale_write_5_4 on scale_write_5(id4, id3, id2
                                             ,id1);
CREATE INDEX scale_write_5_5 on scale_write_5(id5, id4, id3
                                             ,id2, id1);

CREATE OR REPLACE
FUNCTION run_insert(idxes INT, lb INT, ub INT, n INT)
 RETURNS VARCHAR AS
$$
DECLARE
  rows_affected INT;
  r2 INT;
  r3 INT;
  r4 INT;
  r5 INT;
  d1 INT;
BEGIN
  WHILE n > 0 LOOP
    d1 := (random() * (ub-lb))::INT + lb;
    r2 := (random() * 9000000)::INT;
    r3 := (random() * 9000000)::INT;
    r4 := (random() * 9000000)::INT;
    r5 := (random() * 9000000)::INT;
    CASE idxes
    WHEN 0 THEN 
           INSERT INTO scale_write_0 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    WHEN 1 THEN 
           INSERT INTO scale_write_1 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    WHEN 2 THEN 
           INSERT INTO scale_write_2 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    WHEN 3 THEN 
           INSERT INTO scale_write_3 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    WHEN 4 THEN 
           INSERT INTO scale_write_4 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    WHEN 5 THEN 
           INSERT INTO scale_write_5 (id1, id2, id3, id4, id5)
                              VALUES ( d1,  r2,  r3,  r4,  r5);
    END CASE;
    n := n - 1;
  END LOOP;
  RETURN 'insert';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE
FUNCTION run_delete(tbl INT, lb INT, ub INT, n INT)
 RETURNS VARCHAR AS 
$$
DECLARE
  rows_affected INT;
  aff  INT := 0;
  d1   INT;
  iter INT := n;
BEGIN
  WHILE iter > 0 LOOP
    d1 := (random() * (ub-lb))::INT + lb;
    CASE tbl
    WHEN 1 THEN 
           DELETE FROM scale_write_1 WHERE id1 = d1;
    WHEN 2 THEN 
           DELETE FROM scale_write_2 WHERE id1 = d1;
    WHEN 3 THEN 
           DELETE FROM scale_write_3 WHERE id1 = d1;
    WHEN 4 THEN 
           DELETE FROM scale_write_4 WHERE id1 = d1;
    WHEN 5 THEN 
           DELETE FROM scale_write_5 WHERE id1 = d1;
    ELSE NULL;
    END CASE;
    iter := iter - 1;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    aff := aff + rows_affected;
  END LOOP;
  RETURN CASE WHEN aff = n THEN 'delete'
         ELSE NULL END;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE
FUNCTION run_update_all(tbl INT, lb INT, ub INT, n INT)
RETURNS VARCHAR AS
$$
DECLARE
  rows_affected INT;
  r2  INT;
  r3  INT;
  r4  INT;
  r5  INT;
  d1  INT;
  iter INT := n;
  aff  INT := 0;
BEGIN
  WHILE iter > 0 LOOP
    d1 := (random() * (ub-lb))::INT + lb;
    r2 := (random() * 9000000)::INT;
    r3 := (random() * 9000000)::INT;
    r4 := (random() * 9000000)::INT;
    r5 := (random() * 9000000)::INT;
    CASE tbl
    WHEN 1 THEN 
           UPDATE scale_write_1
              SET id2 = r2, id3=r3, id4=r4, id5=r5 WHERE id1=d1;
    WHEN 2 THEN
           UPDATE scale_write_2
              SET id2 = r2, id3=r3, id4=r4, id5=r5 WHERE id1=d1;
    WHEN 3 THEN 
           UPDATE scale_write_3
              SET id2 = r2, id3=r3, id4=r4, id5=r5 WHERE id1=d1; 
    WHEN 4 THEN 
           UPDATE scale_write_4
              SET id2 = r2, id3=r3, id4=r4, id5=r5 WHERE id1=d1; 
    WHEN 5 THEN 
           UPDATE scale_write_5
              SET id2 = r2, id3=r3, id4=r4, id5=r5 WHERE id1=d1;
    ELSE NULL;
    END CASE; 
    iter := iter - 1;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    aff := aff + rows_affected;
  END LOOP;
  RETURN CASE WHEN aff = n THEN 'update all'
         ELSE NULL END;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE
FUNCTION run_update_one(tbl INT, lb INT, ub INT, n INT)
RETURNS VARCHAR AS
$$
DECLARE
  rows_affected INT;
  r  INT;
  d1 INT;
  aff  INT := 0;
  iter INT := n;
BEGIN
  WHILE iter > 0 LOOP
    d1 := (random() * (ub-lb))::INT + lb;
    r  := (random() * 9000000)::INT;
    CASE tbl
    WHEN 1 THEN -- no index updated
           UPDATE scale_write_1 SET id2 = r WHERE id1=d1;
    WHEN 2 THEN -- one index updated
           UPDATE scale_write_2 SET id2 = r WHERE id1=d1;
    WHEN 3 THEN -- one index updated
           UPDATE scale_write_3 SET id3 = r WHERE id1=d1;
    WHEN 4 THEN -- one index updated
           UPDATE scale_write_4 SET id4 = r WHERE id1=d1;
    WHEN 5 THEN -- one index updated
           UPDATE scale_write_5 SET id5 = r WHERE id1=d1;
    ELSE NULL;
    END CASE;
    iter := iter - 1;
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    aff := aff + rows_affected;
  END LOOP;
  RETURN CASE WHEN aff = n THEN 'update one'
         ELSE NULL END;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE
FUNCTION test_write_scalability (n INT)
 RETURNS SETOF RECORD AS
$$
DECLARE
  rec  RECORD;
  strt TIMESTAMP;
  mode VARCHAR;
  cmnd INT;
  q    INT;
  lb   INT;
  alb  INT;
  iter INT;
  idxs INT;
BEGIN
  SELECT ((max(id1)-min(id1))/4)::INT, min(id1)::INT
    INTO q, alb
    FROM scale_write_1;

  FOR iter IN 1 .. n LOOP
    FOR cmnd IN 0 .. 3 LOOP
      FOR idxs IN 0 .. 5 LOOP
        lb   := alb + cmnd*q;
        strt := CLOCK_TIMESTAMP();
        mode := 
          CASE cmnd
          WHEN 0 THEN run_insert    (idxs, lb, lb+q, 1)
          WHEN 1 THEN run_update_one(idxs, lb, lb+q, 1)
          WHEN 2 THEN run_delete    (idxs, lb, lb+q, 1)
          WHEN 3 THEN run_update_all(idxs, lb, lb+q, 1)
          END;

        IF mode IS NOT NULL THEN
           SELECT INTO rec
                  idxs, mode, (CLOCK_TIMESTAMP() - strt);
           RETURN NEXT rec;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
  RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT indxes
     , mode
     , AVG(seconds)  seconds   
     , TO_CHAR (STDDEV(EXTRACT(epoch FROM seconds))
                / AVG(EXTRACT(epoch FROM seconds))
                * 100
               , '999.9') std_dev_prc
  FROM test_write_scalability(10) 
    AS (indxes INT, mode VARCHAR, seconds INTERVAL)
 GROUP BY indxes, mode
 ORDER BY mode, indxes;
