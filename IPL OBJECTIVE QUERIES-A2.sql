
-- Enugu Saketh Reddy 
-- RCB - STRATEGY FOR IPL 

USE ipl ; 

-- OBEJECTIVE QUESTIONS --

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 1.List the different dtypes of columns in table “ball_by_ball” 
--   (using information schema)

-- QUERY --
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Ball_by_Ball';

-- ********************************************************************************************************
-- ********************************************************************************************************


-- 2.What is the total number of runs scored in 1st season by RCB
--  (bonus: also include the extra runs using the extra runs table)

-- QUERY --
SELECT  m.Season_Id , 
		SUM(bob.Runs_Scored) + SUM(COALESCE(er.Extra_Runs, 0)) AS Total_Runs_Scored
FROM ball_by_ball bob 
JOIN team t ON t.Team_Id = bob.Team_Batting
JOIN matches m ON m.Match_Id = bob.Match_Id
LEFT JOIN extra_runs er ON er.Match_Id = bob.Match_Id 
		AND er.Over_Id = bob.Over_Id 
        AND er.Ball_Id = bob.Ball_Id 
        AND er.Innings_No = bob.Innings_No 
WHERE t.Team_Name = 'Royal Challengers Bangalore' 
		AND Season_Id = ( SELECT MIN(Season_Id)
						  FROM matches
                          WHERE Match_Id = m.Match_Id )
GROUP BY m.Season_Id
ORDER BY m.Season_Id  LIMIT 1 ;

-- ********************************************************************************************************
-- ********************************************************************************************************


-- 3. How many players were more than the age of 25 during season 2014?

-- QUERY --
SELECT COUNT(DISTINCT p.Player_Id) AS Players_Count
FROM player p 
JOIN player_match pm ON pm.Player_Id = p.Player_Id
JOIN matches m ON m.Match_Id = pm.Match_Id
WHERE YEAR(m.Match_Date) = 2014 
	  AND TIMESTAMPDIFF(YEAR, p.DOB , '2014-01-01') > 25 ;
      
-- ********************************************************************************************************
-- ********************************************************************************************************


-- 4. How many matches did RCB win in 2013?

-- QUERY --
SELECT COUNT(*) AS Matches_Won 
FROM team t 
JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
WHERE Match_Winner = 2 
      AND Team_Name = 'Royal Challengers Bangalore' 
	  AND YEAR(Match_Date) = 2013;

-- ********************************************************************************************************
-- ********************************************************************************************************
      

-- 5. List the top 10 players according to their strike rate in the last 4 seasons.

-- QUERY -- 
WITH Prev_Season AS (
	SELECT DISTINCT Season_Year , Season_Id 
    FROM season
    ORDER BY Season_Year DESC LIMIT 4 
    ) 
SELECT DISTINCT p.Player_Name , 
	   ( SUM(bob.Runs_Scored) * 100 / COUNT(bob.Ball_Id) ) AS Strike_Rate
FROM ball_by_ball bob 
JOIN player p ON bob.Striker = p.Player_Id
JOIN matches m ON bob.Match_Id = m.Match_Id 
JOIN Prev_Season ps ON m.Season_Id = ps.Season_Id
GROUP BY p.Player_Name  
ORDER BY Strike_Rate DESC LIMIT 10 ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 6. What are the average runs scored by each batsman considering all the seasons?

-- QUERY --
WITH CTE AS (
		SELECT p.Player_Id , p.Player_Name , 
				SUM(bob.Runs_Scored) AS Total_Runs , 
				COUNT(DISTINCT bob.Match_Id) AS Total_Innings 
		FROM ball_by_ball bob 
		JOIN player p ON bob.Striker = p.Player_Id 
		GROUP BY  p.Player_Id , p.Player_Name )
SELECT CTE.* , ROUND(Total_Runs/Total_Innings , 2) AS Average_Runs
FROM CTE 
ORDER BY Average_Runs DESC ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 7. What are the average wickets taken by each bowler considering all the seasons?

