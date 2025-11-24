
-- Enugu Saketh Reddy 
-- RCB - STRATEGY FOR IPL 

USE ipl ; 

-- SUBJECTIVE QUESTIONS --

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 1. How does the toss decision affect the result of the match? 
-- (Which visualisations could be used to present your answer better?) 
-- And is the impact limited to only specific venues?

-- QUERY -- 
WITH MATCHVENUE AS (
		SELECT m.Match_Id , v.Venue_Name, m.Toss_Winner, m.Match_Winner , 
				td.Toss_Name AS Toss_Descion , 
                t1.Team_Id AS Team1_Id , t1.Team_Name AS Team1_Name ,
                t2.Team_Id AS Team2_Id , t2.Team_Name AS Team2_Name 
        FROM matches m 
        JOIN venue v ON m.Venue_Id = v.Venue_Id
        JOIN toss_decision td ON td.Toss_Id = m.Toss_Decide
        JOIN team t1 ON m.Team_1 = t1.Team_Id 
        JOIN team t2 ON m.Team_2 = t2.Team_Id ) , 
FULLTABLE AS (
		SELECT Match_Id , Venue_Name , Toss_Winner , Match_Winner ,Toss_Descion , Team1_Id AS Team_Id , Team1_Name as Team_Name
        FROM MATCHVENUE 
        UNION ALL 
        SELECT Match_Id , Venue_Name , Toss_Winner , Match_Winner ,Toss_Descion , Team2_Id AS Team_Id , Team2_Name as Team_Name
        FROM MATCHVENUE ) 
SELECT Team_Name , Venue_Name , 
		COUNT(DISTINCT Match_Id) AS Played_Matches , 
        COUNT(DISTINCT CASE WHEN Team_Id = Toss_Winner THEN Match_Id END ) AS Toss_Wins , 
        Toss_Descion , 
		COUNT(DISTINCT CASE WHEN Team_Id = Match_Winner THEN Match_Id END ) AS Match_Wins , 
        ROUND(COUNT(DISTINCT CASE WHEN Team_Id = Match_Winner THEN Match_Id END )*100 / COUNT(DISTINCT Match_Id) , 2) AS Win_Percentage 
FROM FULLTABLE 
GROUP BY Team_Name , Venue_Name , Toss_Descion
ORDER BY Team_Name , Venue_Name ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 2. Suggest some of the players who would be best fit for the team?

-- QUERY -- 
-- (1) Top Batsmen
SELECT 
    DISTINCT p.Player_Name, 
    SUM(b.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT b.Match_Id) AS Matches_Played, 
    ROUND((SUM(b.Runs_Scored) * 100.0 / COUNT(b.Ball_Id)), 2) AS Strike_Rate
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC LIMIT 10;

-- (2) Top Bowlers
SELECT
    DISTINCT p.Player_Name, 
    COUNT(w.Player_Out) AS Total_Wickets, 
    COUNT(DISTINCT b.Match_Id) AS Matches_Played, 
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(w.Player_Out), 0), 2) AS Bowling_Avg,
    ROUND(SUM(b.Runs_Scored) / (COUNT(*) / 6.0), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
LEFT JOIN wicket_taken w 
    ON b.Match_Id = w.Match_Id 
    AND b.Over_Id = w.Over_Id 
    AND b.Ball_Id = w.Ball_Id 
    AND b.Innings_No = w.Innings_No
JOIN matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Name
HAVING COUNT(*) >= 60
ORDER BY Total_Wickets DESC LIMIT 10;

-- (3) Top All-Rounders
SELECT
    p.Player_Name,
    SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(DISTINCT CASE WHEN b.Striker = p.Player_Id THEN b.Match_Id END) AS Matches_Played,
    ROUND(
        SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) /
        NULLIF(COUNT(DISTINCT CASE WHEN b.Striker = p.Player_Id THEN b.Match_Id END), 0),
        2
    ) AS Batting_Avg,
    COUNT(DISTINCT CASE 
        WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL 
        THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) 
    END) AS Total_Wickets,
    ROUND(
        SUM(CASE WHEN b.Bowler = p.Player_Id THEN b.Runs_Scored ELSE 0 END) /
        NULLIF(COUNT(DISTINCT CASE 
            WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL 
            THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) 
        END), 0),
        2
    ) AS Bowling_Avg
