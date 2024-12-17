# 1. 재구매 분석

# 1) 소비자별 특정 상품 구매 총 횟수, 재구매횟수, 재구매까지 걸린 시간, 모든 상품 총 구매 횟수

WITH CustomerOrders AS (
    SELECT
        o.customer_id,
        oi.product_id,
        o.order_date,
        oi.quantity,
        c.country -- 고객의 나라 추가
    FROM
        orders o
        JOIN orderitem oi ON o.order_id = oi.order_id
        JOIN customer c ON o.customer_id = c.customer_id -- customer 테이블과 조인
),
RankedOrders AS (
    SELECT
        customer_id,
        product_id,
        order_date,
        quantity,
        country, -- 고객의 나라를 계속해서 포함
        LAG(order_date) OVER (PARTITION BY customer_id, product_id ORDER BY order_date) AS previous_order_date
    FROM
        CustomerOrders
),
PurchaseDetails AS (
    SELECT
        customer_id,
        product_id,
        country, -- 고객의 나라 선택
        COUNT(order_date) AS purchase_count,
        SUM(quantity) AS total_quantity, -- 총 구매한 상품 수량
        CASE 
            WHEN COUNT(order_date) > 1 THEN AVG(DATEDIFF(order_date, previous_order_date))
            ELSE NULL -- 재구매가 없으면 평균 재구매 시간은 NULL
        END AS avg_repurchase_time
    FROM
        RankedOrders
    GROUP BY
        customer_id, product_id, country
),
CustomerTotalPurchases AS (
    SELECT
        customer_id,
        SUM(quantity) AS total_purchase_count -- 총 구매 수량 계산
    FROM
        orderitem oi
        JOIN orders o ON oi.order_id = o.order_id
    GROUP BY
        customer_id
),
FinalSummary AS (
    SELECT
        pd.customer_id,
        pd.country, -- 고객의 나라를 최종 결과에 포함
        cat.category_name,
        sc.subcategory_name,
        p.name AS product_name,
        pd.product_id,
        pd.purchase_count,
        CASE 
            WHEN pd.purchase_count > 1 THEN pd.purchase_count - 1
            ELSE 0 -- 재구매 횟수 계산, 한 번만 구매한 경우 0
        END AS repurchase_count,
        pd.avg_repurchase_time,
        ctp.total_purchase_count
    FROM
        PurchaseDetails pd
        JOIN product p ON pd.product_id = p.product_id
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category cat ON sc.category_id = cat.category_id
        JOIN CustomerTotalPurchases ctp ON pd.customer_id = ctp.customer_id
)
SELECT *
FROM
    FinalSummary;
    
## 2) 소비자 별로 구매건수마다 평균 몇 가지의 카테고리를 구입하는가? => 전체 평균은 4.745
WITH OrderCategories AS (
    SELECT
        o.customer_id,
        o.order_id,
        COUNT(DISTINCT c.category_id) AS category_count
    FROM
        orders o
        JOIN orderitem oi ON o.order_id = oi.order_id
        JOIN product p ON oi.product_id = p.product_id
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category c ON sc.category_id = c.category_id
    GROUP BY
        o.customer_id, o.order_id
),
CustomerCategoryAverages AS (
    SELECT
        customer_id,
        AVG(category_count * 1.0) AS avg_category_per_order
    FROM
        OrderCategories
    GROUP BY
        customer_id
)
SELECT *
FROM
    CustomerCategoryAverages
ORDER BY
    customer_id;


# 2. 대시보드를 위한 분석 및 테이블 생성

## 1) 소비자별 가장 많이 구입하는 상위 5개의 카테고리(같은 횟수일 경우 재구매율, 평균 평점을 기준으로 우선 순위)
WITH CategoryPurchases AS (
    SELECT
        o.customer_id,
        c.category_id,
        COUNT(*) AS purchase_count, -- 각 카테고리별 총 구매 횟수
        COUNT(DISTINCT CASE WHEN oi.quantity > 1 THEN o.order_id END) AS repurchase_count -- 재구매 횟수
    FROM
        orders o
        JOIN orderitem oi ON o.order_id = oi.order_id
        JOIN product p ON oi.product_id = p.product_id
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category c ON sc.category_id = c.category_id
    GROUP BY
        o.customer_id, c.category_id
),
CategoryRatings AS (
    SELECT
        c.category_id,
        AVG(p_ratings.ratings) AS avg_ratings, -- 카테고리별 평균 평점
        COUNT(p_ratings.review) AS review_count, -- 리뷰 수
        SUM(CASE WHEN p_ratings.sentiment = 'good' THEN 1 ELSE 0 END) * 1.0 / COUNT(p_ratings.sentiment) AS good_sentiment_ratio -- 긍정 리뷰 비율
    FROM
        category c
        JOIN subcategory s ON c.category_id = s.category_id
        JOIN product p ON s.subcategory_id = p.subcategory_id
        LEFT JOIN customer_product_ratings p_ratings ON p.product_id = p_ratings.product_id
    GROUP BY
        c.category_id
),
CategoryRepurchaseRates AS (
    SELECT
        cp.customer_id,
        cp.category_id,
        cp.purchase_count,
        cp.repurchase_count,
        CASE WHEN cp.purchase_count > 0 THEN cp.repurchase_count * 1.0 / cp.purchase_count ELSE 0 END AS repurchase_rate,
        cr.avg_ratings, -- 평균 평점
        cr.review_count, -- 리뷰 수
        cr.good_sentiment_ratio -- 긍정 리뷰 비율
    FROM
        CategoryPurchases cp
        JOIN CategoryRatings cr ON cp.category_id = cr.category_id
),
RankedCategories AS (
    SELECT
        cr.customer_id,
        cat.category_name,
        cr.purchase_count,
        cr.repurchase_rate,
        cr.avg_ratings,
        cr.review_count,
        cr.good_sentiment_ratio,
        DENSE_RANK() OVER (PARTITION BY cr.customer_id ORDER BY cr.purchase_count DESC, cr.repurchase_rate DESC, cr.avg_ratings DESC, cr.review_count DESC, cr.good_sentiment_ratio DESC) AS ranking
    FROM
        CategoryRepurchaseRates cr
        JOIN category cat ON cr.category_id = cat.category_id
)
SELECT
    customer_id,
    category_name,
    purchase_count,
    repurchase_rate,
    avg_ratings,
    review_count,
    good_sentiment_ratio,
    ranking
