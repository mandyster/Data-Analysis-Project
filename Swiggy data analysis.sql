
--checking data of the tables

select * from food;
select * from menu;
select * from orders;
select * from restraunts;
select * from users;
select * from order_details;
select * from delivery_partners;

--Analysis

--1. Find customers who have never ordered

SELECT 
	user_id 
	from users
	where not user_id in 
					(
					Select 
					distinct user_id 
					from orders
					)


--2. Average Price/dish

SELECT 
	f.f_name, 
	avg(price) as Avg_price
	from menu m
	join
	food f on m.f_id = f.f_id
	group by m.f_id, f.f_name
	order by 2 desc


--3. Find the top restaurant in terms of the number of orders for a given month

drop procedure if exists top_restraunt

create procedure top_restraunt @month_id int
as
begin
select * from (select
	o.r_id,
	r.r_name,
	r.cuisine,
	month(o.date) as month_id,
	count(o.order_id) as Total_orders,
	sum(amount) as total_amount, 
	ntile(4)over(order by count(o.order_id) desc) as rnk_order,
	ntile(4)over(order by sum(o.order_id) desc ) as rnk_amount
	from orders o
	join restraunts r on r.r_id=o.r_id
	group by 
	o.r_id, 
	r.r_name, 
	r.cuisine, 
	month(o.date)
	) as cte
where month_id = @month_id
order by 6 desc
end

--EXECUTE THIS STORE PRECEDURE TO GET THE TOP_RESTRAUNT OF THAT MONTH

 exec top_restraunt @month_id =06 --CHANGE MONTH_ID


--4. restaurants with monthly sales greater than x for 

drop procedure if exists top_restraunts_monthly_revenue 

CREATE PROCEDURE top_restraunts_monthly_revenue
@month_id int, --month to be checked
@value int   -- restraunt having revenue greater that this value
as
begin
select
	o.r_id,
	r.r_name,
	month(o.date) as month_id,
	sum(o.amount) as total_sales
	from orders o
	join restraunts r on r.r_id=o.r_id  
	where month(o.date)=@month_id		--change month id to get the Top Restraunt details of that month							
	group by 
		o.r_id, 
		r.r_name, 
		month(o.date)
	having sum(o.amount) > @value  -- change value to compare accordingly
	order by 4 desc
end;

--EXECUTE THIS STORE PRECEDURE TO GET THE TOP_RESTRAUNT IN DIFFERENT @MONTH_ID HAVING TOTAL SALES GREATER THAT @VALUE

exec top_restraunts_monthly_revenue @month_id= 7, @value=1000 -- CHANGE TO GET DIFFERENT OUTPUT


--5. Show all orders with order details for a particular customer in a particular date range

--EXECUTE THIS STORE PRECEDURE TO GET all orders with order details for a particular customer @name in a particular date range @startdate, @enddate


DROP PROCEDURE order_details_between_a_range_of_dates;
CREATE PROCEDURE order_details_between_a_range_of_dates @startdate date, @enddate date, @name varchar(255)
as
begin
	select 
	o.order_id,
	r.r_name,
	o.date,
	o.amount
	from orders o 
	join restraunts r on r.r_id = o.r_id
	join users u on u.user_id= o.user_id
	where date between @startdate and @enddate 
	and u.name = @name
end;

exec order_details_between_a_range_of_dates @startdate='2022-06-15', @enddate='2022-07-15', @name = 'Nitish' 



--6. Find restaurants with max repeated customers / Loyal customers  

with rep_cus as 
(select
	r.r_id,
	r.r_name,
	u.user_id,
	u.name,
	u.email, 
	o.total_orders
	from restraunts r
	join 
		(select   
			distinct count(user_id)over(partition by user_id, r_id) as total_orders, *
		from orders
		) as o 
	on r.r_id = o.r_id 
	join users u 
	on u.user_id = o.user_id 
	where o.total_orders = 3
)
,
--Details of loyal Customers
loyal_customers as 
(select 
	distinct r_id, 
	r_name, 
	User_id, 
	name as Loyal_Customer, 
	email, 
	total_orders 
from rep_cus 
)
--restraunt with the max_reapeated customers

select 
top 1 
r_name as Restraunt_name, 
count(*) as 'Total_loyal_Customers' 
from loyal_customers 
group by r_name
order by Total_loyal_Customers desc


/**** ALTERNATE SOLUTION****/


with rep_cus as 
(select
	r.r_id,
	r.r_name,
	u.user_id,
	u.name,
	u.email, 
	count(o.order_id) as total_orders,
	dense_rank()over(partition by u.user_id order by count(o.order_id) desc) as 'Rank'
	from restraunts r
	join 
    orders as o 
	on r.r_id = o.r_id 
	join users u 
	on u.user_id = o.user_id 
	group by
	r.r_id,
	r.r_name,
	u.user_id,
	u.name,
	u.email
)
,
--Details of loyal Customers

loyal_customers as 
(select 
	r_id, 
	r_name, 
	User_id, 
	name as Loyal_Customer, 
	email, 
	total_orders 
from rep_cus 
where rank = 1
)
--restraunt with the max_reapeated customers

select 
top 1 
r_name as Restraunt_name, 
count(*) as 'Total_loyal_Customers' 
from loyal_customers 
group by r_name
order by Total_loyal_Customers desc



--7. Month over month revenue growth of swiggy
--EXECUTE THE STORED PROCEDURE TO GET THE MONTHLY REVENUE PERCENTAGE GROWTH IN A YEAR @YEAR

DROP PROCEDURE if exists monthly_percentage_growth_in_revenue;
CREATE PROCEDURE monthly_percentage_growth_in_revenue @year int 
as
begin 
with cte as 	
(select month(date) as Month_id,
	sum(isnull(amount,0)) Revenue
	from orders
	where year(date) = @year
	group by month(date)
	)
	select 
	month_id, 
	round(growth, 2) as percent_growth
	from
	(select a.month_id,
	(case when b.month_id-a.month_id = 1 then 100*cast(b.revenue-a.revenue as decimal)/cast(a.revenue as decimal) end) as growth  
	from cte a, cte b ) as sb where growth is not null
end;

exec monthly_percentage_growth_in_revenue @year =2022


--8. Customer - favorite food
--	EXECUTE THIS STORED PROCEDURE TO GET THE FAVORITE FOOD OF @user_id 

EXEC Customer_favourite_food @user_id = 3;

DROP PROCEDURE IF EXISTS Customer_favourite_food;
CREATE PROCEDURE Customer_favourite_food @user_id int 
as 
begin 

with cte as 
(
select  
	od.f_id,
	o.user_id, 
	o.r_id,
	o.date,
	concat(od.f_id, o.r_id) as 'concated_ids'
	from order_details od 
	left join 
	orders o on od.order_id = o.order_id
)
,

cpe as

(select 
	user_id,
	f_id, 
	r_id,
	count(concated_ids) as times_ordered
	from cte
	group by concated_ids,
	user_id, 
	f_id, 
	r_id
)

select
	u.user_id, 
	u.name, 
	f_name as favourite_food
	from 
	(
		select 
			c.*,
			f.f_name,
			f.type,
			dense_rank()over(partition by user_id order by times_ordered desc) as rnk
			from cpe c 
			join 
			food f on c.f_id=f.f_id
			) 
			as sb 
			join 
			users u on sb.user_id=u.user_id 
			where rnk=1
			and u.user_id = @user_id
end;

EXEC Customer_favourite_food @user_id = 3; --change this to get the data for different user