FROM ball_by_ball b
JOIN player p ON p.Player_Id IN (b.Striker, b.Bowler)
LEFT JOIN wicket_taken w 
    ON b.Match_Id = w.Match_Id
    AND b.Over_Id = w.Over_Id
    AND b.Ball_Id = w.Ball_Id
    AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY 
    (SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) + 
     COUNT(DISTINCT CASE 
         WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL 
         THEN CONCAT(b.Match_Id, '-', b.Over_Id, '-', b.Ball_Id) 
     END) * 20) DESC
LIMIT 10;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 3. What are some of parameters that should be focused while selecting the players?

-- QUERY -- 
-- (1) Batting Performance
SELECT 
    p.Player_Name,
    SUM(b.Runs_Scored) AS Total_Runs,
    COUNT(CASE WHEN w.Player_Out IS NOT NULL THEN 1 END) AS Times_Out,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(CASE WHEN w.Player_Out IS NOT NULL THEN 1 END), 0), 2) AS Batting_Average
FROM ball_by_ball b
JOIN player p ON b.Striker = p.Player_Id
LEFT JOIN wicket_taken w 
    ON b.Match_Id = w.Match_Id 
    AND b.Over_Id = w.Over_Id 
    AND b.Ball_Id = w.Ball_Id 
    AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC LIMIT 10;

-- (2) Bowling Performance
SELECT 
    p.Player_Name,
    COUNT(w.Player_Out) AS Total_Wickets,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(w.Player_Out), 0), 2) AS Bowling_Average,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(DISTINCT CONCAT(b.Match_Id, '-', b.Over_Id)), 0), 2) AS Economy_Rate
FROM ball_by_ball b
JOIN player p ON b.Bowler = p.Player_Id
LEFT JOIN wicket_taken w 
    ON b.Match_Id = w.Match_Id 
    AND b.Over_Id = w.Over_Id 
    AND b.Ball_Id = w.Ball_Id 
    AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY Total_Wickets DESC LIMIT 10;

-- (3) All-Rounder Performance
SELECT 
    p.Player_Name,
    SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
    COUNT(CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END) AS Total_Wickets,
    ROUND(
        SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) + 
        20 * COUNT(CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END),
        2
    ) AS All_Rounder_Score
FROM ball_by_ball b
JOIN player p ON p.Player_Id IN (b.Striker, b.Bowler)
LEFT JOIN wicket_taken w 
    ON b.Match_Id = w.Match_Id 
    AND b.Over_Id = w.Over_Id 
    AND b.Ball_Id = w.Ball_Id 
    AND b.Innings_No = w.Innings_No
GROUP BY p.Player_Name
ORDER BY All_Rounder_Score DESC LIMIT 10;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 4. Which players offer versatility in their skills and can contribute effectively with both bat and ball? 
-- (can you visualize the data for the same)

