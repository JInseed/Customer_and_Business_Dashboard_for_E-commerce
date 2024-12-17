# 상품 리뷰 평점 분석

# 1. ratigns 평균, review 수, sentiment good 비율

## 1) 상품별
SELECT 
	product_id, 
	AVG(ratings) AVG_ratings, 
    COUNT(review) as review_count,
    SUM(CASE WHEN sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(sentiment) as good_sentiment_ratio
FROM 
	customer_product_ratings
GROUP BY 1
ORDER BY 2 DESC
;


## 2) 카테고리별
SELECT 
    c.category_id,
    c.category_name,
    AVG(p_ratings.ratings) AS avg_ratings,
    COUNT(p_ratings.review) AS review_count,
    SUM(CASE WHEN p_ratings.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(p_ratings.sentiment) AS good_sentiment_ratio
FROM 
    category c
JOIN 
    subcategory s ON c.category_id = s.category_id
JOIN 
    product p ON s.subcategory_id = p.subcategory_id
LEFT JOIN 
    (
        SELECT 
            cp.product_id,
            cp.ratings,
            cp.review,
            cp.sentiment
        FROM 
            customer_product_ratings cp
    ) AS p_ratings ON p.product_id = p_ratings.product_id
GROUP BY 1
ORDER BY 3 DESC
;

## 3) 국가별
SELECT 
    c.country,
    AVG(cp.ratings) AS avg_ratings,
    COUNT(cp.review) AS review_count,
    SUM(CASE WHEN cp.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(cp.sentiment) AS good_sentiment_ratio
FROM 
    customer c
JOIN 
    customer_product_ratings cp ON c.customer_id = cp.customer_id
GROUP BY 1
ORDER BY 3 DESC
;

### 국가수
SELECT COUNT(DISTINCT country) AS unique_country_count
FROM customer;


## 4) 소비자별, 인당
SELECT 
    c.customer_id,
    AVG(cp.ratings) AS avg_ratings,
    COUNT(cp.review) AS review_count,
    SUM(CASE WHEN cp.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(cp.sentiment) AS good_sentiment_ratio
FROM 
    customer c
LEFT JOIN 
    customer_product_ratings cp ON c.customer_id = cp.customer_id
GROUP BY 
    c.customer_id
ORDER BY 2 DESC
;

### 모든 고객이 전부 리뷰를 작성해본 경험 있음
SELECT COUNT(DISTINCT customer_id) AS unique_customer_count
FROM customer_product_ratings;

## 인당 평균
WITH customer_summary AS (
    SELECT 
        cp.customer_id,
        AVG(cp.ratings) AS avg_ratings,
        COUNT(cp.review) AS review_count,
        SUM(CASE WHEN cp.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(cp.sentiment) AS good_sentiment_ratio
    FROM 
        customer_product_ratings cp
    GROUP BY 
        cp.customer_id
)
SELECT 
    AVG(avg_ratings) AS avg_ratings,
    AVG(review_count) AS avg_review_count,
    AVG(good_sentiment_ratio) AS avg_good_sentiment_ratio
FROM 
    customer_summary;


# 2. 순위 지정 

## 1) 카테고리, 상품별
WITH category_product_summary AS (
    SELECT 
        c.category_id,
        c.category_name,
        p.product_id,
        AVG(cp.ratings) AS avg_ratings,
        COUNT(cp.review) AS review_count,
        SUM(CASE WHEN cp.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(cp.sentiment) AS good_sentiment_ratio
    FROM 
        product p
    JOIN 
        customer_product_ratings cp ON p.product_id = cp.product_id
    JOIN 
        subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN 
        category c ON sc.category_id = c.category_id
    GROUP BY 
        c.category_id, p.product_id
),
ranked_summary AS (
    SELECT 
        cps.*,
        RANK() OVER (PARTITION BY cps.category_id ORDER BY cps.avg_ratings DESC) AS ratings_rank,
        RANK() OVER (PARTITION BY cps.category_id ORDER BY cps.review_count DESC) AS review_count_rank,
        RANK() OVER (PARTITION BY cps.category_id ORDER BY cps.good_sentiment_ratio DESC) AS good_sentiment_ratio_rank
    FROM 
        category_product_summary cps
)
SELECT 
    rs.category_id,
    rs.category_name,
    rs.product_id,
    rs.avg_ratings,
    rs.review_count,
    rs.good_sentiment_ratio,
    rs.ratings_rank,
    rs.review_count_rank,
    rs.good_sentiment_ratio_rank,
    RANK() OVER (PARTITION BY rs.category_id ORDER BY (rs.ratings_rank + rs.review_count_rank + rs.good_sentiment_ratio_rank)) AS total_rank
FROM 
    ranked_summary rs
ORDER BY rs.category_id;
    
## 2) 국가, 카테고리별
WITH country_category_product_summary AS (
    SELECT 
        c.country,
        ct.category_id,
        ct.category_name,
        AVG(cp.ratings) AS avg_ratings,
        COUNT(cp.review) AS review_count,
        SUM(CASE WHEN cp.sentiment = 'good' THEN 1 ELSE 0 END) / COUNT(cp.sentiment) AS good_sentiment_ratio
    FROM 
        customer_product_ratings cp
    JOIN 
        customer c ON cp.customer_id = c.customer_id
    JOIN 
        product p ON cp.product_id = p.product_id
    JOIN 
        subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN 
        category ct ON sc.category_id = ct.category_id
    GROUP BY 
        c.country, ct.category_id
),
ranked_summary AS (
    SELECT 
        ccps.*,
        RANK() OVER (PARTITION BY ccps.country ORDER BY ccps.avg_ratings DESC) AS ratings_rank,
        RANK() OVER (PARTITION BY ccps.country ORDER BY ccps.review_count DESC) AS review_count_rank,
        RANK() OVER (PARTITION BY ccps.country ORDER BY ccps.good_sentiment_ratio DESC) AS good_sentiment_ratio_rank
    FROM 
        country_category_product_summary ccps
)
SELECT 
    rs.country,
    rs.category_id,
    rs.category_name,
    rs.avg_ratings,
    rs.review_count,
    rs.good_sentiment_ratio,
    rs.ratings_rank,
    rs.review_count_rank,
    rs.good_sentiment_ratio_rank,
    RANK() OVER (PARTITION BY rs.country ORDER BY (rs.ratings_rank + rs.review_count_rank + rs.good_sentiment_ratio_rank)) AS total_rank
FROM 
    ranked_summary rs;

