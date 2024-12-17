# 캠페인 분석


# 0. 캠페인별 판매 데이터 현황, 할인 적용, 총 판매 데이터 , 마케팅 진행 기간 생성 CTE

## 주문 데이터 할인 적용
/*
-- product 판매 관련
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
*/
### 마케팅 진행기간 구하기
/*
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
), campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	-- WHERE campaign_start_date LIKE '2022-%-%'
	GROUP BY 3, 1, 2
	ORDER BY 3
)
*/

# 1. 마케팅 진행 유무에 따른 판매량 비교
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
)
SELECT campaign_id, SUM(per_campaign_total) as campaign_total
FROM (
    SELECT 
        campaign_id, 
        campaign_start_date, 
        SUM(total_discounted) as per_campaign_total
    FROM campaign_has_start_date
    GROUP BY 1, 2
) as campaigns_summarized
GROUP BY 1
ORDER BY 1;


# 2. 연도별, 마케팅별 매출액
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
)
SELECT campaign_id, campaign_start_date, SUM(per_campaign_total) as campaign_total
FROM (
    SELECT 
        campaign_id, 
        campaign_start_date, 
        SUM(total_discounted) as per_campaign_total
    FROM campaign_has_start_date 
    # WHERE campaign_start_date LIKE '2016-%-%' # 연도 설정
    GROUP BY 1, 2
) as campaigns_summarized
GROUP BY 1, 2
ORDER BY 1
;


# 3. 마케팅, 연도별 매출액
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
)
SELECT campaign_id, campaign_start_date, SUM(per_campaign_total) as campaign_total
FROM (
    SELECT 
        campaign_id, 
        campaign_start_date, 
        SUM(total_discounted) as per_campaign_total
    FROM campaign_has_start_date
    WHERE campaign_id = 1 # 여기만 바꿔주면 됨
    GROUP BY 1, 2
) as campaigns_summarized
GROUP BY 1, 2
ORDER BY 1;


# 4. 캠페인 중 인기 많은 서브 카테고리

## 연도 상관 없이 마케팅 별 가장 많이 팔린 서브 카테고리
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
),
product_has_subcategory_name as (
	SELECT p.product_id as product_id, p.subcategory_id as subcategory_id, s.subcategory_name as subcategory_name
	FROM PRODUCT p INNER JOIN SUBCATEGORY s ON p.subcategory_id = s.subcategory_id
)
-- 캠페인 기간 중 가장 잘 팔린 서브 카테고리 표시
, product_subcategory_has_order_date as (
	SELECT 
		oihd.campaign_id as campaign_id, 
        phs.subcategory_name as subcategory_name, 
        oihd.order_date as order_date, 
        oihd.discounted_subtotal as discounted_subtotal
	FROM product_has_subcategory_name phs INNER JOIN oi_has_discounted_subtotal oihd ON phs.product_id = oihd.product_id
	ORDER BY 1
)
SELECT DISTINCT campaign_id, subcategory_name, discounted_subtotal, order_date
FROM product_subcategory_has_order_date
WHERE 1=1
AND campaign_id != 17
AND campaign_id = 1 # 여기만 1~16으로 바꿔주면 됨
GROUP BY 1, 2, 3, 4
ORDER BY 3 DESC
LIMIT 5
;

## 연도에 따라 세부적으로 많이 팔린 서브 카테고리
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
),
product_has_subcategory_name as (
	SELECT p.product_id as product_id, p.subcategory_id as subcategory_id, s.subcategory_name as subcategory_name
	FROM PRODUCT p INNER JOIN SUBCATEGORY s ON p.subcategory_id = s.subcategory_id
)
-- 캠페인 기간 중 가장 잘 팔린 서브 카테고리 표시
, product_subcategory_has_order_date as (
	SELECT 
		oihd.campaign_id as campaign_id, 
        phs.subcategory_name as subcategory_name, 
        oihd.order_date as order_date, 
        oihd.discounted_subtotal as discounted_subtotal
	FROM product_has_subcategory_name phs INNER JOIN oi_has_discounted_subtotal oihd ON phs.product_id = oihd.product_id
	ORDER BY 1
)
SELECT chs.campaign_id as campaign_id, chs.campaign_start_date as campaign_start_date, psho.subcategory_name, SUM(chs.total_discounted) as total_discounted
FROM campaign_has_start_date chs INNER JOIN product_subcategory_has_order_date psho ON chs.order_date = psho.order_date
WHERE 1=1
AND psho.campaign_id != 17
AND psho.campaign_id = 1
AND chs.campaign_start_date LIKE '2016-%-%'
GROUP BY 1, 2, 3
ORDER BY 4 DESC
LIMIT 5
;


# 5. 대시보드에 넣기 위한 테이블 작성

## 주차별 마케팅 유무에 따른 판매량과 매출액
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
),
product_has_subcategory_name as (
	SELECT p.product_id as product_id, p.subcategory_id as subcategory_id, s.subcategory_name as subcategory_name
	FROM PRODUCT p INNER JOIN SUBCATEGORY s ON p.subcategory_id = s.subcategory_id
)
-- 캠페인 기간 중 가장 잘 팔린 서브 카테고리 표시
, product_subcategory_has_order_date as (
	SELECT 
		oihd.campaign_id as campaign_id, 
        phs.subcategory_name as subcategory_name, 
        oihd.order_date as order_date, 
        oihd.discounted_subtotal as discounted_subtotal
	FROM product_has_subcategory_name phs INNER JOIN oi_has_discounted_subtotal oihd ON phs.product_id = oihd.product_id
	ORDER BY 1
)
-- 17번에 있는 캠페인이 아닌 기간을 "월단위 -> 주단위" 로 세분화 시키기
SELECT *
FROM campaign_has_amount_per_week


