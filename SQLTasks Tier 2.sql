/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name AS Facility
FROM Facilities
WHERE membercost > 0;

/* ANSWER
Facility
Tennis Court 1
Tennis Court 2
Massage Room 1
Massage Room 2
Squash Court */


/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(facid)
FROM Facilities
WHERE membercost = 0;

/* ANSWER: 4 */


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0 
	AND membercost < (0.20 * monthlymaintenance);


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1,5);


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 
	CASE WHEN monthlymaintenance > 100 THEN 'expensive'
		ELSE 'cheap' END AS 'General Cost'
FROM Facilities;


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT m.memid, m.firstname, m.surname, m.joindate
FROM Members AS m
INNER JOIN (
	SELECT memid, firstname, surname, MAX(joindate) AS lastjoin
	FROM Members
	GROUP BY EXTRACT(year FROM joindate) 
    ) AS msub 
	ON m.joindate = msub.lastjoin;

/* ANSWER: Darren Smith, 2012-09-26 18:08:45 */


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT Members.surname, Members.firstname, Facilities.name
FROM Members
INNER JOIN Bookings
	ON Members.memid = Bookings.memid
INNER JOIN Facilities
	ON Bookings.facid = Facilities.facid
WHERE Facilities.facid IN (0,1)
ORDER BY Members.surname;

/* ANSWER: I tried multiple variations to get this query to work but PHP kept repeatedly giving the Error Code 403.  This query works but PHP returns an Error Code 403 when CONCAT is included to produce a single column output. When I attempted to alias the tables, I also recieved an Error Code 403.*/


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT f.name AS Facility, CONCAT_WS(m.firstname, ' ', m.surname) AS Name, 
	CASE WHEN f.guestcost > 30 THEN f.guestcost
		WHEN f.membercost > 30 THEN f.membercost
		ELSE NULL END AS Cost
FROM Members AS m
INNER JOIN Bookings AS b ON m.memid = b.memid
INNER JOIN Facilities AS f ON b.facid = f.facid
WHERE DATE(b.starttime) = '2012-09-14' AND (f.membercost > 30 OR f.guestcost > 30)
ORDER BY Cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT f.name AS Facility, CONCAT_WS(m.firstname, ' ', m.surname) AS Name, 
	CASE WHEN f.guestcost > 30 THEN f.guestcost
		WHEN f.membercost > 30 THEN f.membercost
		ELSE NULL END AS Cost
FROM Members AS m
INNER JOIN (
    		SELECT starttime, memid, facid
            FROM Bookings 
            WHERE DATE(starttime) = '2012-09-14'
            ) AS b ON m.memid = b.memid
INNER JOIN (
    		SELECT name, membercost, guestcost, facid
            FROM Facilities 
    		WHERE (membercost > 30 OR guestcost > 30)
            ) AS f ON b.facid = f.facid
ORDER BY Cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

WITH rtable AS (
	SELECT f.name AS Facility, 
		CASE WHEN type.PriceType = 'Guest' THEN TotalUse * guestcost
		ELSE TotalUse * membercost END AS Revenue
	FROM Facilities AS f
	INNER JOIN (
		SELECT facid,
			CASE WHEN memid = 0 THEN 'Guest'
				ELSE 'Member' END AS PriceType,
			COUNT(bookid) AS TotalUse
		FROM Bookings
		GROUP BY facid, PriceType
	    ) AS type ON f.facid = type.facid
	GROUP BY f.facid, PriceType
    )

SELECT Facility, TotalRevenue
FROM (
    SELECT Facility, SUM(Revenue) AS TotalRevenue
    FROM rtable
    GROUP BY Facility
    )
WHERE TotalRevenue < 1000  
  

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT m2.surname || ', ' || m2.firstname AS Member,
        m1.surname || ', ' || m1.firstname AS recommendedBy
FROM Members AS m1
INNER JOIN Members AS m2
ON m2.recommendedby = m1.memid


/* Q12: Find the facilities with their usage by member, but not guests */

SELECT f.name, COUNT(bookid)
FROM Bookings AS b
INNER JOIN Facilities AS f ON b.facid = f.facid AND b.memid <> 0
GROUP BY b.facid


/* Q13: Find the facilities usage by month, but not guests */

SELECT f.name AS Facility, 
    strftime('%m', starttime) AS Month, 
    COUNT(bookid)
FROM Bookings AS b
INNER JOIN Facilities AS f ON b.facid = f.facid
GROUP BY Facility, Month
