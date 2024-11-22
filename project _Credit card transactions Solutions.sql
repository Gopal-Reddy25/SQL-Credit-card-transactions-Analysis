-- Data exploration 
select	
	min(transaction_date) as Transacation_start_date,
	max(transaction_date) as End_transaction_date 
from credit_card_transcations


select
	card_type 
from credit_card_transcations
group by card_type


select
	exp_type 
from credit_card_transcations
group by exp_type


select distinct exp_type from credit_card_transcations

select distinct city from credit_card_transcations

select * from credit_card_transcations 

select count(*) from  credit_card_transcations

select card_type,sum(amount) as total_amount  from credit_card_transcations
group by card_type 
order by total_amount  desc


select  top 5 city ,sum(amount)as cities_total_amount from credit_card_transcations
group by city
order by cities_total_amount  desc



select * from credit_card_transcations ;
/* 1. write a query to print top 5 cities with highest
spends and their percentage contribution of total credit card spends */

with cte as(
select city ,sum(amount)as total_spend from credit_card_transcations
group by city )

,total_spent as (select sum(cast(amount as bigint)) as total_amount from credit_card_transcations)

select top 5 cte.*,round(total_spend *1.0/ total_amount *100,2) as percentage_contribution from
cte ,total_spent
order by total_spend desc


--2 write a query to print highest spend month and amount spent in that month for each card type
select * from credit_card_transcations


with cte2 as(
	select card_type , 
	sum(amount)as total_card_type_spent
	,datepart(year,transaction_date)as year_transactions
	,datepart(month,transaction_date)as month_transactions
from 
	credit_card_transcations
group by
	card_type,
	datepart(year,transaction_date),
	datepart(month,transaction_date) 
--order by card_type,datepart(year,transaction_date),datepart(month,transaction_date) 
)

select *from
	(select *,
	rank()over (partition by card_type order by total_card_type_spent desc)as rn
from  
	cte2)a where rn =1 

/*3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/


WITH cte AS(
SELECT *,
	SUM(amount)  OVER(PARTITION BY card_type ORDER BY  transaction_Date,transaction_id  )AS total_spent
FROM
	credit_card_transcations)

select *from (select *,rank()over(partition by card_type order by total_Spent)as rn 
from cte )a where rn=1

--4- write a query to find city which had lowest percentage spend for gold card type
with cte as(
select 
	city ,card_type ,sum(amount)as amount
	,sum(case when card_type ='Gold'then amount end)as gold_amount
from credit_card_transcations
group by city,card_type 
--order by city,card_type 
)

select top 1 city,sum(gold_amount)*1.0/sum(amount)as gold_ration from cte
group by city
having sum(gold_amount)is not null
order by gold_ration



/*5- write a query to print 3 columns:  city, highest_expense_type ,
lowest_expense_type (example format : Delhi , bills, Fuel)*/

select * from credit_card_transcations

select city ,exp_type 
,max(amount)as highest_expense_type
,min(amount)as lowest_expense_type 
from credit_card_transcations
group by city ,exp_type
order by highest_expense_type desc ,lowest_expense_type 

with cte as(
select city,exp_type ,sum(amount)as total_amount from credit_card_transcations
group by city,exp_type )

select 
city,min(case when rn_asc =1 then exp_type end) as lowest_exp_type
,max(case when rank_desc =1 then exp_type end) as highest_exp_type
from
(select *
,rank()over(partition by city order by total_amount desc )as rank_desc
,rank()over(partition by city order by total_amount asc)as rn_asc
from cte)A
group by city

/*6- write a query to find percentage contribution 
of spends by females for each expense type*/

select * from credit_card_transcations

select exp_type ,
sum(case when gender ='F'then amount else 0 end )*1.0/sum(amount)as female_contribution
from credit_card_transcations
group by exp_type
order by female_contribution

select * from credit_card_transcations
--7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as(
select card_type,exp_type ,sum(amount)as total_amount,
datepart(year,transaction_date)as year_transaction_date,
datepart(month ,transaction_date)as month_transaction_date
from credit_card_transcations
group by  card_type,exp_type,datepart(year,transaction_date),datepart(month ,transaction_date))
select top 1 *,(total_amount- previous_month_spent)*1.0/previous_month_spent as month_on_month_growth
from
(select *,
lag(total_amount)over(partition by card_type,exp_type order by year_transaction_date,month_transaction_date) as previous_month_spent
from cte)a
where previous_month_spent is not null and year_transaction_date =2014 and month_transaction_date=1
order by month_on_month_growth desc


--8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city,sum(amount)*1.0/count(amount)as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in(1,7)
group by city 
order by  ratio desc

/*9- which city took least number of days to reach 
its 500th transaction after the first transaction in that city*/
with cte as(
SELECT *
		,ROW_NUMBER()OVER(PARTITION BY city ORDER BY transaction_date,transaction_id)as rn
FROM credit_card_transcations
	)

SELECT top 1 city ,datediff(day,min(transaction_date),max(transaction_date))as date_difference
FROM cte
where rn =1 or rn =500
group by city
having count(1) =2
order by date_difference