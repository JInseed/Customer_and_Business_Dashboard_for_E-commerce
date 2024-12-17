# 환불 분석

# 0) 환불 이유
SELECT
    reason,
    COUNT(*) AS total_refund_count
FROM
    returns
GROUP BY
    reason
ORDER BY
    total_refund_count DESC;


# 1) 지역별 환불분석
## 환불 많은 나라 상위 5개별 환불 이유 상위 5개

WITH CountryRefunds AS (
    SELECT
        c.country,
        r.reason,
        COUNT(*) AS refund_count,
        (SELECT COUNT(*) FROM returns r2
         JOIN orders o2 ON r2.order_id = o2.order_id
         JOIN customer c2 ON o2.customer_id = c2.customer_id
         WHERE c2.country = c.country) AS total_refunds_per_country
    FROM
        returns r
        JOIN orders o ON r.order_id = o.order_id
        JOIN customer c ON o.customer_id = c.customer_id
    GROUP BY
        c.country, r.reason
),
TotalCountryRefunds AS (
    SELECT
        country,
        SUM(refund_count) AS total_refunds
    FROM
        CountryRefunds
    GROUP BY
        country
    ORDER BY
        total_refunds DESC
    LIMIT 5
),
TopCountries AS (
    SELECT DISTINCT
        country
    FROM
        TotalCountryRefunds
),
RankedRefunds AS (
    SELECT
        cr.country,
        cr.reason,
        cr.refund_count,
        cr.total_refunds_per_country,
        ROW_NUMBER() OVER (PARTITION BY cr.country ORDER BY cr.refund_count DESC) AS ranking
    FROM
        CountryRefunds cr
    WHERE
        cr.country IN (SELECT country FROM TopCountries)
)
SELECT
    country,
    reason,
    refund_count,
    total_refunds_per_country
FROM
    RankedRefunds
WHERE
    ranking <= 5 
ORDER BY
    total_refunds_per_country DESC, country, ranking;

    
# 2) 환불율 분석

## 카테고리별 환불율, 서브카테고리별 환불율, 상품별 환불율 결합
WITH ProductDetails AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        sc.subcategory_id,
        sc.subcategory_name,
        c.category_id,
        c.category_name
    FROM
        product p
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category c ON sc.category_id = c.category_id
),
SalesData AS (
    SELECT
        oi.product_id,
        COUNT(oi.order_id) AS total_sales -- 총 판매 횟수
    FROM
        orderitem oi
    GROUP BY
        oi.product_id
),
RefundData AS (
    SELECT
        r.product_id,
        COUNT(r.return_id) AS total_refunds -- 총 환불 횟수
    FROM
        returns r
    GROUP BY
        r.product_id
),
ProductRefundRate AS (
    SELECT
        pd.product_id,
        pd.product_name,
        pd.subcategory_id,
        pd.subcategory_name,
        pd.category_id,
        pd.category_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_refunds, 0) AS total_refunds,
        COALESCE(rd.total_refunds, 0) * 1.0 / GREATEST(COALESCE(sd.total_sales, 1), 1) AS product_refund_rate
    FROM
        ProductDetails pd
        LEFT JOIN SalesData sd ON pd.product_id = sd.product_id
        LEFT JOIN RefundData rd ON pd.product_id = rd.product_id
),
SubcategoryAggregates AS (
    SELECT
        subcategory_id,
        subcategory_name,
        SUM(total_sales) AS subcategory_total_sales,
        SUM(total_refunds) AS subcategory_total_refunds,
        SUM(total_refunds) * 1.0 / GREATEST(SUM(total_sales), 1) AS subcategory_refund_rate
    FROM
        ProductRefundRate
    GROUP BY
        subcategory_id
),
CategoryAggregates AS (
    SELECT
        category_id,
        category_name,
        SUM(total_sales) AS category_total_sales,
        SUM(total_refunds) AS category_total_refunds,
        SUM(total_refunds) * 1.0 / GREATEST(SUM(total_sales), 1) AS category_refund_rate
    FROM
        ProductRefundRate
    GROUP BY
        category_id
)
SELECT
    prr.product_id,
    prr.subcategory_id,
    prr.category_id,
    prr.product_name,
    prr.subcategory_name,
    prr.category_name,
    prr.total_sales,
    prr.total_refunds,
    sa.subcategory_total_sales,
    sa.subcategory_total_refunds,
    ca.category_total_sales,
    ca.category_total_refunds,
    prr.product_refund_rate,
    sa.subcategory_refund_rate,
    ca.category_refund_rate
FROM
    ProductRefundRate prr
    JOIN SubcategoryAggregates sa ON prr.subcategory_id = sa.subcategory_id
    JOIN CategoryAggregates ca ON prr.category_id = ca.category_id
ORDER BY
    ca.category_refund_rate DESC, sa.subcategory_refund_rate DESC, prr.product_refund_rate DESC;


