show databases;
create database music_database;
use music_database;
show tables;

## QUESTION SET 1 - EASY ##

-- Q1 Who is the senior most employee based on job title?
select title, concat(first_name,' ',last_name) as employee_name, 
levels, email, city, country from employee
order by levels desc
limit 1;

-- Q2 Which country have the most invoices
select count(*) as invoice_counts, billing_country from invoice
group by billing_country
order by invoice_counts desc;

-- Q3 what are top 3 values of total invoices?
select customer_id, total from invoice
order by total desc
limit 3;

-- Q4 Which city has the best customers? We would like to through a promotional Music Festival in city we made the most money
-- Write a query that returns one city that has the highest sum of invoice totals.
-- Return both the city name and sum of all invoice totals.
select * from customer;
select sum(total) as invoice_total, billing_city from invoice
group by billing_city
order by invoice_total desc;

-- Q5 Who is the best customer? The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent most money..
select c.customer_id, concat(c.first_name,' ',c.last_name) as customer_name, sum(i.total) as Amount 
from customer as c
join invoice as i on c.customer_id = i.customer_id
group by c.customer_id, customer_name
order by Amount desc
limit 1;

## QUESTION SET 2 - MODERATE ##

-- Q1 Write query to return email, first name, last name & Genre of Rock Music listners.
-- Return your list by alphabetically by email starting with A.
select distinct c.email, concat(c.first_name,' ',c.last_name) as customer_name
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
where track_id in(
select track_id from track as t
join genre as g on t.genre_id = g.genre_id
where g.name like 'Rock')
order by email;

-- Q2 Lets invite the artists who have written most rock music in our dataset.
-- Write a query that returns Artist name and total track count of the top 10 rock bands.

select a.name, count(t.track_id) as tracks 
from artist as a
join album as al on a.artist_id = al.artist_id
join track as t on al.album_id = t.album_id
join genre as g on t.genre_id = g.genre_id
where g.name like 'Rock'
group by a.name
order by tracks desc
limit 10;

-- Q3 Return all the track names that have a song length longer than the average song length.
-- Return the name and Milliseconds for each track. 
-- Order by the song lenght with the longest songs listed first.

select name, milliseconds from track
where milliseconds > (
select avg(milliseconds) as avg_length from track)
order by milliseconds desc;

## QUESTION SET 3 - ADVANCE ##

-- Q1 Find how much amount spend by each customer on artists?
-- Write a query to return customer name, artist name and total spent.

with best_selling_artist as (
select a.artist_id, a.name as artist_name, sum(il.unit_price * il.quantity) as total_sales
from invoice_line as il
join track as t on t.track_id = il.track_id
join album as al on al.album_id = t.album_id
join artist as a on a.artist_id = al.artist_id
group by 1, 2
order by 3 desc
limit 1
)
select c.customer_id, concat(c.first_name,' ',c.last_name) as customer, bsa.artist_name, round(sum(il.unit_price * il.quantity),2) as amount_spent
from invoice as i
join customer as c on c.customer_id = i.customer_id
join invoice_line as il on il.invoice_id = i.invoice_id
join track as t on t.track_id = il.track_id
join album as al on al.album_id = t.album_id
join best_selling_artist as bsa on bsa.artist_id = al.artist_id
group by 1,2,3
order by 4 desc;

-- Q2 We want to find out most popular Music Genre for each country.
-- We determine the most popular genre as the genre with the highest amount of purchase.
-- Write a query that returns each country along with the top Genre.
-- For countries where the maximum number of purchases is shared return all genres
with popular_genre as (
select count(il.quantity) as purchase, c.country, g.name, g.genre_id,
row_number() over(partition by c.country order by count(il.quantity) desc) as row_no
from invoice_line as il
join invoice as i on i.invoice_id = il.invoice_id 
join customer as c on c.customer_id = i.customer_id
join track as t on t.track_id = il.track_id
join genre as g on g.genre_id = t.genre_id
group by 2,3,4
order by c.country asc, purchase desc
)
select * from popular_genre where row_no <= 1;

-- Q3 Write a query that determines the customer that has spent on music for each country.
-- Write a query that returns a country along with the top customer and how much they spent.
-- For countries the top amount is shared, provide all customers who spent this amount
with customer_with_country as (
select c.customer_id, concat(c.first_name,' ',c.last_name) as customer_name, billing_country, round(sum(total),2) as total_spending,
row_number() over(partition by billing_country order by sum(total) desc) as rowno
from invoice as i
join customer as c on c.customer_id = i.customer_id
group by 1, 2, 3
order by 3 asc, 4 desc)
select * from customer_with_country where rowno <= 1;