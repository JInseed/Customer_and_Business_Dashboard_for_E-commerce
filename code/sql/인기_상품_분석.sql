# 인기 상품 분석

# 1. 카테고리별 상위 5개 인기상품 
WITH ranked_products AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        s.category_id,
        c.category_name,
        COUNT(oi.orderitem_id) AS total_sold,
        ROW_NUMBER() OVER(PARTITION BY s.category_id ORDER BY COUNT(oi.product_id) DESC) AS rank_num
    FROM
        product p
    JOIN
        orderitem oi ON p.product_id = oi.product_id
    JOIN
        subcategory s ON p.subcategory_id = s.subcategory_id
    JOIN
        category c ON s.category_id = c.category_id
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM public.returns r
            WHERE r.order_id = oi.order_id
            AND r.product_id = oi.product_id
        )
    GROUP BY
        p.product_id, p.name, s.category_id, c.category_name
)
SELECT
    category_id,
    category_name,
    product_name,
    total_sold,
    rank_num
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY category_id ORDER BY rank_num) AS category_rank
    FROM
        ranked_products
) ranked_products_with_category_rank
WHERE
    category_rank <= 5
ORDER BY
    category_id, category_rank;
    
    
# 2. 매출 상위 10개 나라별 상위 3개 인기상품

WITH top_selling_countries AS (
    SELECT
        c.country,
        SUM(oi.quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    JOIN 
        orderitem oi ON o.order_id = oi.order_id
    JOIN 
        product p ON oi.product_id = p.product_id
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM returns r
            WHERE r.order_id = oi.order_id
            AND r.product_id = oi.product_id
        )
    GROUP BY 
        c.country
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
, top_selling_products AS (
    SELECT
        c.country,
        p.name AS product_name,
        SUM(oi.quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    JOIN 
        orderitem oi ON o.order_id = oi.order_id
    JOIN 
        product p ON oi.product_id = p.product_id
    WHERE
        c.country IN (SELECT country FROM top_selling_countries)
        AND NOT EXISTS (
            SELECT 1
            FROM returns r
            WHERE r.order_id = oi.order_id
            AND r.product_id = oi.product_id
        )
    GROUP BY 
        c.country, p.product_id, p.name
),
ranked_products AS (
    SELECT 
        country,
        product_name,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_quantity DESC) AS rank_num1,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_quantity DESC) AS category_rank
    FROM 
        top_selling_products
)
SELECT 
    country,
    product_name,
    total_quantity,
    category_rank
FROM 
    ranked_products
WHERE 
    rank_num1 <= 3
ORDER BY
    country, rank_num1;

    
   
    