-- QUERY -- 
WITH Batting AS (
    SELECT p.Player_Name,
        SUM(CASE WHEN b.Striker = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Total_Runs,
        COUNT(CASE WHEN b.Striker = p.Player_Id AND w.Player_Out IS NOT NULL THEN 1 END) AS Times_Out
    FROM ball_by_ball b
    JOIN player p ON b.Striker = p.Player_Id
    LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id
        AND b.Over_Id = w.Over_Id
        AND b.Ball_Id = w.Ball_Id
        AND b.Innings_No = w.Innings_No
    GROUP BY p.Player_Name
),
Bowling AS (
    SELECT p.Player_Name,
        COUNT(DISTINCT CASE WHEN b.Bowler = p.Player_Id AND w.Player_Out IS NOT NULL THEN CONCAT(b.Match_Id,'-',b.Over_Id,'-',b.Ball_Id) END) AS Total_Wickets,
        SUM(CASE WHEN b.Bowler = p.Player_Id THEN b.Runs_Scored ELSE 0 END) AS Runs_Conceded
    FROM ball_by_ball b
    JOIN player p ON b.Bowler = p.Player_Id
    LEFT JOIN wicket_taken w ON b.Match_Id = w.Match_Id
        AND b.Over_Id = w.Over_Id
        AND b.Ball_Id = w.Ball_Id
        AND b.Innings_No = w.Innings_No
    GROUP BY p.Player_Name
)
SELECT b.Player_Name, b.Total_Runs, bo.Total_Wickets,
    ROUND(b.Total_Runs / NULLIF(b.Times_Out, 0), 2) AS Batting_Average,
    ROUND(bo.Runs_Conceded / NULLIF(bo.Total_Wickets, 0), 2) AS Bowling_Average
FROM Batting b
JOIN Bowling bo ON b.Player_Name = bo.Player_Name
WHERE b.Total_Runs > 500 AND bo.Total_Wickets > 20
ORDER BY (b.Total_Runs + (bo.Total_Wickets * 20)) DESC;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 5. Are there players whose presence positively influences the morale and performance of the team? 
-- (justify your answer using visualisation)

-- QUERY -- 
-- (1) Choose a player
SELECT 
    pm.Player_ID, 
    p.Player_Name, 
    COUNT(*) AS Matches_Played
FROM player_match pm
JOIN player p ON pm.Player_ID = p.Player_ID
GROUP BY pm.Player_ID, p.Player_Name
ORDER BY Matches_Played DESC
LIMIT 20;  -- Chosen Player_Id = 21 (For Example)

-- (2) Team Win Rate When the Player Played and When the Player Did NOT Play
WITH player_matches AS (
    SELECT Match_ID, Team_ID
    FROM player_match
    WHERE Player_ID = 21
),
player_teams AS (
    SELECT DISTINCT Team_ID
    FROM player_matches
),
team_matches AS (
    SELECT Match_ID,
           CASE 
               WHEN Team_1 IN (SELECT Team_ID FROM player_teams) THEN Team_1
               ELSE Team_2
           END AS Team_ID
    FROM matches
    WHERE Team_1 IN (SELECT Team_ID FROM player_teams)
       OR Team_2 IN (SELECT Team_ID FROM player_teams)
),
matches_without_player AS (
    SELECT tm.Match_ID, tm.Team_ID
    FROM team_matches tm
    WHERE NOT EXISTS (
        SELECT 1
        FROM player_matches pm
        WHERE pm.Match_ID = tm.Match_ID
    )
),
matches_with_player AS (
    SELECT pm.Match_ID, pm.Team_ID
    FROM player_matches pm
)
SELECT 
    'With Player' AS Scenario,
    COUNT(*) AS Total_Matches,
    SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) AS Wins,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN matches_with_player mwp ON m.Match_ID = mwp.Match_ID
UNION ALL
SELECT 
    'Without Player' AS Scenario,
    COUNT(*) AS Total_Matches,
    SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) AS Wins,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = mwp.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM matches m
JOIN matches_without_player mwp ON m.Match_ID = mwp.Match_ID;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 6. What would you suggest to RCB before going to mega auction ?

-- QUERY -- 
-- (1) Players with highest match impact for RCB
WITH rcb_players AS (
    SELECT p.Player_ID, Player_Name, Team_ID, Match_ID
    FROM player_match pm
    JOIN player p ON pm.Player_ID = p.Player_ID
    WHERE pm.Team_ID = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
)
SELECT 
    Player_Name,
    COUNT(*) AS Matches_Played,
    SUM(CASE WHEN m.Match_Winner = rcb.Team_ID THEN 1 ELSE 0 END) AS Wins_With_Player,
    ROUND(100.0 * SUM(CASE WHEN m.Match_Winner = rcb.Team_ID THEN 1 ELSE 0 END) / COUNT(*), 2) AS Win_Percentage
FROM rcb_players rcb
JOIN matches m ON rcb.Match_ID = m.Match_ID
GROUP BY Player_Name
HAVING COUNT(*) > 20
ORDER BY Win_Percentage DESC;

