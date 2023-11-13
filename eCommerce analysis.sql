-- membuat ERD (ID)
-- create an ERD (ENG)

CREATE TABLE IF NOT EXISTS public.customers_dataset
(
    customers_id character varying,
    customer_unique_id character varying,
    customer_zip_code_prefix integer,
    customer_city character varying,
    customer_state character varying,
    PRIMARY KEY (customers_id)
);

CREATE TABLE IF NOT EXISTS public.geolocation_dataset3
(
    geolocation_zip_code_prefix integer,
    geolocation_lat bigint,
    geolocation_lng bigint,
    geolocation_city character varying COLLATE pg_catalog."default",
    geolocation_state character varying COLLATE pg_catalog."default",
    PRIMARY KEY (geolocation_zip_code_prefix)
);

CREATE TABLE IF NOT EXISTS public.order_items_dataset
(
    order_id character varying(50) COLLATE pg_catalog."default",
    order_item_id numeric,
    product_id character varying(50) COLLATE pg_catalog."default",
    seller_id character varying(50) COLLATE pg_catalog."default",
    shipping_limit_date timestamp without time zone,
    price numeric,
    freight_value numeric,
    PRIMARY KEY (order_id)
);

CREATE TABLE IF NOT EXISTS public.order_payments_dataset
(
    order_id character varying(50) COLLATE pg_catalog."default",
    payment_sequential integer,
    payment_type character varying(50) COLLATE pg_catalog."default",
    payment_installments integer,
    payment_value numeric,
    PRIMARY KEY (order_id)
);

CREATE TABLE IF NOT EXISTS public.order_reviews_dataset
(
    review_id character varying COLLATE pg_catalog."default",
    order_id character varying COLLATE pg_catalog."default",
    review_score integer,
    review_comment_title character varying COLLATE pg_catalog."default",
    review_comment_message character varying COLLATE pg_catalog."default",
    review_creation_date timestamp without time zone,
    review_answer_timestamp timestamp without time zone,
    PRIMARY KEY (review_id)
);

CREATE TABLE IF NOT EXISTS public.orders_dataset
(
    order_id character varying COLLATE pg_catalog."default",
    customer_id character varying COLLATE pg_catalog."default",
    order_status character varying COLLATE pg_catalog."default",
    order_purchase_timestamp timestamp without time zone,
    order_approved_at timestamp without time zone,
    order_delivered_carrier_date timestamp without time zone,
    order_delivered_customer_date timestamp without time zone,
    order_estimated_delivery_date timestamp without time zone,
    PRIMARY KEY (order_id)
);

CREATE TABLE IF NOT EXISTS public.product_dataset
(
    no integer,
    product_id character varying COLLATE pg_catalog."default",
    product_category_name character varying COLLATE pg_catalog."default",
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer,
    PRIMARY KEY (product_id)
);

CREATE TABLE IF NOT EXISTS public.sellers_dataset
(
    seller_id character varying COLLATE pg_catalog."default",
    seller_zip_code_prefix integer,
    seller_city character varying COLLATE pg_catalog."default",
    seller_state character varying COLLATE pg_catalog."default",
    PRIMARY KEY (seller_id)
);

