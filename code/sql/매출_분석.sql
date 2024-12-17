# 매출 분석

# 1. 국가별 매출
-- 리턴된 오더는 orders에서 제외
-- 할인된 가격으로 총 매출액 산정 
-- 나라 이름으로 group by

-- real_orderitem = 리턴된 row는 제거한 테이블
with real_orderitem as (
	select
			orderitem.*
	from
			orderitem
	left join
	 		returns on orderitem.order_id = returns.order_id
	and
			orderitem.product_id = returns.product_id
	where
			returns.return_id is null
),
real_orderitem as (
	select *,
			  (subtotal) * (1 - discount) as real_price #할인된 가격 컬럼 추가
	from 
			 real_orderitem
)
select straight_join
    c.country,
    sum(real_price) as total_sales
from 
    customer c
join 
    orders o on c.customer_id = o.customer_id
join 
    real_orderitem oi on o.order_id = oi.order_id
join 
    product p on oi.product_id = p.product_id
group by 
    country
order by 
    2 desc;


# 2. 카테고리별 판매량 상위 3개 국가
with real_orderitem as (
	select
			orderitem.*
	from
			orderitem
	left join
	 		returns on orderitem.order_id = returns.order_id
	and
			orderitem.product_id = returns.product_id
	where
			returns.return_id is null
),
category_sales as (
    select straight_join
        cate.category_name,
        c.country,
        sum(oi.quantity) as total_quantity
    from 
        customer c
    join 
        orders o on c.customer_id = o.customer_id
    join
        real_orderitem oi on o.order_id = oi.order_id
    join 
        product p on oi.product_id = p.product_id
    join 
		    subcategory sub on p.subcategory_id = sub.subcategory_id
		join 
				category cate on sub.category_id = cate.category_id 
    group by 
        cate.category_name, c.country
),
ranked_sales as (
    select straight_join
        category_name,
        country,
        total_quantity,
        ROW_NUMBER() over (partition by category_name order by total_quantity desc) as ranking
    from 
        category_sales
)
select 
    category_name,
    country,
    total_quantity
from 
    ranked_sales
where 
    ranking <= 3;
    
    
# 3. 연도, 분기, 월별 매출
with real_orderitem as (
	select
			orderitem.*
	from
			orderitem
	left join
	 		returns on orderitem.order_id = returns.order_id
	and
			orderitem.product_id = returns.product_id
	where
			returns.return_id is null
),
real_orderitem as (
	select *,
			  (subtotal) * (1 - discount) as real_price
	from 
			 real_orderitem
)
# 연도별 매출
select straight_join
    EXTRACT(YEAR FROM o.order_date) as order_year,
    SUM(oi.real_price) as total_sales
from 
    orders o
join 
    real_orderitem oi on o.order_id = oi.order_id
join 
    product p on oi.product_id = p.product_id
group by 
    EXTRACT(YEAR FROM o.order_date)
order by 
    order_year;

-- 분기별 매출
with real_orderitem as (
	select
			orderitem.*
	from
			orderitem
	left join
	 		returns on orderitem.order_id = returns.order_id
	and
			orderitem.product_id = returns.product_id
	where
			returns.return_id is null
),
real_orderitem as (
	select *,
			  (subtotal) * (1 - discount) as real_price
	from 
			 real_orderitem
)
 select straight_join 
    EXTRACT(YEAR FROM o.order_date) as order_year,
    CEIL(EXTRACT(MONTH FROM o.order_date) / 3) as quarter,
    SUM(oi.real_price) as total_sales
from 
    orders o
join 
    real_orderitem oi on o.order_id = oi.order_id
join 
    product p on oi.product_id = p.product_id
group by 
    EXTRACT(YEAR FROM o.order_date),
    quarter
order by 
    1,2;


# 월별 매출
with real_orderitem as (
	select
			orderitem.*
	from
			orderitem
	left join
	 		returns on orderitem.order_id = returns.order_id
	and
			orderitem.product_id = returns.product_id
	where
			returns.return_id is null
),
real_orderitem as (
	select *,
			  (subtotal) * (1 - discount) as real_price
	from 
			 real_orderitem
)
select straight_join 
    EXTRACT(YEAR FROM o.order_date) as order_year,
    EXTRACT(MONTH FROM o.order_date) as order_month,
    SUM(oi.real_price) as total_sales
from 
    orders o
join 
    real_orderitem oi on o.order_id = oi.order_id
join 
    product p on oi.product_id = p.product_id
group by 
    1,2
order by 
    1,2

