  DROP INDEX sales_date;
CREATE INDEX sales_dt_pr ON sales (sale_date, product_id);

EXPLAIN
 SELECT sale_date, product_id, quantity
   FROM sales
  WHERE sale_date = now() - INTERVAL '1' DAY
  ORDER BY sale_date, product_id;
  
  DROP INDEX sales_dt_pr;

CREATE INDEX sales_dt_pr
    ON sales (sale_date ASC, product_id DESC);

EXPLAIN
 SELECT sale_date, product_id, quantity
   FROM sales
  WHERE sale_date >= now() - INTERVAL '1' DAY
  ORDER BY sale_date ASC, product_id DESC;
  
  
  
  DROP INDEX sales_dt_pr;

CREATE INDEX sales_dt_pr
    ON sales (sale_date ASC, product_id DESC NULLS LAST);

EXPLAIN
 SELECT sale_date, product_id, quantity
   FROM sales
  WHERE sale_date >= now() - INTERVAL '1' DAY
  ORDER BY sale_date ASC, product_id DESC NULLS LAST;