ALTER TABLE IF EXISTS public.customers_dataset
    ADD CONSTRAINT customers_zip_code_prefix FOREIGN KEY (customer_zip_code_prefix)
    REFERENCES public.geolocation_dataset3 (geolocation_zip_code_prefix) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order_items_dataset
    ADD CONSTRAINT seller_id FOREIGN KEY (seller_id)
    REFERENCES public.sellers_dataset (seller_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order_items_dataset
    ADD CONSTRAINT product_id FOREIGN KEY (product_id)
    REFERENCES public.product_dataset (product_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order_items_dataset
    ADD CONSTRAINT order_id FOREIGN KEY (order_id)
    REFERENCES public.orders_dataset (order_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order_payments_dataset
    ADD CONSTRAINT order_id FOREIGN KEY (order_id)
    REFERENCES public.orders_dataset (order_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.order_reviews_dataset
    ADD CONSTRAINT order_id FOREIGN KEY (order_id)
    REFERENCES public.orders_dataset (order_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.orders_dataset
    ADD CONSTRAINT customer_id FOREIGN KEY (customer_id)
    REFERENCES public.customers_dataset (customers_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;


ALTER TABLE IF EXISTS public.sellers_dataset
    ADD CONSTRAINT seller_zip_code_prefix FOREIGN KEY (seller_zip_code_prefix)
    REFERENCES public.geolocation_dataset3 (geolocation_zip_code_prefix) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;

-- The Customer Growth Metrics

-- menampilkan rata-rata jumlah customer aktif bulanan (monthly active user) untuk setiap tahun
-- displays the average number of monthly active customers (monthly active users) for each year
SELECT 
	year, 
	FLOOR(AVG(customer_total)) AS avg_mau
FROM (
  SELECT 
  	date_part('year', od.order_purchase_timestamp) AS year,
  	date_part('month', od.order_purchase_timestamp) AS month,
  	COUNT(DISTINCT cd.customer_unique_id) AS customer_total
  FROM orders_dataset AS od
  JOIN customers_dataset AS cd
  	ON cd.customers_id = od.customer_id
  GROUP BY 1, 2
  ) AS sub
GROUP BY 1
ORDER BY 1
;

-- menampilkan jumlah customer baru pada masing-masing tahun
-- displays the number of new customers in each year
SELECT 
	year, 
	COUNT(customer_unique_id) AS total_new_customer
FROM (
  SELECT
  	Min(date_part('year', od.order_purchase_timestamp)) AS year,
  	cd.customer_unique_id
  FROM orders_dataset AS od
  JOIN customers_dataset AS cd
  	ON cd.customers_id = od.customer_id
  GROUP BY 2
  ) AS sub
GROUP BY 1
ORDER BY 1
;

-- menampilkan jumlah customer repeat order pada masing-masing tahun
-- displays the number of customer repeat orders in each year
SELECT 
	year, 
	count(customer_unique_id) AS total_customer_repeat
FROM (
  SELECT
  	date_part('year', od.order_purchase_timestamp) AS year,
  	cd.customer_unique_id,
  	COUNT(od.order_id) AS total_order
  FROM orders_dataset AS od
  JOIN customers_dataset AS cd
  	ON cd.customers_id = od.customer_id
  GROUP BY 1, 2
  HAVING count(2) > 1
  ) AS sub
GROUP BY 1
ORDER BY 1
;

-- menampilkan rata-rata jumlah order yang dilakukan customer untuk masing-masing tahun
-- displays the average number of orders placed by customers for each year
SELECT 
	year, 
	ROUND(AVG(freq), 3) AS avg_frequency
FROM (
  SELECT
  	date_part('year', od.order_purchase_timestamp) AS year,
  	cd.customer_unique_id,
  	COUNT(order_id) AS freq
  FROM orders_dataset AS od
  JOIN customers_dataset AS cd
  	ON cd.customers_id = od.customer_id
  GROUP BY 1, 2
  ) AS sub
GROUP BY 1
ORDER BY 1
;

-- menggabungkan ketiga metrik yang telah berhasil ditampilkan menjadi satu tampilan tabel
-- combines three successfully collected metrics into one table view
WITH cte_mau AS (
  SELECT 
	year, 
	FLOOR(AVG(customer_total)) AS avg_mau
  FROM (
  	SELECT 
  		date_part('year', od.order_purchase_timestamp) AS year,
  		date_part('month', od.order_purchase_timestamp) AS month,
  		COUNT(DISTINCT cd.customer_unique_id) AS customer_total
  	FROM orders_dataset AS od
  	JOIN customers_dataset AS cd
  		ON cd.customers_id = od.customer_id
  	GROUP BY 1, 2
  	) AS sub
  GROUP BY 1
),

cte_new_cust AS (
  SELECT 
	year, 
	COUNT(customer_unique_id) AS total_new_customer
  FROM (
  	SELECT
  		Min(date_part('year', od.order_purchase_timestamp)) AS year,
  		cd.customer_unique_id
  	FROM orders_dataset AS od
  	JOIN customers_dataset AS cd
  		ON cd.customers_id = od.customer_id
  	GROUP BY 2
  	) AS sub
  GROUP BY 1
),

cte_repeat_order AS (
  SELECT 
	year, 
	count(customer_unique_id) AS total_customer_repeat
  FROM (
  	SELECT
  		date_part('year', od.order_purchase_timestamp) AS year,
  		cd.customer_unique_id,
  		COUNT(od.order_id) AS total_order
  	FROM orders_dataset AS od
  	JOIN customers_dataset AS cd
  		ON cd.customers_id = od.customer_id
  	GROUP BY 1, 2
  	HAVING count(2) > 1
  	) AS sub
  GROUP BY 1
),

cte_frequency AS (
  SELECT 
	year, 
	ROUND(AVG(freq), 3) AS avg_frequency
  FROM (
  	SELECT
  		date_part('year', od.order_purchase_timestamp) AS year,
  		cd.customer_unique_id,
  		COUNT(order_id) AS freq
  	FROM orders_dataset AS od
  	JOIN customers_dataset AS cd
  		ON cd.customers_id = od.customer_id
  	GROUP BY 1, 2
  	) AS sub
  GROUP BY 1
)

SELECT
  mau.year AS year,
  avg_mau,
  total_new_customer,
  total_customer_repeat,
  avg_frequency
FROM
  cte_mau AS mau
  JOIN cte_new_cust AS nc
  	ON mau.year = nc.year
  JOIN cte_repeat_order AS ro
  	ON nc.year = ro.year
  JOIN cte_frequency AS f
  	ON ro.year = f.year
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1
;

-- The Product Quality Metrics

-- membuat tabel yang berisi informasi pendapatan/revenue perusahaan total untuk masing-masing tahun
-- create a table containing total company income/revenue information for each year
CREATE TABLE total_revenue AS
  SELECT
  	date_part('year', od.order_purchase_timestamp) AS year,
  	SUM(oid.price + oid.freight_value) AS revenue
  FROM order_items_dataset AS oid
  JOIN orders_dataset AS od
  	ON oid.order_id = od.order_id
  WHERE od.order_status like 'delivered'
  GROUP BY 1
  ORDER BY 1;

-- membuat tabel yang berisi informasi jumlah cancel order total untuk masing-masing tahun
-- create a table containing information on the total number of canceled orders for each year
CREATE TABLE canceled_order AS
  SELECT
  	date_part('year', order_purchase_timestamp) AS year,
  	COUNT(order_status) AS canceled
  FROM orders_dataset
  WHERE order_status like 'canceled'
  GROUP BY 1
  ORDER BY 1;

-- membuat tabel yang berisi nama kategori produk yang memberikan pendapatan total tertinggi untuk masing-masing tahun
-- create a table containing the names of product categories that provide the highest total revenue for each year
CREATE TABLE top_product_category AS
  SELECT 
  	year,
  	top_category,
  	product_revenue
  FROM (
  	SELECT
  		date_part('year', shipping_limit_date) AS year,
  		pd.product_category_name AS top_category,
  		SUM(oid.price + oid.freight_value) AS product_revenue,
  		RANK() OVER (PARTITION BY date_part('year', shipping_limit_date)
  				 ORDER BY SUM(oid.price + oid.freight_value) DESC) AS ranking
  	FROM orders_dataset AS od 
  	JOIN order_items_dataset AS oid
  		ON od.order_id = oid.order_id
  	JOIN product_dataset AS pd
  		ON oid.product_id = pd.product_id
  	WHERE od.order_status like 'delivered'
  	GROUP BY 1, 2
  	ORDER BY 1
  	) AS sub
  WHERE ranking = 1;

-- membuat tabel yang berisi nama kategori produk yang memiliki jumlah cancel order terbanyak untuk masing-masing tahun
-- create a table containing the names of product categories that have the highest number of canceled orders for each year
CREATE TABLE most_canceled_category AS
  SELECT 
  	year,
  	most_canceled,
  	total_canceled
  FROM (
  	SELECT
  		date_part('year', shipping_limit_date) AS year,
  		pd.product_category_name AS most_canceled,
  		COUNT(od.order_id) AS total_canceled,
  		RANK() OVER (PARTITION BY date_part('year', shipping_limit_date)
  				 ORDER BY COUNT(od.order_id) DESC) AS ranking
  	FROM orders_dataset AS od 
  	JOIN order_items_dataset AS oid
  		ON od.order_id = oid.order_id
  	JOIN product_dataset AS pd
  		ON oid.product_id = pd.product_id
  	WHERE od.order_status like 'canceled'
  	GROUP BY 1, 2
  	ORDER BY 1
  	) AS sub
  WHERE ranking = 1;

-- menggabungkan informasi-informasi yang telah didapatkan ke dalam satu tampilan tabel
-- combines the information that has been obtained in one table display 

-- pada tabel top product categgoty terdapat anomali data yaitu row year 2020, top category housewares, dan product revenue 322.
-- in the top product category table there are data anomalies, namely row year 2020, top category housewares, and product revenue 322. 

-- pada tabel most canceled categgoty terdapat anomali data yaitu row year 2020, most canceled housewares, dan total canceled 1.
-- In the most canceled category table there are data anomalies, namely row year 2020, most canceled housewares, and total canceled 1.

-- menghapus anomali data tahun
-- remove year data anomalies
DELETE FROM top_product_category WHERE year = 2020;
DELETE FROM most_canceled_category WHERE year = 2020;

-- menggabungkan tabel
-- combine tables
SELECT 
  tr.year,
  tr.revenue AS total_revenue,
  tpc.top_category AS top_product,
  tpc.product_revenue AS total_revenue_top_product,
  co.canceled total_canceled,
  mcc.most_canceled top_canceled_product,
  mcc.total_canceled total_top_canceled_product
FROM total_revenue AS tr
JOIN top_product_category AS tpc
  ON tr.year = tpc.year
JOIN canceled_order AS co
  ON tpc.year = co.year
JOIN most_canceled_category AS mcc
  ON co.year = mcc.year
GROUP BY 1, 2, 3, 4, 5, 6, 7;

-- The Payment Methods Metrics

-- menampilkan jumlah penggunaan masing-masing tipe pembayaran secara all time diurutkan dari yang terfavorit
-- displays the number of uses of each type of payment all time sorted from the most favorite
SELECT 
	payment_type, 
	COUNT(1) 
FROM order_payments_dataset
GROUP BY 1
ORDER BY 2 DESC;
 
-- menampilkan detail informasi jumlah penggunaan masing-masing tipe pembayaran untuk setiap tahun
-- displays detailed information on the amount of usage of each payment type for each year
SELECT
  payment_type,
  SUM(CASE WHEN year = 2016 THEN total ELSE 0 END) AS "2016",
  SUM(CASE WHEN year = 2017 THEN total ELSE 0 END) AS "2017",
  SUM(CASE WHEN year = 2018 THEN total ELSE 0 END) AS "2018",
  SUM(total) AS sum_payment_type_usage
FROM (
  SELECT 
  	date_part('year', od.order_purchase_timestamp) AS year,
  	opd.payment_type,
  	COUNT(opd.payment_type) AS total
  FROM orders_dataset AS od
  JOIN order_payments_dataset AS opd 
  	ON od.order_id = opd.order_id
  GROUP BY 1, 2
  ) AS sub
GROUP BY 1
ORDER BY 2 DESC;