-- QUERY --
WITH CTE AS (
		SELECT bob.Bowler , p.Player_Name , 
				COUNT(wt.Player_Out) AS Total_Wickets , 
                COUNT(DISTINCT bob.Match_Id) AS Innings_Played
		FROM ball_by_ball bob 
        JOIN player p ON bob.Bowler = p.Player_Id
        JOIN wicket_taken wt ON  bob.Match_Id = wt.Match_Id 
							AND bob.Over_Id = wt.Over_Id 
                            AND bob.Ball_Id = wt.Ball_Id 
                            AND bob.Innings_No = wt.Innings_No 
		GROUP BY bob.Bowler, p.Player_Name ) 
SELECT CTE.* , ROUND(Total_Wickets / Innings_Played ,2) AS Average_Wickets
FROM CTE 
ORDER BY Total_Wickets DESC ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 8. List the players who have average runs scored greater than the overall
-- average and who have taken wickets greater than the overall average.

-- QUERY--
WITH batting AS (
    SELECT 
        p.Player_ID,
        p.Player_Name,
        COALESCE(SUM(b.Runs_Scored), 0) AS total_runs,
        COUNT(w.Player_Out) AS times_out,
        CASE 
            WHEN COUNT(w.Player_Out) = 0 THEN COALESCE(SUM(b.Runs_Scored), 0)
            ELSE CAST(SUM(b.Runs_Scored) AS FLOAT) / COUNT(w.Player_Out)
        END AS batting_average
    FROM player p
    LEFT JOIN ball_by_ball b
        ON p.Player_ID = b.Striker
    LEFT JOIN wicket_taken w
        ON w.Player_Out = p.Player_ID
           AND w.Match_Id = b.Match_Id
           AND w.Innings_No = b.Innings_No
           AND w.Over_Id = b.Over_Id
           AND w.Ball_Id = b.Ball_Id
    GROUP BY p.Player_ID, p.Player_Name
),
bowling AS (
    SELECT 
        p.Player_ID,
        p.Player_Name,
        COUNT(w.Player_Out) AS wickets,
        COALESCE(SUM(b.Runs_Scored),0) AS runs_conceded,
        CASE 
            WHEN COUNT(w.Player_Out) = 0 THEN NULL
            ELSE CAST(SUM(b.Runs_Scored) AS FLOAT) / COUNT(w.Player_Out)
        END AS bowling_average
    FROM player p
    LEFT JOIN ball_by_ball b
        ON p.Player_ID = b.Bowler
    LEFT JOIN wicket_taken w
        ON w.Match_Id = b.Match_Id
           AND w.Innings_No = b.Innings_No
           AND w.Over_Id = b.Over_Id
           AND w.Ball_Id = b.Ball_Id
    GROUP BY p.Player_ID, p.Player_Name
),
overall AS (
    -- Overall Batting Average
    SELECT 
        CAST(SUM(b.Runs_Scored) AS FLOAT) / NULLIF(SUM(
            CASE WHEN w.Player_Out IS NOT NULL THEN 1 ELSE 0 END
        ),0) AS overall_batting_avg,
        -- Overall Wickets Average per player
        (SELECT AVG(wickets_count) 
         FROM (
            SELECT COUNT(*) AS wickets_count
            FROM wicket_taken
            GROUP BY Player_Out
         ) x) AS overall_wickets_avg
    FROM ball_by_ball b
    LEFT JOIN wicket_taken w
        ON b.Ball_Id = w.Ball_Id
)
SELECT 
    ba.Player_ID,
    ba.Player_Name,
    ba.total_runs AS runs,
    ROUND(ba.batting_average,2) AS batting_average,
    bo.wickets,
    ROUND(bo.bowling_average,2) AS bowling_average
FROM batting ba
JOIN bowling bo
    ON ba.Player_ID = bo.Player_ID
CROSS JOIN overall o
WHERE ba.batting_average > o.overall_batting_avg
  AND bo.wickets > o.overall_wickets_avg
  AND ba.total_runs > 300 AND bo.wickets > 10 
ORDER BY Player_ID ;



-- ********************************************************************************************************
-- ********************************************************************************************************

-- 9. Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.

-- QUERY --
CREATE TABLE rcb_record AS 
SELECT v.Venue_Name , 
		SUM(CASE WHEN (m.Team_1 = 2 OR m.Team_2 = 2) 
				 AND m.Match_Winner = 2 THEN 1 ELSE 0 END ) AS Wins , 
		SUM(CASE WHEN (m.Team_1 = 2 OR m.Team_2 = 2) 
				 AND m.Match_Winner != 2 AND m.Match_Winner IS NOT NULL 
                 THEN 1 ELSE 0 END ) AS Losses 
