-- 1) Запрос с DISTINCT и функциями даты
-- Получить уникальный список композиторов с годами рождения и возрастом на момент смерти
SELECT DISTINCT 
    c.surname || ' ' || c.name as composer_name,
    EXTRACT(YEAR FROM c.date_birth) as birth_year,
    EXTRACT(YEAR FROM c.date_death) - EXTRACT(YEAR FROM c.date_birth) as age
FROM music.composer c
WHERE c.date_death IS NOT NULL
ORDER BY age DESC;


-- 2) Запрос с COUNT и MAX
-- Посчитать количество композиторов и самый поздний год рождения по странам
SELECT 
    co.name as country_name,
    COUNT(c.composer_id) as composer_count,
    MAX(EXTRACT(YEAR FROM c.date_birth)) as latest_birth_year
FROM music.countries co
JOIN music.composer c ON co.country_id = c.country_id
WHERE c.date_birth IS NOT NULL
GROUP BY co.country_id, co.name
HAVING COUNT(c.composer_id) > 0;


-- 3) Запрос с LIMIT
-- Найти 2 самых длинных названий произведений с их продолжительностью
SELECT 
    m.name as music_name,
    UPPER(LEFT(m.name, 1)) || LOWER(SUBSTRING(m.name FROM 2)) as formatted_name,
    LENGTH(m.name) as name_length,
    m.duration
FROM music.music m
WHERE m.duration IS NOT NULL
ORDER BY name_length DESC
LIMIT 2;


-- 4) Запрос с AVG
-- Рассчитать среднюю продолжительность произведений по жанрам
SELECT 
    g.name as genre_name,
    COUNT(mg.music_id) as music_count,
    ROUND(AVG(
        EXTRACT(HOUR FROM m.duration::time) * 60 + 
        EXTRACT(MINUTE FROM m.duration::time)
    ), 2) as avg_duration_minutes
FROM music.genres g
JOIN music.music_genres mg ON g.genre_id = mg.genre_id
JOIN music.music m ON mg.music_id = m.music_id
WHERE m.duration IS NOT NULL
GROUP BY g.genre_id, g.name
HAVING COUNT(mg.music_id) >= 2;


-- 5) Запрос с функциями даты и времени
-- Показать современные произведения с вычислением лет с момента создания
SELECT
    m.name as music_name,
    TO_CHAR(m.finished_date, 'DD.MM.YYYY') as formatted_date,
    m.finished_date,
    NOW() as current_timestamp,
    DATE_PART('year', NOW()) - DATE_PART('year', m.finished_date) as years_ago
FROM music.music m
WHERE m.finished_date IS NOT NULL
  AND m.finished_date > '2000-01-01'
ORDER BY m.finished_date DESC;


-- 6) Запрос с функциями строк и условиями
-- Найти композиторов с фамилиями на "ов" и преобразовать их фамилии
SELECT 
    c.surname,
    c.name,
    COALESCE(c.second_name, 'Нет отчества') as second_name,
    REPLACE(LOWER(c.surname), 'ов', '') as surname_without_ov,
    REVERSE(c.surname) as reversed_surname
FROM music.composer c
WHERE c.surname LIKE '%ов%'
  AND c.date_birth IS NOT NULL
ORDER BY c.surname;


-- 7) Запрос с математикой
-- Вычислить характеристики продолжительности произведений
SELECT 
    m.name as music_name,
    m.duration,
    EXTRACT(HOUR FROM m.duration::time) as hours,
    EXTRACT(MINUTE FROM m.duration::time) as minutes,
    EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time) as total_minutes,
    POWER(EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time), 2) as minutes_squared
FROM music.music m
WHERE m.duration IS NOT NULL
  AND EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time) > 60
ORDER BY total_minutes DESC;


-- 8) Запрос с ROUND
-- Анализ произведений по продолжительности
SELECT 
    name as composition_name,
    duration,
    EXTRACT(HOUR FROM duration::time) * 60 + EXTRACT(MINUTE FROM duration::time) as total_minutes,
    ROUND(POWER(EXTRACT(HOUR FROM duration::time) * 60 + EXTRACT(MINUTE FROM duration::time), 1.2), 1) as weighted_duration,
    ABS(60 - (EXTRACT(HOUR FROM duration::time) * 60 + EXTRACT(MINUTE FROM duration::time))) as deviation_from_hour
FROM music.music
WHERE duration IS NOT NULL
  AND EXTRACT(HOUR FROM duration::time) * 60 + EXTRACT(MINUTE FROM duration::time) BETWEEN 10 AND 120
ORDER BY total_minutes DESC;


-- 9) COUNT and etc.
-- Статистика композиторов по датам жизни
SELECT 
    COUNT(*) as total_composers,
    MIN(date_birth) as earliest_birth,
    MAX(date_birth) as latest_birth,
    AVG(EXTRACT(YEAR FROM date_birth)) as avg_birth_year,
    COUNT(CASE WHEN date_death IS NOT NULL THEN 1 END) as composers_with_known_death,
    ROUND(AVG(EXTRACT(YEAR FROM date_death) - EXTRACT(YEAR FROM date_birth))) as avg_lifespan_years
FROM music.composer
WHERE date_birth IS NOT NULL;


-- 10) Запрос с округлением
-- Округлить продолжительность произведений в разных вариантах
SELECT 
    m.name as music_name,
    m.duration,
    EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time) as exact_minutes,
    CEILING(EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time)) as rounded_up_minutes,
    FLOOR(EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time)) as rounded_down_minutes
FROM music.music m
WHERE m.duration IS NOT NULL
  AND EXTRACT(HOUR FROM m.duration::time) * 60 + EXTRACT(MINUTE FROM m.duration::time) BETWEEN 30 AND 120;