-- (2) Death over bowling economy for RCB
WITH rcb_bowling AS (
    SELECT b.Bowler AS Player_ID, b.Over_Id, b.Runs_Scored, b.Match_ID
    FROM ball_by_ball b
    WHERE b.Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
      AND b.Over_Id BETWEEN 16 AND 20
)
SELECT 
    p.Player_Name,
    COUNT(DISTINCT rb.Match_ID) AS Matches_Played,
    COUNT(DISTINCT rb.Over_Id) AS Overs_Bowled,
    ROUND(SUM(rb.Runs_Scored) * 6.0 / COUNT(*), 2) AS Economy_Rate
FROM rcb_bowling rb
JOIN player p ON rb.Player_ID = p.Player_ID
GROUP BY p.Player_Name
HAVING COUNT(*) > 20
ORDER BY Economy_Rate ASC;

-- (3) RCB batting collapse by phase
WITH rcb_batting AS (
    SELECT Over_Id, Runs_Scored
    FROM ball_by_ball
    WHERE Team_Batting = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
)
SELECT
  CASE 
    WHEN Over_Id BETWEEN 1 AND 6 THEN 'Powerplay'
    WHEN Over_Id BETWEEN 7 AND 15 THEN 'Middle Overs'
    ELSE 'Death Overs'
  END AS Phase,
  COUNT(DISTINCT Over_Id) AS Total_Overs,
  ROUND(SUM(Runs_Scored * 1.0) / COUNT(*), 2) AS Runs_Per_Ball
FROM rcb_batting
GROUP BY Phase;

-- (4) Players performing best against RCB
WITH rcb_against AS (
    SELECT Striker AS Player_ID, Runs_Scored
    FROM ball_by_ball
    WHERE Team_Bowling = (SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore')
)
SELECT 
    p.Player_Name,
    SUM(r.Runs_Scored) AS Runs_Against_RCB
FROM rcb_against r
JOIN player p ON r.Player_ID = p.Player_ID
GROUP BY p.Player_Name
HAVING SUM(r.Runs_Scored) > 150
ORDER BY Runs_Against_RCB DESC;


-- ********************************************************************************************************
-- ********************************************************************************************************

-- 7. What do you think could be the factors contributing to the high-scoring matches and the impact 
-- on viewership and team strategies?

-- QUERY -- 
-- (1) High-scoring partnerships
WITH partnerships AS (
    SELECT 
        b.Striker, 
        b.Non_Striker, 
        SUM(b.Runs_Scored) AS Total_Partnership_Runs,
        COUNT(*) AS Balls_Faced
    FROM ball_by_ball b
    GROUP BY b.Striker, b.Non_Striker
)
SELECT 
    p1.Player_Name AS Striker,
    p2.Player_Name AS Non_Striker,
    Balls_Faced,
    Total_Partnership_Runs
FROM partnerships ps
JOIN player p1 ON ps.Striker = p1.Player_Id
JOIN player p2 ON ps.Non_Striker = p2.Player_Id
WHERE Total_Partnership_Runs > 30
ORDER BY Total_Partnership_Runs DESC;


-- (2a) Close matches for excitement
WITH close_matches AS (
    SELECT m.Match_ID, w.Win_Type, m.Win_Margin
    FROM matches m
    JOIN win_by w ON m.Win_Type = w.Win_Id
    WHERE (w.Win_Type = 'runs' AND m.Win_Margin <= 10)
       OR (w.Win_Type = 'wickets' AND m.Win_Margin <= 2)
)
SELECT * FROM close_matches;


-- (2b) Chasing team wins after field decision
WITH chasing_wins AS (
    SELECT m.Match_ID, t.Team_Name AS Team_Won, td.Toss_Name
    FROM matches m
    LEFT JOIN team t ON m.Match_Winner = t.Team_Id
    LEFT JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    WHERE td.Toss_Name = 'field' AND t.Team_Id = m.Toss_Winner
)
SELECT * FROM chasing_wins;


-- (2c) Death overs drama
WITH death_overs AS (
    SELECT 
        b.Match_ID,
        b.Over_Id,
        SUM(b.Runs_Scored) AS Death_Over_Runs,
        COUNT(CASE WHEN w.Player_Out IS NOT NULL THEN 1 END) AS Death_Over_Wickets
    FROM ball_by_ball b
    LEFT JOIN wicket_taken w 
        ON b.Match_Id = w.Match_Id
        AND b.Over_Id = w.Over_Id
        AND b.Ball_Id = w.Ball_Id
        AND b.Innings_No = w.Innings_No
    WHERE b.Over_Id BETWEEN 16 AND 20
    GROUP BY b.Match_ID, b.Over_Id
)
SELECT * FROM death_overs;


-- (3a) Batsmen with high strike rate and average
WITH batting_stats AS (
    SELECT 
        b.Striker AS Player_ID,
        SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_ID) AS Batting_Avg,
        (SUM(b.Runs_Scored) * 100.0) / COUNT(*) AS Strike_Rate,
        SUM(CASE WHEN b.Runs_Scored IN (4, 6) THEN 1 ELSE 0 END) AS Boundary_Count,
        COUNT(DISTINCT b.Match_ID) AS Matches_Played
    FROM ball_by_ball b
    GROUP BY b.Striker
)
SELECT 
    p.Player_Name AS Striker,
    Batting_Avg,
    Strike_Rate,
    Boundary_Count