FROM matches m 
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY v.Venue_Name ;
SELECT * 
FROM rcb_record ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 10. What is the impact of bowling style on wickets taken?

-- QUERY --
SELECT bs.Bowling_skill , 
		COUNT(*) AS Total_Wickets
FROM bowling_style bs 
JOIN player p ON bs.Bowling_Id = p.Bowling_skill
JOIN ball_by_ball bob ON bob.Bowler = p.Player_Id 
JOIN wicket_taken wt ON  bob.Match_Id = wt.Match_Id 
					AND bob.Over_Id = wt.Over_Id 
					AND bob.Ball_Id = wt.Ball_Id 
					AND bob.Innings_No = wt.Innings_No 
WHERE bs.Bowling_skill IS NOT NULL 
GROUP BY bs.Bowling_skill
ORDER BY Total_Wickets DESC ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 11. Write the SQL query to provide a status of whether the performance of the team 
-- is better than the previous year's performance on the basis of the number of runs 
-- scored by the team in the season and the number of wickets taken.

-- QUERY --
WITH team_runs AS (
    SELECT t.Team_Name, s.Season_Year,
			SUM(b.Runs_Scored) AS Total_Runs
    FROM team t 
    JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN ball_by_ball b ON m.Match_Id = b.Match_Id
    WHERE b.Team_Batting = t.Team_Id
    GROUP BY t.Team_Name, s.Season_Year
),
team_wickets AS (
		SELECT t.Team_Name, s.Season_Year,
				COUNT(w.Player_Out) AS Total_Wickets
		FROM team t 
		JOIN matches m ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
		JOIN season s ON m.Season_Id = s.Season_Id
		JOIN ball_by_ball b ON m.Match_Id = b.Match_Id
		JOIN wicket_taken w ON b.Match_Id = w.Match_Id 
			AND b.Over_Id = w.Over_Id 
			AND b.Ball_Id = w.Ball_Id 
			AND b.Innings_No = w.Innings_No
		WHERE b.Team_Bowling = t.Team_Id
		GROUP BY t.Team_Name, s.Season_Year
),
Wickets_Runs AS (
		SELECT r.Team_Name, r.Season_Year, r.Total_Runs,
			LAG(r.Total_Runs) OVER (PARTITION BY r.Team_Name ORDER BY r.Season_Year) AS Prev_Runs,
			COALESCE(w.Total_Wickets, 0) AS Total_Wickets,
			LAG(w.Total_Wickets) OVER (PARTITION BY w.Team_Name ORDER BY w.Season_Year) AS Prev_Wickets
		FROM team_runs r
		LEFT JOIN team_wickets w ON r.Team_Name = w.Team_Name 
				AND r.Season_Year = w.Season_Year
)
SELECT Team_Name, Season_Year, Total_Runs, Prev_Runs, Total_Wickets, Prev_Wickets,
		CASE
			WHEN Prev_Runs IS NULL OR Prev_Wickets IS NULL THEN "No Previous Data"
			WHEN Total_Runs > Prev_Runs AND Total_Wickets > Prev_Wickets THEN "Increased"
			WHEN Total_Runs < Prev_Runs AND Total_Wickets < Prev_Wickets THEN "Decreased"
			ELSE "Mixed"
		END AS Performance_Status
FROM Wickets_Runs
ORDER BY Team_Name, Season_Year;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 12. Can you derive more KPIs for the team strategy?

-- QUERY -- 
-- 1. Powerplay Performance
WITH powerplay_runs AS (
    SELECT 
        m.Season_Id,
        b.Team_Batting,
        SUM(b.Runs_Scored) AS Total_Runs
    FROM ball_by_ball b
    JOIN matches m ON b.Match_Id = m.Match_Id
    WHERE b.Over_Id IN (1, 2, 3, 4,5,6)
    GROUP BY m.Season_Id, b.Team_Batting
)
SELECT 
    t.Team_Name,
    pr.Season_Id,
    pr.Total_Runs
FROM powerplay_runs pr
JOIN team t ON pr.Team_Batting = t.Team_Id
WHERE Team_Name = 'Royal Challengers Bangalore'
ORDER BY pr.Season_Id;

