# Data-Analysis-Project

##    Analysis done on following questions ##


1. Find customers who have never ordered
2. Average Price/dish
3. Find the top restaurant in terms of the number of orders for a given month
4. restaurants with monthly sales greater than x for 
5. Show all orders with order details for a particular customer in a particular date range
6. Find restaurants with max repeated customers 
7. Month over month revenue growth of swiggy
8. Customer - favorite food


Analysis is done on the 7 table schema to get the desired result sets

* CTE is used to temporarily name the result set.
* Store Procedure are used to gather the confined result set like :-
* STORE PRECEDURE TO GET THE TOP_RESTRAUNT OF THAT MONTH
* STORE PRECEDURE TO GET THE TOP_RESTRAUNT IN DIFFERENT @MONTH_ID HAVING TOTAL SALES GREATER THAT @VALUE
* STORE PRECEDURE TO GET all orders with order details for a particular customer @name in a particular date range @startdate, @enddate
* STORED PROCEDURE TO GET THE MONTHLY REVENUE PERCENTAGE GROWTH IN A YEAR @YEAR
* STORED PROCEDURE TO GET THE FAVORITE FOOD OF @user_id