## 마케팅별 판매량 상위 5개
WITH oi_has_product_price as (
	SELECT
		oi.product_id as product_id, 
        oi.order_id,
        SUM(oi.quantity) as quantity, 
        ROUND(AVG(p.price), 2) as price, 
        SUM(oi.subtotal) as subtotal, 
        SUM(CASE
				WHEN oi.discount != 0 THEN oi.subtotal*(1-oi.discount)
                ELSE oi.subtotal
			END) as discounted_subtotal
	FROM ORDERITEM oi INNER JOIN PRODUCT p ON oi.product_id = p.product_id
    GROUP BY 1, 2
)
, o_has_campaign_name as (
	SELECT 
		o.amount as amount,
        o.order_date as order_date, 
        o.campaign_id as campaign_id, 
        mc.campaign_name as campaign_name,
        o.order_id as order_id
    FROM ORDERS o INNER JOIN MARKETING_CAMPAIGNS mc ON o.campaign_id = mc.campaign_id
)-- product 판매 관련
, oi_has_discounted_subtotal as (
	SELECT 
		oih.order_id as order_id, 
        ohc.amount as amount, 
        ohc.order_date as order_date,
        oih.product_id as product_id,
        oih.discounted_subtotal as discounted_subtotal, 
        oih.quantity as quantity,
        ohc.campaign_id as campaign_id,
        ohc.campaign_name as campaign_name
	FROM oi_has_product_price oih INNER JOIN o_has_campaign_name ohc ON oih.order_id = ohc.order_id
	GROUP BY 1, 2, 3, 4, oih.discounted_subtotal, 7, 8
)
-- 마케팅별 2016~2022년까지의 총 매출액
, campaign_has_start_date as (
SELECT mc.campaign_id, ohd.order_date, ohd.campaign_name, ohd.quantity as quantity,
	CASE
		WHEN mc. campaign_id = 17 
        THEN 
			-- 주차별로 나누기 위한 목적
			CASE 
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
                ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
        ELSE
			CASE
			-- DAYOFWEEK()가 일요일을 시작으로 해당 주를 계산하기 때문에, 월요일을 시작 날짜로 하고 싶으면 일요일에 이전 주차를 가져오는 분기처리가 필요함
				WHEN DAYOFWEEK(ohd.order_date) = 1 THEN DATE_SUB(ohd.order_date, INTERVAL 6 DAY)
				ELSE DATE_SUB(ohd.order_date, INTERVAL (DAYOFWEEK(ohd.order_date)-2) % 7 DAY) 
			END
	END as campaign_start_date,
	CASE
        WHEN mc.campaign_id = 17 THEN 'NONE'
        ELSE 'CAMPAIGN'
    END as is_campaign,
    ROUND(SUM(ohd.discounted_subtotal)) as total_discounted
FROM MARKETING_CAMPAIGNS mc INNER JOIN oi_has_discounted_subtotal ohd ON mc.campaign_id = ohd.campaign_id
GROUP BY 1, 2, 3, 4
ORDER BY campaign_id, order_date
),
campaign_has_amount_per_week as (
	SELECT campaign_id, campaign_name, campaign_start_date, SUM(quantity) as quantity, SUM(total_discounted) as campaign_total
	FROM campaign_has_start_date
	GROUP BY 3, 1, 2
	ORDER BY 3
),
product_has_subcategory_name as (
	SELECT p.product_id as product_id, p.subcategory_id as subcategory_id, s.subcategory_name as subcategory_name
	FROM PRODUCT p INNER JOIN SUBCATEGORY s ON p.subcategory_id = s.subcategory_id
)
-- 캠페인 기간 중 가장 잘 팔린 서브 카테고리 표시
, product_subcategory_has_order_date as (
	SELECT 
		oihd.campaign_id as campaign_id, 
        phs.subcategory_name as subcategory_name, 
        oihd.order_date as order_date, 
        oihd.discounted_subtotal as discounted_subtotal
	FROM product_has_subcategory_name phs INNER JOIN oi_has_discounted_subtotal oihd ON phs.product_id = oihd.product_id
	ORDER BY 1
), 
ranked_campaign_with_start_date as (
	SELECT 
		chs.campaign_id as campaign_id, 
		chs.campaign_name as campaign_name,
		chs.campaign_start_date as campaign_start_date, 
		psho.subcategory_name as subcategory_name,
		SUM(chs.total_discounted) as total_discounted,
        ROW_NUMBER() OVER (PARTITION BY chs.campaign_start_date ORDER BY SUM(chs.total_discounted) DESC) as amount_rank
	FROM campaign_has_start_date chs INNER JOIN product_subcategory_has_order_date psho ON chs.order_date = psho.order_date
	WHERE 1=1
	AND psho.campaign_id != 17
	GROUP BY 1, 2, 3, 4
)
SELECT campaign_id, 
    campaign_name,
    campaign_start_date, 
    subcategory_name,
    total_discounted, 
    amount_rank
FROM ranked_campaign_with_start_date
WHERE amount_rank <= 5
ORDER BY 3, 5 DESC