-- 2.  Batting Performance
SELECT 
    p.Player_Name,
    SUM(b.Runs_Scored) AS Total_Runs,
    ROUND(SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id), 2) AS Strike_Rate
FROM ball_by_ball b 
JOIN player p ON b.Striker = p.Player_Id
WHERE Striker_Batting_Position BETWEEN 1 AND 8
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC, Strike_Rate DESC, p.Player_Name;

-- 3.  Bowling Performance
WITH bowling_stats AS (
    SELECT 
        b.Bowler,
        SUM(b.Runs_Scored) AS Runs_Conceded,
        COUNT(*) AS Balls_Bowled
    FROM ball_by_ball b
    GROUP BY b.Bowler
),
wickets_by_bowler AS (
    SELECT 
        b.Bowler,
        COUNT(*) AS Wickets
    FROM ball_by_ball b
    JOIN wicket_taken w 
        ON b.Match_Id = w.Match_Id 
        AND b.Innings_No = w.Innings_No
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id
    WHERE w.Player_Out IS NOT NULL
    GROUP BY b.Bowler
)
SELECT 
    p.Player_Name,
    COALESCE(w.Wickets, 0) AS Wickets,
    ROUND(bs.Runs_Conceded * 6.0 / bs.Balls_Bowled, 2) AS Economy
FROM bowling_stats bs
JOIN player p ON bs.Bowler = p.Player_Id
LEFT JOIN wickets_by_bowler w ON bs.Bowler = w.Bowler
ORDER BY Wickets DESC, Economy ASC;