FROM batting_stats bs
JOIN player p ON bs.Player_ID = p.Player_Id
WHERE Matches_Played > 10
ORDER BY Strike_Rate DESC;


-- (3b) Players performing best against RCB
WITH against_rcb AS (
    SELECT b.Striker AS Player_ID, SUM(b.Runs_Scored) AS Runs_Against_RCB
    FROM ball_by_ball b
    JOIN matches m ON b.Match_ID = m.Match_ID
    WHERE b.Team_Bowling = (
        SELECT Team_ID FROM team WHERE Team_Name = 'Royal Challengers Bangalore'
    )
    GROUP BY b.Striker
)
SELECT 
    p.Player_Name,
    Runs_Against_RCB
FROM against_rcb rcb
JOIN player p ON rcb.Player_ID = p.Player_Id
WHERE Runs_Against_RCB > 150
ORDER BY Runs_Against_RCB DESC;




-- ********************************************************************************************************
-- ********************************************************************************************************

-- 8. Analyse the impact of home-ground advantage on team performance and 
-- identify strategies to maximize this advantage for RCB.

-- QUERY -- 
SELECT 
	CASE 
		WHEN v.Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home' 
        ELSE 'Away' 
	END AS Place , 
    COUNT(*) AS Matches , 
    SUM(CASE WHEN Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Wins , 
    ROUND(SUM(CASE WHEN Match_Winner = t.Team_Id THEN 1 ELSE 0 END)*100/COUNT(*),2) AS Win_Percentage
FROM matches m 
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN team t ON t.Team_Name = 'Royal Challengers Bangalore'
WHERE t.Team_Id IN ( m.Team_1 , m.Team_2) 
GROUP BY Place ;

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 9. Come up with a visual and analytical analysis of the RCB's past season's performance and 
-- potential reasons for them not winning a trophy.

-- QUERY -- 
WITH CTE AS (
    SELECT 
        m.Match_Id,
        v.Venue_Name,
        CASE 
            WHEN t.Team_Id = m.Team_1 THEN t2.Team_Name 
            ELSE t1.Team_Name 
        END AS Opponent,
        CASE 
            WHEN m.Match_Winner = t.Team_Id THEN 1 
            ELSE 0
        END AS Result,
        m.Match_Date
    FROM matches m
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    JOIN team t ON t.Team_Name = 'Royal Challengers Bangalore'
    JOIN team t1 ON m.Team_1 = t1.Team_Id
    JOIN team t2 ON m.Team_2 = t2.Team_Id
    WHERE m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id 
			AND m.Match_Winner IS NOT NULL )
SELECT * 
FROM CTE
ORDER BY Match_Date;
		

-- ********************************************************************************************************
-- ********************************************************************************************************

-- 11. In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" instead 
-- of "Delhi_Daredevils". Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".

-- QUERY -- 
UPDATE team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Name = 'Delhi Capitals' ;

-- ********************************************************************************************************
-- ********************************************************************************************************






