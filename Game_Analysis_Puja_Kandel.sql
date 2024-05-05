use game_analysis;

-- 1. Extract P_ID, Dev_ID, PName, and Difficulty_level of all players at Level 0.
SELECT pd.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty AS Difficulty_level
FROM player_details pd
JOIN level_details2 ld ON pd.P_ID = ld.P_ID
WHERE ld.Level = 0;

-- 2. Find Level1_code wise average Kill_Count where Lives_Earned is 2 and at least 3 stages are crossed.
SELECT pd.L1_Code, AVG(ld.Kill_Count) AS Avg_Kill_Count
FROM player_details pd
JOIN level_details2 ld ON pd.P_ID = ld.P_ID
WHERE ld.Lives_Earned = 2 AND ld.Stages_crossed >= 3
GROUP BY pd.L1_Code;

-- 3. Find the total number of stages crossed at each difficulty level for Level 2 with players using zm_series devices.
SELECT ld.Difficulty, SUM(ld.Stages_crossed) AS Total_Stages_Crossed
FROM level_details2 ld
JOIN player_details pd ON pd.P_ID = ld.P_ID
WHERE ld.Level = 2 AND ld.Dev_ID REGEXP '^zm_series'
GROUP BY ld.Difficulty
ORDER BY Total_Stages_Crossed DESC;


-- 4. Extract P_ID and the total number of unique dates for those players who have played games on multiple days.
SELECT P_ID, COUNT(DISTINCT DATE(TimeStamp)) AS Unique_Dates
FROM level_details2
GROUP BY P_ID
HAVING COUNT(DISTINCT DATE(TimeStamp)) > 1;


-- 5. Find P_ID and levelwise sum of kill_counts where kill_count is greater than the average kill count for Medium difficulty.
SELECT ld.P_ID, ld.Level, SUM(ld.Kill_Count) AS Total_Kill_Count
FROM level_details2 ld
JOIN (
    SELECT Difficulty, AVG(Kill_Count) AS Avg_Kill_Count
    FROM level_details2
    WHERE Difficulty = 'Medium'
    GROUP BY Difficulty
) AS avg_kill ON ld.Difficulty = avg_kill.Difficulty
WHERE ld.Kill_Count > avg_kill.Avg_Kill_Count
GROUP BY ld.P_ID, ld.Level;


-- 6. Find Level and its corresponding Level_Code wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.
SELECT ld.Level, pd.L2_Code, SUM(ld.Lives_Earned) AS Total_Lives_Earned
FROM player_details pd
JOIN level_details2 ld ON pd.P_ID = ld.P_ID
WHERE ld.Level != 0
GROUP BY ld.Level, pd.L2_Code
ORDER BY ld.Level;

-- 7. Find the top 3 scores based on each Dev_ID and rank them in increasing order using Row_Number. Display the difficulty as well.
SELECT ld.Dev_ID, ld.Score, ld.Difficulty,
       ROW_NUMBER() OVER(PARTITION BY ld.Dev_ID ORDER BY ld.Score DESC) AS rnk
FROM level_details2 ld
ORDER BY ld.Dev_ID, rnk limit 3;



-- 8. Find the first_login datetime for each device ID.
SELECT Dev_ID, MIN(TimeStamp) AS first_login
FROM level_details2
GROUP BY Dev_ID;

-- 9. Find the top 5 scores based on each difficulty level and rank them in increasing order using Rank. Display Dev_ID as well.
SELECT Dev_ID, Score, Difficulty,
       RANK() OVER(PARTITION BY Difficulty ORDER BY Score DESC) AS rnk
FROM level_details2
LIMIT 5;

-- 10. Find the device ID that is first logged in (based on TimeStamp) for each player (P_ID). Output should contain player ID, device ID, and first login datetime.
SELECT ld.P_ID, ld.Dev_ID, MIN(ld.TimeStamp) AS first_login
FROM level_details2 ld
GROUP BY ld.P_ID, ld.Dev_ID;


-- 11a. For each player and date, determine how many kill_counts were played by the player so far using window functions.
SELECT P_ID, DATE(TimeStamp) AS Date,
       SUM(Kill_Count) OVER(PARTITION BY P_ID ORDER BY TimeStamp) AS Total_Kill_Count
FROM level_details2;

-- 11b. Without window functions.
SELECT P_ID, DATE(TimeStamp) AS Date,
       (SELECT SUM(Kill_Count) FROM level_details2 sub WHERE sub.P_ID = ld.P_ID AND sub.TimeStamp <= ld.TimeStamp) AS Total_Kill_Count
FROM level_details2 ld;

-- 12. Find the cumulative sum of stages crossed over TimeStamp for each P_ID, excluding the most recent TimeStamp.
SELECT P_ID, SUM(Stages_crossed) AS Cumulative_Stages_Crossed
FROM (
    SELECT P_ID, Stages_crossed,
           ROW_NUMBER() OVER(PARTITION BY P_ID ORDER BY TimeStamp DESC) AS rn
    FROM level_details2
) AS sub
WHERE rn > 1
GROUP BY P_ID;

-- 13. Extract the top 3 highest sums of scores for each Dev_ID and the corresponding P_ID.
SELECT ld.Dev_ID, ld.P_ID, SUM(ld.Score) AS Total_Score
FROM level_details2 ld
GROUP BY ld.Dev_ID, ld.P_ID
ORDER BY Total_Score DESC
LIMIT 3;

-- 14. Find players who scored more than 50% of the average score, scored by the sum of scores for each P_ID.
SELECT ld.P_ID
FROM level_details2 ld
GROUP BY ld.P_ID
HAVING SUM(ld.Score) > 0.5 * (
    SELECT AVG(Total_Score)
    FROM (
        SELECT SUM(Score) AS Total_Score
        FROM level_details2
        GROUP BY P_ID
    ) AS sub
);

-- 15. Create a stored procedure to find the top n Headshots_Count based on each Dev_ID and rank them in increasing order using Row_Number. Display the difficulty as well.
DELIMITER //

CREATE PROCEDURE GetTopHeadshotsCount(
    IN n INT
)
BEGIN
    SET @sql = CONCAT(
        'SELECT Dev_ID, Headshots_Count, Difficulty, ',
        'ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY Headshots_Count DESC) AS Rank ',
        'FROM level_details2 ',
        'LIMIT ', n
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//

DELIMITER ;










