---
title: "PostgreSQL Basics"
date: 2020-10-24
tags: ["sql", "pqsl", "postgres"]

draft: false
---

This is a series of notes from FreeCodeCamp's PostgreSQL tutorial.
The youtube video can be found [here][yt_video].

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Install](#install)
  - [Login to CLI](#login-to-cli)
- [Creating databases](#creating-databases)
  - [Connect to the DB](#connect-to-the-db)
  - [Dropping Databases](#dropping-databases)
  - [Creating Tables](#creating-tables)
- [List Tables in DB](#list-tables-in-db)
- [List Columns in Table](#list-columns-in-table)
- [Creating Tables Part 2 -- With Constraints](#creating-tables-part-2----with-constraints)
- [Dropping tables](#dropping-tables)
- [Insert](#insert)
- [View Table Contents](#view-table-contents)
- [Mockaroo](#mockaroo)
- [Select](#select)
- [Limit](#limit)
  - [Selecting one column:](#selecting-one-column)
  - [Selecting multiple Columns:](#selecting-multiple-columns)
- [Order By](#order-by)
  - [Default ASC mode](#default-asc-mode)
  - [DESC mode](#desc-mode)
- [Distinct](#distinct)
- [Where](#where)
- [AND - OR](#and---or)
  - [Chained Conditionals](#chained-conditionals)
  - [Nested Conditionals](#nested-conditionals)
- [Comparison Operators](#comparison-operators)
- [Offset](#offset)
- [Fetch](#fetch)
- [IN](#in)
- [Between](#between)
- [Like](#like)
    - [Symbols](#symbols)
- [iLike](#ilike)
- [Group By](#group-by)
- [Having](#having)
- [Exporting Query Results](#exporting-query-results)
- [Max, Min, Avg](#max-min-avg)
  - [Getting the Min, Max and, Avg for each Make & Model](#getting-the-min-max-and-avg-for-each-make--model)
  - [Sum](#sum)
- [Operations](#operations)
- [Operations on Data](#operations-on-data)
- [Alias](#alias)
- [Coalesce](#coalesce)
  - [Usage](#usage)
- [NullIf](#nullif)
  - [Handling Division by Zero](#handling-division-by-zero)
- [Now](#now)
  - [Using NOW() to get the date and time](#using-now-to-get-the-date-and-time)
- [Interval](#interval)
- [Extract](#extract)
- [Age](#age)
- [Prefix](#prefix)
- [Primary Key](#primary-key)
  - [Adding a Primary Key](#adding-a-primary-key)
    - [On Table Creation](#on-table-creation)
    - [After Table Creation](#after-table-creation)
  - [Removing a Primary Key](#removing-a-primary-key)
  - [UUIDs as Primary Keys](#uuids-as-primary-keys)
    - [Generating UUIDs](#generating-uuids)
    - [Inserting Rows](#inserting-rows)
- [Constrains](#constrains)
  - [Unique](#unique)
    - [Add](#add)
    - [Remove](#remove)
  - [Check](#check)
- [On Conflict](#on-conflict)
- [Delete](#delete)
  - [Deleting when a Foreign Key is present](#deleting-when-a-foreign-key-is-present)
- [Update](#update)
- [Upsert](#upsert)
- [Foreign Key](#foreign-key)
  - [Updating](#updating)
- [Joins](#joins)
  - [Inner Joins](#inner-joins)
  - [Left Joins](#left-joins)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Install

On Arch Linux install with `pacman`.

```console
pacman -Ss postgresql
```

Then start with `systemctl`

```console
systemctl start postgresql
```

## Login to CLI

Access the PostgreSQL CLI via:

```SQL
sudo -u postgres psql
```

# Creating databases

Within the psql CLI you can run

```SQL
CREATE DATABASE db_name;
```

To create a new database.

> All commands must end with a `;`!!

```SQL
    postgres=# CREATE DATABASE test;
    CREATE DATABASE
    postgres=#
```

## Connect to the DB

`psql -U username db_name`

Or, from within the psql cli

`\c db_name`

## Dropping Databases

Within the psql cli: `DROP DATABASE db_name`

## Creating Tables

```SQL
CREATE TABLE table_name (
	column_name data_type constraints[optional]
)
```

Person Example:

```SQL
CREATE TABLE person (
	id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	gender VARCHAR(6),
	date_of_birth DATE
);
```

[Data Types Docs][data_types]

# List Tables in DB

```console
postTesting=# \d


        List of relations
 Schema |  Name  | Type  | Owner
--------+--------+-------+-------
 public | person | table | kgb33
(1 row)
```

# List Columns in Table

```console
postTesting=# \d person


                         Table "public.person"
    Column     |         Type          | Collation | Nullable | Default
---------------+-----------------------+-----------+----------+---------
 id            | integer               |           |          |
 first_name    | character varying(50) |           |          |
 last_name     | character varying(50) |           |          |
 gender        | character varying(6)  |           |          |
 date_of_birth | date                  |           |          |
```

# Creating Tables Part 2 -- With Constraints

```SQL
CREATE TABLE person (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender VARCHAR(6) NOT NULL,
	date_of_birth DATE NOT NULL
);
```

- `NOT NULL` - Value cannot be NULL
- `PRIMARY KEY` -
- `BIGSERIAL` - Signed Int, Auto increments

```console
postTesting=# \d
             List of relations
 Schema |     Name      |   Type   | Owner
--------+---------------+----------+-------
 public | person        | table    | kgb33
 public | person_id_seq | sequence | kgb33
(2 rows)

postTesting=# \d person
                                       Table "public.person"
    Column     |         Type          | Collation | Nullable |              Default
---------------+-----------------------+-----------+----------+------------------------------------
 id            | bigint                |           | not null | nextval('person_id_seq'::regclass)
 first_name    | character varying(50) |           | not null |
 last_name     | character varying(50) |           | not null |
 gender        | character varying(6)  |           | not null |
 date_of_birth | date                  |           | not null |
Indexes:
    "person_pkey" PRIMARY KEY, btree (id)

```

# Dropping tables

`DROP TABLE table_name;`

# Insert

```SQL
INSERT INTO table_name (
	columns
	...
	...)
VALUES (var, ..., ...);
```

Example:

```SQL
INSERT INTO person (
	first_name,
	last_name,
	gender,
	date_of_birth)
	VALUES ('Anne', 'Smith', 'FEMALE', DATE '1988-01-09');
INSERT 0 1
```

- DATE format is YEAR-MONTH-DAY
- id is not specified because PostgreSQL auto increments it for us

# View Table Contents

Use SQL `SELECT * FROM table_name` to view all entries.

```SQL
SELECT * FROM person;
 id | first_name | last_name | gender | date_of_birth
----+------------+-----------+--------+---------------
  1 | jake       | jones     | MALE   | 1990-01-10
  2 | Anne       | Smith     | FEMALE | 1988-01-09
(2 rows)
```

# Mockaroo

Generating 1,000 rows of data using [Mockaroo][mockaroo]

After downloading changed the following in the CREATE TABLE command

- Added NOT NULL constrains
- Added id and corresponding info

Generated data is in person.sql

Within psql run `\i ./persons.sql` to run all the SQL code within the file

# Select

`SELECT $column_name FROM $table_name;`

`*` is the wild card operator, i.e.

`SELECT * FROM $table_name;` will select all columns.

`LIMIT int` will limit the returned rows to the specified integer

To select multiple columns separate the column names with commas.

`SELECT column_1, column_2, ..., column_n FROM table_name`

# Limit

`LIMIT int` will limit the returned rows to the specified integer

`SELECT * FROM $table_name LIMIT 10`

Will return the first 10 rows

## Selecting one column:

```SQL
SELECT first_name FROM person LIMIT 5;

 first_name
------------
 Sargent
 Tobias
 Wait
 Lulita
 Tobye
(5 rows)
```

## Selecting multiple Columns:

```SQL
 SELECT first_name, last_name FROM person LIMIT 5;

 first_name | last_name
------------+-----------
 Sargent    | Matusiak
 Tobias     | Bulled
 Wait       | Deeves
 Lulita     | Olivo
 Tobye      | Blaisdell
(5 rows)
```

# Order By

Order by has two modes, ASC and DESC. Ascending is default

`SELECT $column_A FROM $table_name ORDER BY $column_B`

## Default ASC mode

```SQL
SELECT * FROM person ORDER BY contry_of_birth LIMIT 10;

 id  | first_name  | last_name | gender |         email          | date_of_birth | contry_of_birth
-----+-------------+-----------+--------+------------------------+---------------+-----------------
 450 | Brinna      | Barabisch | Female | bbarabischch@apple.com | 1989-10-05    | Afghanistan
 656 | Christy     | Tew       | Female | ctewi7@i2i.jp          | 2007-07-18    | Afghanistan
 283 | Anallese    | Wooles    | Female | awooles7u@ebay.co.uk   | 2014-02-15    | Afghanistan
 709 | Wake        | Machans   | Male   | wmachansjo@nih.gov     | 1999-10-04    | Afghanistan
 147 | Hercules    | Anstie    | Male   | hanstie42@cdc.gov      | 1987-04-18    | Afghanistan
 660 | Kissie      | Emett     | Female | kemettib@trellian.com  | 1991-05-23    | Albania
 490 | Kaile       | Neillans  | Female | kneillansdl@t.co       | 2002-09-04    | Albania
 245 | Lee         | Kitter    | Female | lkitter6s@youku.com    | 1953-12-04    | Albania
 361 | Rolf        | Capnor    | Male   |                        | 1997-01-01    | Albania
 590 | Barbaraanne | Easey     | Female | beaseygd@sina.com.cn   | 2017-02-09    | Albania
(10 rows)

```

## DESC mode

```SQL
SELECT * FROM person ORDER BY contry_of_birth DESC LIMIT 10;

 id  | first_name | last_name | gender |          email          | date_of_birth | contry_of_birth
-----+------------+-----------+--------+-------------------------+---------------+-----------------
 757 | Ansell     | Teaz      | Male   | ateazl0@dmoz.org        | 1971-05-02    | Zimbabwe
 559 | Bourke     | Zamora    | Male   | bzamorafi@php.net       | 1983-07-16    | Zimbabwe
 146 | Sharla     | Green     | Female | sgreen41@live.com       | 2020-03-07    | Zambia
 860 | Raul       | Yeliashev | Male   | ryeliashevnv@wiley.com  | 2014-02-16    | Zambia
 332 | Mack       | OLagen    | Male   |                         | 1973-04-03    | Yemen
 314 | Odessa     | Pinnigar  | Female | opinnigar8p@4shared.com | 1986-09-05    | Yemen
 567 | Avery      | Snap      | Male   | asnapfq@gravatar.com    | 1977-02-10    | Yemen
 535 | Ruprecht   | Lippett   | Male   | rlippetteu@amazon.co.uk | 1984-03-09    | Yemen
 955 | Terrance   | Fevier    | Male   | tfevierqi@myspace.com   | 1974-07-11    | Yemen
  19 | Emanuel    | Bembrigg  | Male   |                         | 2016-11-20    | Western Sahara
(10 rows)
```

# Distinct

`DISTINCT` removes duplicates from a Query

`SELECT DISTINCT $column_name FROM $table_name`

```SQL
 SELECT DISTINCT contry_of_birth FROM person ORDER BY contry_of_birth LIMIT 5;

   contry_of_birth
---------------------
 Afghanistan
 Albania
 Antigua and Barbuda
 Argentina
 Armenia
(5 rows)
```

# Where

`SELECT $column_A FROM $table WHERE $condtion`

```SQL
SELECT * FROM person WHERE gender = 'Male' LIMIT 5;

 id | first_name | last_name | gender |          email          | date_of_birth | contry_of_birth
----+------------+-----------+--------+-------------------------+---------------+-----------------
  1 | Sargent    | Matusiak  | Male   | smatusiak0@irs.gov      | 1968-09-08    | China
  2 | Tobias     | Bulled    | Male   |                         | 1961-07-01    | Poland
  3 | Wait       | Deeves    | Male   | wdeeves2@lulu.com       | 1972-09-24    | Russia
  6 | Antonino   | Pineaux   | Male   |                         | 1971-05-28    | Russia
  7 | Quintin    | Cromb     | Male   | qcromb6@theguardian.com | 1979-11-25    | China
(5 rows)
```

You can also use other comparison operators

```SQL
SELECT * FROM person WHERE date_of_birth > DATE '1999-03-03' LIMIT 5;

 id | first_name |  last_name  | gender |             email             | date_of_birth |    contry_of_birth
----+------------+-------------+--------+-------------------------------+---------------+-----------------------
  5 | Tobye      | Blaisdell   | Female | tblaisdell4@sciencedirect.com | 2015-10-14    | Netherlands
  9 | Barthel    | Roughey     | Male   | broughey8@opensource.org      | 2002-04-23    | Philippines
 11 | Geralda    | Ludgate     | Female |                               | 2005-02-12    | France
 12 | Tracey     | Connaughton | Female | tconnaughtonb@pcworld.com     | 2008-03-05    | Saint Kitts and Nevis
 13 | Alica      | OMahony     | Female |                               | 2004-02-22    | France
(5 rows)
```

# AND - OR

Conditionals can also be combined using AND & OR.

`SELECT ... FROM ... WHERE $condtion_A AND $condtion_B`

## Chained Conditionals

```SQL
SELECT * FROM person WHERE date_of_birth > DATE '1999-03-03' AND contry_of_birth = 'Brazil'  LIMIT 5;

 id  | first_name | last_name | gender |          email           | date_of_birth | contry_of_birth
-----+------------+-----------+--------+--------------------------+---------------+-----------------
  30 | Katee      | Coopman   | Female | kcoopmant@columbia.edu   | 2006-10-17    | Brazil
  40 | Sula       | Hourihane | Female | shourihane13@mozilla.org | 2016-12-06    | Brazil
  53 | Camellia   | Minico    | Female |                          | 2008-03-26    | Brazil
  62 | Leona      | Leborgne  | Female | lleborgne1p@squidoo.com  | 2000-02-29    | Brazil
 398 | Davidson   | Kynson    | Male   | dkynsonb1@e-recht24.de   | 2002-01-31    | Brazil
(5 rows)

```

## Nested Conditionals

```SQL
SELECT * FROM person WHERE gender = 'Male' AND (contry_of_birth = 'Brazil' OR contry_of_birth = 'Russia')  LIMIT 5;

 id | first_name | last_name | gender |         email         | date_of_birth | contry_of_birth
----+------------+-----------+--------+-----------------------+---------------+-----------------
  3 | Wait       | Deeves    | Male   | wdeeves2@lulu.com     | 1972-09-24    | Russia
  6 | Antonino   | Pineaux   | Male   |                       | 1971-05-28    | Russia
 22 | Berny      | Tremayle  | Male   |                       | 1989-08-21    | Brazil
 37 | Morly      | Emanueli  | Male   |                       | 1991-06-01    | Russia
 51 | Holden     | Olliff    | Male   | holliff1e@cbsnews.com | 1992-12-25    | Russia
(5 rows)

```

# Comparison Operators

| Equal | Greater Than | Less Than | Greater Than or Equal To | Less Than or Equal To | Not Equal |
| :---: | :----------: | :-------: | :----------------------: | :-------------------: | :-------: |
|   =   |      >       |     <     |            >=            |          <=           |    <>     |

# Offset

`SELECT ... FROM ... OFFSET $n` returns all columns after the first `n` columns.

```SQL
SELECT * FROM person OFFSET 5 LIMIT 5;

 id | first_name | last_name | gender |          email           | date_of_birth | contry_of_birth
----+------------+-----------+--------+--------------------------+---------------+-----------------
  6 | Antonino   | Pineaux   | Male   |                          | 1971-05-28    | Russia
  7 | Quintin    | Cromb     | Male   | qcromb6@theguardian.com  | 1979-11-25    | China
  8 | Rivy       | Di Biagio | Female | rdibiagio7@nymag.com     | 1987-07-18    | Uruguay
  9 | Barthel    | Roughey   | Male   | broughey8@opensource.org | 2002-04-23    | Philippines
 10 | Tanhya     | Dymock    | Female | tdymock9@unesco.org      | 1974-04-08    | Ukraine
(5 rows)

```

# Fetch

SQL standard for LIMIT.

`LIMIT $n` is equivalent to `FETCH FIRST $n ROW ONLY`

# IN

A shorter way to write OR'd equal to statements.

`... WHERE $column_X = $value_1 OR ... OR $column_X = $value_N`

Is equivalent to

`... WHERE $column_X IN ($value_1, ..., $value_N)`

```SQL
SELECT * FROM person WHERE contry_of_birth IN ('Russia', 'Germany', 'Japan') OFFSET 5 LIMIT 5;

 id  | first_name |  last_name   | gender |            email             | date_of_birth | contry_of_birth
-----+------------+--------------+--------+------------------------------+---------------+-----------------
  61 | Aimee      | Romei        | Female | aromei1o@yahoo.com           | 2019-02-17    | Russia
  63 | Sybille    | Disbrey      | Female | sdisbrey1q@addtoany.com      | 2004-11-26    | Germany
  72 | Jamima     | Hardison     | Female | jhardison1z@china.com.cn     | 1959-04-25    | Russia
  90 | Quintin    | Raubenheimer | Male   | qraubenheimer2h@yolasite.com | 2015-04-22    | Japan
 102 | Rand       | Oxenden      | Male   | roxenden2t@123-reg.co.uk     | 2003-08-31    | Russia
(5 rows)

```

# Between

Select all rows where the given column is between two values

`... WHERE $column BETWEEN $value_1 AND $value_2`

```SQL
SELECT * FROM person WHERE date_of_birth BETWEEN DATE '2000-01-01' AND '2009-12-31' ORDER BY date_of_birth LIMIT 5;

 id  | first_name |  last_name  | gender |            email             | date_of_birth | contry_of_birth
-----+------------+-------------+--------+------------------------------+---------------+-----------------
 907 | Marjie     | Wrightham   | Female |                              | 2000-02-20    | Portugal
  62 | Leona      | Leborgne    | Female | lleborgne1p@squidoo.com      | 2000-02-29    | Brazil
 624 | Gennie     | De Michetti | Female | gdemichettihb@imdb.com       | 2000-03-18    | Sweden
 362 | Jedediah   | Hincham     | Male   | jhinchama1@ezinearticles.com | 2000-03-27    | Russia
 994 | Gertruda   | Tapp        | Female | gtapprl@amazon.de            | 2000-06-16    | Netherlands
(5 rows)

```

# Like

`LIKE` is used for pattern matching strings

`... WHERE $column LIKE $pattern`

### Symbols

- `%` is the wild card
- `_` Matches a single char

```SQL
SELECT * FROM person WHERE email LIKE '%@google%' LIMIT 5;

 id  | first_name | last_name | gender |         email         | date_of_birth | contry_of_birth
-----+------------+-----------+--------+-----------------------+---------------+-----------------
  31 | Cherin     | Trevett   | Female | ctrevettu@google.cn   | 2013-03-02    | China
 121 | Maggee     | Greenley  | Female | mgreenley3c@google.pl | 1970-01-23    | China
 212 | Jeramie    | Margeram  | Male   | jmargeram5v@google.fr | 1973-03-10    | Indonesia
 301 | Alisa      | Twells    | Female | atwells8c@google.cn   | 1987-02-28    | China
 305 | Frannie    | Marriage  | Male   | fmarriage8g@google.fr | 2015-10-04    | Russia
(5 rows)

```

# iLike

`ILIKE` is a case **insensitive** version of `LIKE`

# Group By

Groups data by a column

`SELECT $column, COUNT(*) FROM $table GROUP BY $column`

```SQL
SELECT contry_of_birth, COUNT(*) from person GROUP BY contry_of_birth ORDER BY COUNT DESC LIMIT 10;

 contry_of_birth | count
-----------------+-------
 China           |   188
 Indonesia       |   104
 Russia          |    61
 Philippines     |    52
 Brazil          |    46
 United States   |    37
 Portugal        |    37
 France          |    30
 Poland          |    28
 Sweden          |    24
(10 rows)

```

# Having

A way to filter `GROUP BY` results

`... GROUP BY ... HAVING $condtional`

```SQL
SELECT contry_of_birth, COUNT(*) from person GROUP BY contry_of_birth HAVING COUNT(*) > 10 ORDER BY contry_of_birth LIMIT 10;

 contry_of_birth | count
-----------------+-------
 Argentina       |    11
 Brazil          |    46
 China           |   188
 Colombia        |    16
 Czech Republic  |    11
 France          |    30
 Greece          |    14
 Indonesia       |   104
 Japan           |    14
 Mexico          |    13
(10 rows)

```

> Other Aggregate Functions like `COUNT()` can be found [here][aggregate_functions] and are discussed in more detail in the next section.

# Exporting Query Results

```SQL
COPY (query) TO 'location/file_name' DELIMITER 'delimiter' FILE_TYPE HEADER;
```

Example (using the car_person.sql file):

```SQL
COPY persons TO '\tmp\persons_db.csv' DELIMITER ',' CSV HEADER;
```

# Max, Min, Avg

```SQL
SELECT MAX(price), MIN(price), AVG(price::numeric)::money FROM car;

    max     |   min   |    avg
------------+---------+------------
 $19,987.90 | $260.86 | $10,039.70
(1 row)
```

> For Avg, the price is cast to a numeric type then back to money because `AVG` does not accept the type money.

## Getting the Min, Max and, Avg for each Make & Model

```SQL
SELECT make, model, MIN(price), MAX(price), AVG(price::numeric)::money FROM car GROUP BY make, model ORDER BY AVG(price::numeric) LIMIT 10;

    make    |     model      |   min   |   max   |   avg
------------+----------------+---------+---------+---------
 Volkswagen | GTI            | $260.86 | $260.86 | $260.86
 Bentley    | Continental GT | $277.09 | $277.09 | $277.09
 Mitsubishi | Expo           | $288.28 | $288.28 | $288.28
 Chevrolet  | Blazer         | $340.02 | $340.02 | $340.02
 Mazda      | Protege        | $387.81 | $387.81 | $387.81
 Lincoln    | Navigator      | $561.70 | $561.70 | $561.70
 Mazda      | B2600          | $577.52 | $577.52 | $577.52
 Dodge      | Ram Wagon B150 | $599.64 | $599.64 | $599.64
 Porsche    | 911            | $660.27 | $660.27 | $660.27
 Isuzu      | Rodeo          | $709.94 | $709.94 | $709.94
(10 rows)
```

## Sum

```SQL
SELECT make, SUM(price) FROM car GROUP BY make LIMIT 5;

   make   |     sum
----------+-------------
 McLaren  |   $4,512.17
 Ford     | $799,628.88
 Maserati |  $67,333.64
 Dodge    | $582,804.56
 Infiniti | $125,195.89
(5 rows)
```

# Operations

```SQL
SELECT 2+2 AS add,
	   2-2 AS sub,
	   2*3 AS mul,
	   16/2 AS div,
	   3^3 AS pow,
	   5! AS fac,
	   9%3 AS mod;

 add | sub | mul | div | pow | fac | mod
-----+-----+-----+-----+-----+-----+-----
   4 |   0 |   6 |   8 |  27 | 120 |   0
(1 row)
```

# Operations on Data

Here we are displaying the new price and potential loss a 10% sale plus a \$200 coupon would cost
a car dealership.

```SQL

SELECT make, model, year, (price::numeric * .9 - 200)::money AS "New Price", (price::numeric * .1 + 200)::money AS "Lost Profit" FROM car ORDER BY "Lost Profit" LIMIT 10;

    make    |     model      | year | New Price | Lost Profit
------------+----------------+------+-----------+-------------
 Volkswagen | GTI            | 2000 |    $34.77 |     $226.09
 Bentley    | Continental GT | 2012 |    $49.38 |     $227.71
 Mitsubishi | Expo           | 1992 |    $59.45 |     $228.83
 Ford       | Explorer       | 2009 |    $60.29 |     $228.92
 Lexus      | ES             | 2007 |    $68.84 |     $229.87
 Chevrolet  | Blazer         | 1992 |   $106.02 |     $234.00
 Acura      | RSX            | 2003 |   $123.57 |     $235.95
 Hyundai    | Accent         | 1999 |   $141.35 |     $237.93
 McLaren    | MP4-12C        | 2012 |   $148.40 |     $238.71
 Mazda      | Protege        | 2001 |   $149.03 |     $238.78
(10 rows)
```

# Alias

You might have noticed the `AS` keyword in the above SQL, its just a way to rename columns in the output.

`SELECT $column_name AS $new_column_name FROM ...`

# Coalesce

`COALESCE($val_1, $val_2, ..., $val_n)` will output the first value that is not `null`

## Usage

`SELECT COALESCE(null, null, 2)`

Can be used to provide a default value.

```SQL
SELECT email, COALESCE(email, 'Email not Provided') FROM person LIMIT 5;

             email             |           coalesce
-------------------------------+-------------------------------
 smatusiak0@irs.gov            | smatusiak0@irs.gov
                               | Email not Provided
 wdeeves2@lulu.com             | wdeeves2@lulu.com
                               | Email not Provided
 tblaisdell4@sciencedirect.com | tblaisdell4@sciencedirect.com
(5 rows)

```

# NullIf

`NULLIF($val_1, $val_2)`

If `val_1` == `val_2` returns Null, otherwise returns `val_1`

## Handling Division by Zero

`SELECT COALESCE($val_A / NULLIF(%val_B, 0), -1)`

Val_A = 33, Val_B = 11

```SQL

SELECT COALESCE(33 / NULLIF(11, 0), -1);

 coalesce
----------
        3
(1 row)


```

Val_A = 33, Val_B = 0

```SQL
SELECT COALESCE(33 / NULLIF(0, 0), -1);

 coalesce
----------
       -1
(1 row)

```

# Now

`NOW()` Returns the current Date and Time

Format: yyyy-mm-dd hh:mm:ss.uuuuuu+Shift_From_UTC

```SQL
SELECT NOW();
              now
-------------------------------
 2020-04-11 15:58:19.979002-05
(1 row)
```

## Using NOW() to get the date and time

Cast NOW() into DATE and TIME.

```SQL
SELECT NOW()::DATE AS date, NOW()::TIME AS time;
    date    |      time
------------+-----------------
 2020-04-11 | 16:57:12.945428
(1 row)
```

More Date/Time Info can be found [here][date_time_docs]

# Interval

Used to calculate differences between Date/Time objects

```SQL
SELECT
    NOW()::DATE AS now,
    (NOW() -  INTERVAL '1 YEAR')::DATE AS "1 Year Ago",
    (NOW() + INTERVAL '100 DAYS')::DATE as "100 Days From Now";

    now     | 1 Year Ago | 100 Days From Now
------------+------------+-------------------
 2020-04-11 | 2019-04-11 | 2020-07-20
(1 row)
```

# Extract

Used to extract part of a datetime object

```SQL
SELECT
    EXTRACT(CENTURY FROM NOW()) AS Century,
    EXTRACT(YEAR FROM NOW()) as Year,
    EXTRACT(MONTH FROM NOW()) AS Month,
    EXTRACT(DAY FROM NOW()) AS Day,
    EXTRACT(DOW FROM NOW()) AS "Day Of The Week";

 century | year | month | day | Day Of The Week
---------+------+-------+-----+-----------------
      21 | 2020 |     4 |  11 |               6
(1 row)
```

Where the Day of the Week uses the following table:

| Sunday | Monday | \.\.\. | Friday | Saturday |
| ------ | ------ | ------ | ------ | -------- |
| 0      | 1      | \.\.\. | 5      | 6        |

# Age

`AGE` Calculates the difference between two timestamps

```SQL
SELECT first_name, last_name, AGE(NOW(), date_of_birth) AS Age FROM person ORDER BY date_of_birth LIMIT 5;
 first_name | last_name |                   age
------------+-----------+-----------------------------------------
 Isabelle   | Etheredge | 70 years 2 mons 25 days 17:24:41.850913
 Holly-anne | Folker    | 70 years 2 mons 22 days 17:24:41.850913
 Edeline    | Pietz     | 70 years 1 mon 7 days 17:24:41.850913
 Neall      | Danbrook  | 70 years 21 days 17:24:41.850913
 Leesa      | Gerault   | 69 years 9 mons 25 days 17:24:41.850913
(5 rows)
```

# Prefix

- `\d $table` will show the columns and indexes for a table. Use this to see the constraints and primary keys.

# Primary Key

## Adding a Primary Key

### On Table Creation

```SQL
create table person (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender VARCHAR(7) NOT NULL,
	email VARCHAR(100),
	date_of_birth DATE NOT NULL,
	contry_of_birth VARCHAR(50) NOT NULL
);
```

One of the value constraints is `PRIMARY KEY`

### After Table Creation

```SQL
ALTER TABLE $table_name ADD PRIMARY KEY ($pk_column);
```

Notes:

- All values in the `pk_column` must be unique
- You can use multiple columns instead of one to make a pkey

## Removing a Primary Key

```SQL
ALTER TABLE $table DROP CONSTRAINT $table_pkey;
```

## UUIDs as Primary Keys

### Generating UUIDs

Postgres automatically comes with an extension you can enable to use UUIDs.
Simply run

```SQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";



SELECT uuid_generate_v4();


           uuid_generate_v4
--------------------------------------
 0a59ea41-ad36-4a23-85d0-eea04c72a519
(1 row)

```

### Inserting Rows

In the `CREATE TABLE`:

```SQL
CREATE TABLE $table_name (
	id UUID PRIMARY KEY,
	$column_1,
	...,
	$column_N
);
```

When Inserting:

```SQL
INSERT INTO $table (id, $column_1, ..., $column_N) VALUES (uuid_generate_v4(), $value_1, ..., $value_N);
```

# Constrains

## Unique

Different from primary keys, but have the same add/drop syntax.

### Add

For a custom constraint name use:

```SQL
ALTER TABLE $table ADD CONSTRAINT $constraint_name UNIQUE ($column);
```

To let PostgreSQL decide the constraint name use:

```SQL
ALTER TABLE $table ADD UNIQUE ($column);
```

### Remove

```SQL
ALTER TABLE $table DROP CONSTRAINT $constraint_name;
```

## Check

A Constraint based on a condition.

```SQL
ALTER TABLE $table ADD CONSTRAINT $constraint_name CHECK ($conditional);
```

An example using the `person` table.

```SQL
ALTER TABLE person ADD CONSTRAINT gender_constraint CHECK (gender IN ('Female', 'Male'));
```

```
 \d person
                                        Table "public.person"
     Column      |          Type          | Collation | Nullable |              Default
-----------------+------------------------+-----------+----------+------------------------------------
 id              | bigint                 |           | not null | nextval('person_id_seq'::regclass)
 first_name      | character varying(50)  |           | not null |
 last_name       | character varying(50)  |           | not null |
 gender          | character varying(7)   |           | not null |
 email           | character varying(100) |           |          |
 date_of_birth   | date                   |           | not null |
 contry_of_birth | character varying(50)  |           | not null |
Indexes:
    "person_pkey" PRIMARY KEY, btree (id)
    "unique_email" UNIQUE CONSTRAINT, btree (email)
Check constraints:
    "gender_constraint" CHECK (gender::text = ANY (ARRAY['Female'::character varying, 'Male'::character varying]::text[]))

```

# On Conflict

Used to manage update/insert errors where there is a unique constraint on a column.

In the SQL below if the primary key is a duplicate, it is not inserted into the table, instead, nothing happens.

```SQL
INSERT INTO $table ($pk_column, $column_1, $column_2, ..., $column_N)
VALUES ($pk_value, $value_1, $value_2, ..., $value_N)
ON CONFLICT ($pk_column) DO NOTHING;
```

To manage more than one unique column use:

```SQL
ON CONFLICT ($unique_column_1, $unique_column_2) DO NOTHING;
```

# Delete

```SQL
DELETE FROM $table WHERE ...
```

## Deleting when a Foreign Key is present

Two Options:

1. Update record dependent on foreign key.
2. Delete record dependent on foreign key.
3. Use Cascade - This is a bad practice.

Then delete the record belonging to the foreign key.

# Update

```SQL
UPDATE $table SET $column = $value WHERE ...
```

For more than one column:

```SQL
UPDATE $table SET $column_1 = $value_1, $column_2 = $value_2 WHERE ...
```

# Upsert

Used when a row may or may not be present in the database.

For example if a user updates their email shortly after creating their account,
and the order that the database receives these requests is not known. Only the
most up-to-date info will be kept. Regardless of which gets there first.

```SQL
INSERT INTO $table ($pk, $column_1, ... $column_N) VALUES ($pk, $value_1, ... $value_2)
ON CONFLICT ($pk) DO UPDATE SET $column_to_update = EXCLUDED.$column_to_update;
```

# Foreign Key

A Foreign Key is a column in a table that links to the primary key of a row in another column.

![SQL Relationship Diagram][sql_relationship_diagram]

Foreign Key row example:

```SQL
$forign_key $TYPE REFERANCES $table($pk) UNIQUE $forgin_key
```

In an INSERT statement:

```SQL
create table person (
	id BIGSERIAL NOT NULL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	gender VARCHAR(7) NOT NULL,
	email VARCHAR(100),
	date_of_birth DATE NOT NULL,
	contry_of_birth VARCHAR(50) NOT NULL,
	car_id BIGINT REFERENCES car(id) UNIQUE (car_id)
);
```

> Note - The Forging Key must be the same type as the pk it references.

## Updating

```SQL
UPDATE person SET $fk = $val WHERE ...;
```

# Joins

![Sql Joins Diagram][joins_diagram]

Notes:

- The `ON $table_1.column = $table_2.column` syntax is the same as `USING $column` if and only if the columns have the same names in both tables.

## Inner Joins

Combines elements present in both tables into a new table.

```SQL
SELECT * FROM $table_1 JOIN $table_2 ON $table_1.column = $table_2.column;
```

An example using our `person` and `car` tables.

```SQL
SELECT * FROM person JOIN car ON person.car_id = car.id;
-[ RECORD 1 ]---+-------------------
id              | 3
first_name      | Wait
last_name       | Deeves
gender          | Male
email           | wdeeves2@lulu.com
date_of_birth   | 1972-09-24
contry_of_birth | Russia
car_id          | 1
id              | 1
make            | Acura
model           | Integra
year            | 1995
vin             | JHMZE2H59DS943694
price           | $3,441.88
-[ RECORD 2 ]---+-------------------
id              | 1
first_name      | Sargent
last_name       | Matusiak
gender          | Male
email           | smatusiak0@irs.gov
date_of_birth   | 1968-09-08
contry_of_birth | China
car_id          | 3
id              | 3
make            | BMW
model           | 7 Series
year            | 2001
vin             | 5J8TB3H33FL023983
price           | $19,746.03
```

Selecting specific columns from both tables:

```SQL
SELECT person.first_name, person.last_name, car.make, car.model FROM person JOIN car ON person.id = car.id;
 first_name | last_name | make  |  model
------------+-----------+-------+----------
 Sargent    | Matusiak  | Acura | Integra
 Tobias     | Bulled    | Acura | Integra
 Wait       | Deeves    | BMW   | 7 Series
(3 rows)
```

## Left Joins

Combines two tables where the result has everything from the Left table and the shared values from the
right table.

In the Car example the result would have all the people and the people who have cars would also have the car info.
The people without a `car_id` will have `null` for all of the car values.

```SQL
SELECT * FROM person LEFT JOIN car ON car.id = person.car_id;
 id | first_name | last_name | gender |             email             | date_of_birth | contry_of_birth | car_id | id | make  |  model   | year |        vin        |   price
----+------------+-----------+--------+-------------------------------+---------------+-----------------+--------+----+-------+----------+------+-------------------+------------
  3 | Wait       | Deeves    | Male   | wdeeves2@lulu.com             | 1972-09-24    | Russia          |      1 |  1 | Acura | Integra  | 1995 | JHMZE2H59DS943694 |  $3,441.88
  1 | Sargent    | Matusiak  | Male   | smatusiak0@irs.gov            | 1968-09-08    | China           |      3 |  3 | BMW   | 7 Series | 2001 | 5J8TB3H33FL023983 | $19,746.03
  5 | Tobye      | Blaisdell | Female | tblaisdell4@sciencedirect.com | 2015-10-14    | Netherlands     |        |    |       |          |      |                   |
  4 | Lulita     | Olivo     | Female |                               | 1953-09-03    | China           |        |    |       |          |      |                   |
  2 | Tobias     | Bulled    | Male   |                               | 1961-07-01    | Poland          |        |    |       |          |      |                   |
(5 rows)
```

[yt_video]: https://www.youtube.com/watch?v=qw--VYLpxG4
[mockaroo]: https://www.mockaroo.com/
[data_types]: https://www.postgresql.org/docs/12/datatype.html
[aggregate_functions]: https://www.postgresql.org/docs/12/functions-aggregate.html
[date_time_docs]: https://www.postgresql.org/docs/12/datatype-datetime.html
[sql_relationship_diagram]: /images/notes/sql_relationship_diagram.png
[joins_diagram]: /images/notes/joins_diagram.png