-- 4.  Dot Ball Percentage (Batting)
SELECT
  p.Player_Name,
  ROUND(SUM(CASE WHEN b.Runs_Scored = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Dot_Ball_Percentage
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name;

-- 5.  Dot Ball Percentage (Bowling)
SELECT
  p.Player_Name,
  ROUND(SUM(CASE WHEN b.Runs_Scored = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Dot_Ball_Percentage
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_ID
WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name;



-- 6. Phase-Wise Performance
SELECT
  p.Player_Name,
  CASE 
    WHEN b.Over_Id BETWEEN 1 AND 6 THEN 'Powerplay'
    WHEN b.Over_Id BETWEEN 7 AND 15 THEN 'Middle Overs'
    ELSE 'Death Overs'
  END AS Phase,
  COUNT(*) AS Balls_Faced,
  SUM(b.Runs_Scored) AS Runs,
  ROUND(SUM(b.Runs_Scored * 1.0) / COUNT(*), 2) AS Runs_Per_Ball
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_ID
WHERE b.Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
GROUP BY p.Player_Name, Phase;



-- ********************************************************************************************************
-- ********************************************************************************************************

-- 13. Using SQL, write a query to find out the average wickets taken by 
-- each bowler in each venue. Also, rank them according to the average value.

-- QUERY --
WITH COMBINED AS (
		SELECT v.Venue_Name , p.Player_Name , 
				ROUND(COUNT(wt.Player_Out) * 1.0 / COUNT(DISTINCT bob.Match_Id) , 2) AS Avg_Wickets_Taken
		FROM ball_by_ball bob 
        JOIN player p ON bob.Bowler = p.Player_Id
        JOIN wicket_taken wt ON bob.Match_Id = wt.Match_Id 
							AND bob.Over_Id = wt.Over_Id 
							AND bob.Ball_Id = wt.Ball_Id 
							AND bob.Innings_No = wt.Innings_No
		JOIN matches m ON m.Match_Id = bob.Match_Id 
        JOIN venue v ON v.Venue_Id = m.Venue_Id 
        GROUP BY v.Venue_Name , p.Player_Name ) , 
RANKED AS ( 
		SELECT Venue_Name , Player_Name , Avg_Wickets_Taken , 
				DENSE_RANK() OVER(ORDER BY Avg_Wickets_Taken DESC) AS Rnk 
		FROM COMBINED ) 
SELECT * 
FROM RANKED 
ORDER BY  Rnk ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 14. Which of the given players have consistently performed well in past seasons?
-- (Will you use any visualization to solve the problem?)

-- QUERY -- 
-- (1) Consistent Performance of the batsman by Innings Played and Total Runs Scored in the seasons.
WITH cte AS (
    SELECT DISTINCT b.Striker AS Player_ID, p.Player_Name, 
        SUM(b.Runs_Scored) AS Total_Runs, 
        COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
        ROUND((SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id)), 2) AS Avg_Runs
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    JOIN matches m ON b.Match_Id = m.Match_Id
    GROUP BY b.Striker, p.Player_Name
)
SELECT * 
FROM cte
WHERE Total_Runs > 1500 AND Innings_Played > 40
ORDER BY Total_Runs DESC, Innings_Played DESC;

-- (2) Consistent Performance of the bowlers by Innings Played and Total Wickets Taken in the seasons.
WITH cte AS (
    SELECT DISTINCT b.Bowler AS Bowler_Id, p.Player_Name, 
        COUNT(w.Player_Out) AS Total_Wickets, 
        COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
        ROUND((COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id)), 2) AS Avg_Wickets_Taken
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
    JOIN wicket_taken w ON (b.Match_Id = w.Match_Id 
        AND b.Over_Id = w.Over_Id 
        AND b.Ball_Id = w.Ball_Id 
        AND b.Innings_No = w.Innings_No)
    JOIN matches m ON b.Match_Id = m.Match_Id
    GROUP BY b.Bowler, p.Player_Name
)
SELECT * 
FROM cte
WHERE Total_Wickets > 55 AND Innings_Played > 30
ORDER BY Total_Wickets DESC, Innings_Played DESC;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 15. Are there players whose performance is more suited to specific venues or conditions? 
-- (How would you present this using charts?) 

-- QUERY -- 
-- (1) Batsman whose performance are more suited to specific Venues:
WITH player_venue_stats AS (
    SELECT p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name,
        SUM(b.Runs_Scored) AS Total_Runs,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played,
        SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id) AS Avg_Runs_Venue
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name
),
player_overall_stats AS (
    SELECT p.Player_Id, p.Player_Name,
        SUM(b.Runs_Scored) AS Total_Runs,
        COUNT(DISTINCT b.Match_Id) AS Innings_Played,
        SUM(b.Runs_Scored) * 1.0 / COUNT(DISTINCT b.Match_Id) AS Avg_Runs_Overall
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    GROUP BY p.Player_Id, p.Player_Name
)
SELECT pvs.Player_Id, pvs.Player_Name, pvs.Venue_Name, pvs.Avg_Runs_Venue, pos.Avg_Runs_Overall,
		(pvs.Avg_Runs_Venue - pos.Avg_Runs_Overall) AS Avg_Difference
FROM player_venue_stats pvs
JOIN player_overall_stats pos ON pvs.Player_Id = pos.Player_Id
WHERE pvs.Innings_Played >= 5 -- Consider venues where the player has played at least 5 innings
ORDER BY pvs.Player_Name, Avg_Difference DESC;

-- (2) Bowlers whose performance are more suited to specific Venues:
WITH player_venue_stats AS (
    SELECT p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name,
		COUNT(w.Player_Out) AS Total_Wickets, 
		COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
		COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id) AS Avg_Wickets_Venue
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
	JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
			                and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
    JOIN matches m ON b.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Id, v.Venue_Name
),
player_overall_stats AS (
    SELECT p.Player_Id, p.Player_Name,
        COUNT(w.Player_Out) AS Total_Wickets, 
		COUNT(DISTINCT b.Match_Id) AS Innings_Played, 
		COUNT(w.Player_Out) / COUNT(DISTINCT b.Match_Id) AS Avg_Wickets_Overall
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
	JOIN wicket_taken w on (b.Match_Id = w.Match_Id and b.Over_Id = w.Over_Id 
			     and b.Ball_Id = w.Ball_Id and b.Innings_No = w.Innings_No)
    GROUP BY p.Player_Id, p.Player_Name
)
SELECT pvs.Player_Id, pvs.Player_Name, pvs.Venue_Name, pvs.Avg_Wickets_Venue, pos.Avg_Wickets_Overall,
       (pvs.Avg_Wickets_Venue - pos.Avg_Wickets_Overall) AS Avg_Difference
FROM player_venue_stats pvs
JOIN player_overall_stats pos ON pvs.Player_Id = pos.Player_Id
WHERE pvs.Innings_Played >= 5 -- Consider venues where the player has played at least 5 innings
ORDER BY pvs.Player_Name, Avg_Difference DESC;


-- ********************************************************************************************************
-- ********************************************************************************************************








                            






