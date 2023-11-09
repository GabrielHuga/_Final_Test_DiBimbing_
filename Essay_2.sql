-- Create dim_user table
CREATE TABLE dim_user (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(100),
    country VARCHAR(50)
);

-- Insert data into dim_user table
INSERT INTO dim_user (user_id, user_name, country)
SELECT DISTINCT user_id, user_name, country
FROM raw_users;

-- Create dim_post table
CREATE TABLE dim_post (
    post_id INT PRIMARY KEY,
    post_text VARCHAR(500),
    post_date DATE,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES dim_user(user_id)
);

-- Insert data into dim_post table
INSERT INTO dim_post (post_id, post_text, post_date, user_id)
SELECT DISTINCT rp.post_id, rp.post_text, rp.post_date, rp.user_id
FROM raw_posts rp;

-- Create dim_date table
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    day INT,
    month INT,
    year INT
);

-- Insert data into dim_date table
INSERT INTO dim_date (date_id, day, month, year)
SELECT DISTINCT rp.post_date, EXTRACT(day FROM rp.post_date), EXTRACT(month FROM rp.post_date), EXTRACT(year FROM rp.post_date)
FROM raw_posts rp;

-- Create fact_post_performance table
CREATE TABLE fact_post_performance (
    date_id DATE,
    post_id INT,
    views_count INT,
    likes_count INT,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (post_id) REFERENCES dim_post(post_id)
);

-- Populate fact_post_performance table by joining and aggregating data
INSERT INTO fact_post_performance (date_id, post_id, views_count, likes_count)
SELECT
    dd.date_id,
    dp.post_id,
    COUNT(DISTINCT rp.user_id) AS views_count,
    COUNT(DISTINCT rl.user_id) AS likes_count
FROM
    raw_posts rp
LEFT JOIN
    raw_likes rl ON rp.post_id = rl.post_id
JOIN
    dim_post dp ON rp.post_id = dp.post_id
JOIN
    dim_date dd ON rp.post_date = dd.date_id
GROUP BY
    dd.date_id, dp.post_id;

-- Create fact_daily_posts table
CREATE TABLE fact_daily_posts (
    date_id DATE,
    user_id INT,
    posts_count INT,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (user_id) REFERENCES dim_user(user_id)
);

-- Populate fact_daily_posts table by joining and aggregating data
INSERT INTO fact_daily_posts (date_id, user_id, posts_count)
SELECT
    dd.date_id,
    du.user_id,
    COUNT(DISTINCT rp.post_id) AS posts_count
FROM
    raw_posts rp
JOIN
    dim_user du ON rp.user_id = du.user_id
JOIN
    dim_date dd ON rp.post_date = dd.date_id
GROUP BY
    dd.date_id, du.user_id;