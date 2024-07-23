--Таблица "users" с полями: id, name, email, created_at
--Таблица "orders" с полями: id, user_id, total_price, created_at
--Таблица "order_items" с полями: id, order_id, product_name, price, quantity
--HAPPY GAMES
--В ответе пришлите имя и версию используемой бд, дамп структуры базы, а также запросы для заполнения тестовыми данными, 
--в работе строк должно быть не менее 1 млн в каждой таблице.
--Ответ должен представлять из себя SQL запрос с пояснением. По желанию можете дополнить ваш ответ плохим вариантом запроса также с объяснением.
--
--Запросы:
--1.	Найти общее количество заказов каждого пользователя, который сделал более 10 заказов.
--2.	Найти средний размер заказа для каждого пользователя за последний месяц.
--3.	Найти средний размер заказа за каждый месяц в текущем году и сравнить его с средним размером заказа за соответствующий месяц в прошлом году.
--4.	Найти 10 пользователей, у которых наибольшее количество заказов за последний год, и для каждого из них найти средний размер заказа за последний месяц.

--1
with t as(
select u.name,  count(o.id) as total_orders, u.id
from 
	users1 u 
left join 
	orders1 o 
		on u.id = o.user_id 
group by u.id, u.name 
order by u.id asc)

select *
from t 
where total_orders > 10

--2
WITH t AS (
    SELECT
        u.name,
        u.id,
        oi.order_id,
        (oi.price * oi.quantity) AS cost_u,
        o.created_at
    FROM
        users1 u
    LEFT JOIN
        orders1 o ON u.id = o.user_id
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    WHERE
        o.created_at >= DATE_TRUNC('month', CURRENT_DATE) AND
        o.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
)
SELECT
    t.name,
    t.id AS user_id,
    AVG(cost_u) AS avg_order_cost,
    t.created_at
FROM
    t
GROUP BY
    t.name, t.id, t.created_at
ORDER BY
    t.name;


--3.	Найти средний размер заказа за каждый месяц в текущем году и сравнить его с средним размером заказа за соответствующий месяц в прошлом году.

WITH t AS (
    SELECT
        oi.order_id,
        (oi.price * oi.quantity) AS cost_u,
        o.created_at
    FROM
        orders1 o 
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    where
    	o.created_at >= DATE_TRUNC('year', CURRENT_DATE) AND
        o.created_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
)
SELECT
    DATE_TRUNC('month', k.created_at) as mnt,
    AVG(cost_u) AS avg_order_cost
FROM
    t
GROUP BY
    mnt


with k as (
 SELECT
        oi.order_id,
        (oi.price * oi.quantity) AS cost_u,

        EXTRACT(MONTH FROM o.created_at) as month
    FROM
        orders1 o 
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    where
    	 o.created_at >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year' 
    	 AND o.created_at < DATE_TRUNC('year', CURRENT_DATE)
    	 )
select 
	month, avg(k.cost_u) as avg_month
FROM
    k
where month = 7
group by month






WITH current_year AS (
    SELECT
        DATE_TRUNC('month', o.created_at) AS month,
        AVG(oi.price * oi.quantity) AS avg_order_cost_current_year
    FROM
        orders1 o
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    WHERE
        o.created_at >= DATE_TRUNC('year', CURRENT_DATE)
        AND o.created_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
    GROUP BY
        DATE_TRUNC('month', o.created_at)
),
previous_year AS (
    SELECT
        DATE_TRUNC('month', o.created_at) AS month,
        AVG(oi.price * oi.quantity) AS avg_order_cost_previous_year
    FROM
        orders1 o
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    WHERE
        o.created_at >= DATE_TRUNC('year', CURRENT_DATE - INTERVAL '1 year')
        AND o.created_at < DATE_TRUNC('year', CURRENT_DATE)
    GROUP BY
        DATE_TRUNC('month', o.created_at)
)

SELECT
    TO_CHAR(cy.month, 'Month') AS month_name,
    cy.avg_order_cost_current_year,
    py.avg_order_cost_previous_year
FROM
    current_year cy
LEFT JOIN
    previous_year py ON cy.month = py.month
ORDER BY
    cy.month;

   
--4.	Найти 10 пользователей, у которых наибольшее количество заказов за последний год, и для каждого из них найти средний размер заказа за последний месяц.

WITH t AS (
    SELECT
        u.name,
        u.id as user_id,
        oi.order_id,
        (oi.price * oi.quantity) AS cost_u,
        o.created_at
    FROM
        users1 u
    LEFT JOIN
        orders1 o ON u.id = o.user_id
    LEFT JOIN
        order_items1 oi ON o.id = oi.order_id
    WHERE
        o.created_at >= DATE_TRUNC('year', CURRENT_DATE) AND
        o.created_at < DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year'
),

k as (SELECT
    t.name,
    t.user_id,
    count(distinct t.order_id) AS total
FROM
    t
GROUP BY
    t.name, t.user_id
ORDER BY
    total desc
limit 10
),
recent_orders as (
	select 
		k.name, k.user_id, t.cost_u, t.created_at
	from k
	left join 
		t on t.user_id = k.user_id
	where 
	 t.created_at >= DATE_TRUNC('month', CURRENT_DATE) AND
     t.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')
select 
	ro.name, ro.user_id, avg(ro.cost_u)
from 
	recent_orders ro 
group by ro.name, ro.user_id
   
   