FROM
    RankedCategories
WHERE
    ranking <= 5
ORDER BY
    customer_id, ranking;

# 2. 재구매율, 평균평점, 긍정 리뷰 비율, 리뷰수, 구매 횟수 등

## 1) 카테고리 내에서 재구매율, 평균평점, 긍정 리뷰 비율, 리뷰수, 구매 횟수 등 : 작동시간 약 30초
WITH SubcategoryMetrics AS (
    SELECT
        c.category_id,
        c.category_name,
        sc.subcategory_id,
        sc.subcategory_name,
        COUNT(*) AS purchase_count, -- 구매 횟수
        COUNT(DISTINCT CASE WHEN oi.quantity > 1 THEN oi.order_id END) / COUNT(DISTINCT oi.order_id) AS repurchase_rate, -- 재구매율
        AVG(pr.ratings) AS avg_rating, -- 평균평점
        SUM(CASE WHEN pr.sentiment = 'good' THEN 1 ELSE 0 END) * 1.0 / COUNT(pr.sentiment) AS good_sentiment_ratio, -- 긍정 리뷰 비율
        COUNT(pr.review) AS review_count -- 리뷰수
    FROM
        category c
        JOIN subcategory sc ON c.category_id = sc.category_id
        JOIN product p ON sc.subcategory_id = p.subcategory_id
        JOIN orderitem oi ON p.product_id = oi.product_id
        LEFT JOIN customer_product_ratings pr ON p.product_id = pr.product_id
    GROUP BY
        c.category_id, sc.subcategory_id
),
RankedMetrics AS (
    SELECT
        category_id,
        category_name,
        subcategory_id,
        subcategory_name,
        purchase_count,
        repurchase_rate,
        avg_rating,
        good_sentiment_ratio,
        review_count,
        RANK() OVER (PARTITION BY category_id ORDER BY repurchase_rate DESC) AS repurchase_rate_rank,
        RANK() OVER (PARTITION BY category_id ORDER BY avg_rating DESC) AS avg_rating_rank,
        RANK() OVER (PARTITION BY category_id ORDER BY good_sentiment_ratio DESC) AS good_sentiment_ratio_rank
    FROM
        SubcategoryMetrics
),
FinalRanking AS (
    SELECT
        *,
        (repurchase_rate_rank + avg_rating_rank + good_sentiment_ratio_rank) AS total_rank,
        RANK() OVER (PARTITION BY category_id ORDER BY (repurchase_rate_rank + avg_rating_rank + good_sentiment_ratio_rank)) AS final_rank
    FROM
        RankedMetrics
)
SELECT
    category_id,
    category_name,
    subcategory_id,
    subcategory_name,
    purchase_count,
    repurchase_rate,
    avg_rating,
    good_sentiment_ratio,
    review_count,
    final_rank
FROM
    FinalRanking
ORDER BY
    category_id, final_rank;


## 4) 서브카테고리 내 품목 정보 제공(평점, 리뷰수, 감성분석, 재구매율 등)
WITH CustomerPurchaseCounts AS (
    SELECT
        oi.product_id,
        o.customer_id,
        COUNT(*) AS purchase_count
    FROM
        orders o
        JOIN orderitem oi ON o.order_id = oi.order_id
    GROUP BY
        oi.product_id, o.customer_id
),
RepurchasingCustomers AS (
    SELECT
        product_id,
        COUNT(*) AS repurchasing_customers
    FROM
        CustomerPurchaseCounts
    WHERE
        purchase_count > 1
    GROUP BY
        product_id
),
TotalCustomers AS (
    SELECT
        product_id,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM
        orders o
        JOIN orderitem oi ON o.order_id = oi.order_id
    GROUP BY
        product_id
),
ProductMetrics AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        s.subcategory_name,
        tc.total_customers,
        COALESCE(rc.repurchasing_customers, 0) AS repurchasing_customers,
        -- 재구매율 계산: 두 번 이상 구매한 고객 수 / 총 구매한 고객 수
        COALESCE(rc.repurchasing_customers, 0) * 1.0 / NULLIF(tc.total_customers, 0) AS repurchase_rate,
        AVG(pr.ratings) AS avg_rating,
        COUNT(pr.review) AS review_count,
        SUM(CASE WHEN pr.sentiment = 'good' THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(pr.sentiment), 0) AS good_sentiment_ratio
    FROM
        product p
        JOIN subcategory s ON p.subcategory_id = s.subcategory_id
        JOIN TotalCustomers tc ON p.product_id = tc.product_id
        LEFT JOIN RepurchasingCustomers rc ON p.product_id = rc.product_id
        LEFT JOIN customer_product_ratings pr ON p.product_id = pr.product_id
    GROUP BY
        p.product_id, s.subcategory_name, tc.total_customers, rc.repurchasing_customers
)
SELECT
    product_id,
    product_name,
    subcategory_name,
    total_customers,
    repurchasing_customers,
    repurchase_rate,
    avg_rating,
    review_count,
    good_sentiment_ratio
FROM
    ProductMetrics
ORDER BY
    product_id;