## 이상 상품 찾기, 서브 카테고리별 환불율 평균과 표준편차를 구한 후 상품 환불율이 일정 표준편차보다 높은 상품을 이상 상품으로 정의, 10개 나오도록 임의로 구함
WITH ProductDetails AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        sc.subcategory_id,
        sc.subcategory_name,
        c.category_id,
        c.category_name
    FROM
        product p
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category c ON sc.category_id = c.category_id
),
SalesData AS (
    SELECT
        oi.product_id,
        COUNT(*) AS total_sales -- 총 판매 횟수
    FROM
        orderitem oi
    GROUP BY
        oi.product_id
),
RefundData AS (
    SELECT
        r.product_id,
        COUNT(*) AS total_refunds -- 총 환불 횟수
    FROM
        returns r
    GROUP BY
        r.product_id
),
ProductRefundRate AS (
    SELECT
        pd.product_id,
        pd.product_name,
        pd.subcategory_id,
        pd.subcategory_name,
        pd.category_id,
        pd.category_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_refunds, 0) AS total_refunds,
        COALESCE(rd.total_refunds, 0) * 1.0 / GREATEST(COALESCE(sd.total_sales, 1), 1) AS product_refund_rate
    FROM
        ProductDetails pd
        LEFT JOIN SalesData sd ON pd.product_id = sd.product_id
        LEFT JOIN RefundData rd ON pd.product_id = rd.product_id
),
SubcategoryStats AS (
    SELECT
        subcategory_id,
        AVG(product_refund_rate) AS avg_refund_rate,
        STD(product_refund_rate) AS stddev_refund_rate
    FROM
        ProductRefundRate
    GROUP BY
        subcategory_id
),
HighRefundProducts AS (
    SELECT
        prr.product_id,
        prr.product_name,
        prr.subcategory_id,
        prr.subcategory_name,
        prr.category_id,
        prr.category_name,
        prr.total_sales,
        prr.total_refunds,
        prr.product_refund_rate,
        ss.avg_refund_rate,
        ss.stddev_refund_rate
    FROM
        ProductRefundRate prr
        JOIN SubcategoryStats ss ON prr.subcategory_id = ss.subcategory_id
    WHERE
        prr.product_refund_rate > (ss.avg_refund_rate + ss.stddev_refund_rate * 1.837)
)
SELECT
    *
FROM
    HighRefundProducts
ORDER BY
    product_refund_rate DESC
;

# 3. 상품별  상위 5개 환불이유
WITH ProductDetails AS (
    -- 상품 및 카테고리 정보
    SELECT
        p.product_id,
        p.name AS product_name,
        sc.subcategory_id,
        sc.subcategory_name,
        c.category_id,
        c.category_name
    FROM
        product p
        JOIN subcategory sc ON p.subcategory_id = sc.subcategory_id
        JOIN category c ON sc.category_id = c.category_id
),
SalesData AS (
    -- 상품별 총 판매 횟수
    SELECT
        oi.product_id,
        COUNT(*) AS total_sales
    FROM
        orderitem oi
    GROUP BY
        oi.product_id
),
RefundData AS (
    -- 상품별 총 환불 횟수
    SELECT
        r.product_id,
        COUNT(*) AS total_refunds
    FROM
        returns r
    GROUP BY
        r.product_id
),
ProductRefundRate AS (
    -- 상품별 환불율 계산
    SELECT
        pd.product_id,
        pd.product_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_refunds, 0) AS total_refunds,
        COALESCE(rd.total_refunds, 0) * 1.0 / GREATEST(COALESCE(sd.total_sales, 1), 1) AS product_refund_rate
    FROM
        ProductDetails pd
        LEFT JOIN SalesData sd ON pd.product_id = sd.product_id
        LEFT JOIN RefundData rd ON pd.product_id = rd.product_id
    WHERE
        COALESCE(rd.total_refunds, 0) * 1.0 / GREATEST(COALESCE(sd.total_sales, 1), 1) > 0 -- 환불율이 있는 상품만 선택
),
RefundReasons AS (
    -- 상품별 환불 이유 및 환불 횟수
    SELECT
        r.product_id,
        r.reason,
        COUNT(*) AS refund_count
    FROM
        returns r
        JOIN ProductRefundRate prr ON r.product_id = prr.product_id
    GROUP BY
        r.product_id, r.reason
),
RankedRefundReasons AS (
    -- 상품별 환불 이유별 랭킹
    SELECT
        rr.product_id,
        rr.reason,
        rr.refund_count,
        prr.total_refunds AS product_total_refunds,
        ROW_NUMBER() OVER (PARTITION BY rr.product_id ORDER BY rr.refund_count DESC) AS reason_rank
    FROM
        RefundReasons rr
        JOIN ProductRefundRate prr ON rr.product_id = prr.product_id
)
SELECT
    rrr.product_id,
    prr.product_name,
    rrr.reason,
    rrr.refund_count,
    rrr.product_total_refunds
FROM
    RankedRefundReasons rrr
    JOIN ProductRefundRate prr ON rrr.product_id = prr.product_id
WHERE
    rrr.reason_rank <= 5
ORDER BY
    rrr.product_id, rrr.reason_rank;
