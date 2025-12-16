create database domino_store;

use domino_store;
create table customers (
custid int NOT NULL PRIMARY KEY,
first_name VARCHAR(8) NOT NULL,
    last_name VARCHAR(7) NOT NULL,
    email VARCHAR(19) NOT NULL,
    phone bigint NOT NULL,
    address VARCHAR(11) NOT NULL,
    city VARCHAR(5) NOT NULL,
    state VARCHAR(6) NOT NULL,
    postal_code integer NOT NULL );
    
create table orders ( 
order_id int not null primary key,
    order_date date NOT NULL,
    order_time varchar(8) NOT NULL,
    custid integer NOT NULL,
    status varchar(9) NOT NULL,
    foreign key (custid) references customers(custid) );

alter table orders
modify order_time time not null;


    
create table order_details(
order_details_id int NOT NULL primary key,
    order_id integer NOT NULL,
    pizza_id character varying(14) NOT NULL,
    quantity integer NOT NULL,
    foreign key (order_id) references orders(order_id),
    
   constraint fk_order_detail2
   foreign key (pizza_id) references pizzas(pizza_id) );
   
   create table pizzas (
    pizza_id varchar(14) NOT NULL primary key,
    pizza_type_id varchar(12) NOT NULL,
    size varchar(3) NOT NULL,
    price numeric(5,2) NOT NULL,
    foreign key (pizza_type_id) references pizza_type (pizza_type_id) );
    
    create table pizza_type(
    pizza_type_id varchar(50) NOT NULL primary key,
    name varchar(100) NOT NULL,
    category varchar(50) NOT NULL,
    ingredients text NOT NULL);


drop table order_details;
