CREATE TABLE sales (
  sale_id       NUMERIC NOT NULL,
  employee_id   NUMERIC NOT NULL,
  subsidiary_id NUMERIC NOT NULL,
  sale_date     DATE    NOT NULL,
  eur_value     NUMERIC(17,2) NOT NULL,
  product_id    BIGINT  NOT NULL,
  quantity      INTEGER NOT NULL,
  junk          CHAR(200),
  CONSTRAINT sales_pk     
     PRIMARY KEY (sale_id),
  CONSTRAINT sales_emp_fk 
     FOREIGN KEY          (subsidiary_id, employee_id)
      REFERENCES employees(subsidiary_id, employee_id)
);

SELECT SETSEED(0);

INSERT INTO sales (sale_id
                 , subsidiary_id, employee_id
                 , sale_date, eur_value
                 , product_id, quantity
                 , junk)
SELECT row_number() OVER (), data.*
  FROM (
       SELECT e.subsidiary_id, e.employee_id
            , (CURRENT_DATE - CAST(RANDOM()*3650 AS NUMERIC) * INTERVAL '1 DAY') sale_date
            , CAST(RANDOM()*100000 AS NUMERIC)/100 eur_value
            , CAST(RANDOM()*25 AS NUMERIC) + 1 product_id
            , CAST(RANDOM()*5 AS NUMERIC) + 1 quantity
            , 'junk'
         FROM employees e
            , GENERATE_SERIES(1, 1800) gen
        WHERE MOD(employee_id, 7) = 4
          AND gen < employee_id / 5
        ORDER BY sale_date
       ) data
 WHERE TO_CHAR(sale_date, 'D') <> '1';


VACUUM ANALYZE sales;
