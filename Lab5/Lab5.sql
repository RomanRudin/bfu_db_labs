-- 1) Запрос с INNER JOIN, DISTINCT
-- Получить уникальных композиторов с их странами и преобразованными данными
SELECT DISTINCT 
    comp.surname || ' ' || comp.name as composer_full_name,
    cntr.name as country_name,
    EXTRACT(YEAR FROM comp.date_birth) as birth_year,
    UPPER(LEFT(comp.surname, 3)) as surname_prefix
FROM music.composer comp
INNER JOIN music.countries cntr ON comp.country_id = cntr.country_id
WHERE comp.date_birth IS NOT NULL
ORDER BY composer_full_name;


-- 2) Запрос с LEFT JOIN, GROUP BY
-- Проанализировать статистику композиторов и произведений по странам
SELECT 
    cntr.name as country_name,
    COUNT(DISTINCT comp.composer_id) as composer_count,
    COUNT(mus.music_id) as music_count,
    MAX(EXTRACT(YEAR FROM mus.finished_date)) as latest_composition_year
FROM music.countries cntr
LEFT JOIN music.composer comp ON cntr.country_id = comp.country_id
LEFT JOIN music.music mus ON comp.composer_id = mus.composer_id
WHERE cntr.name IN ('Россия', 'Польша', 'Германия')
GROUP BY cntr.country_id, cntr.name
ORDER BY music_count DESC;


-- 3) Запрос с INNER JOIN
-- Анализ произведений по жанрам
SELECT 
    g.name as genre_name,
    m.name as music_name,
    comp.surname || ' ' || LEFT(comp.name, 1) || '.' as composer_short,
    UPPER(SUBSTRING(m.name FROM 1 FOR 3)) as music_code,
    LENGTH(m.name) as title_length,
    TO_CHAR(m.finished_date, 'YYYY') as creation_year,
    ROUND(EXTRACT(EPOCH FROM (m.duration::time)) / 60, 1) as duration_minutes
FROM music.genres g
INNER JOIN music.music_genres mg ON g.genre_id = mg.genre_id
INNER JOIN music.music m ON mg.music_id = m.music_id
INNER JOIN music.composer comp ON m.composer_id = comp.composer_id
WHERE m.finished_date BETWEEN '1800-01-01' AND '2030-01-01'
  AND m.duration IS NOT NULL
  AND LENGTH(m.name) > 5
ORDER BY duration_minutes DESC, genre_name
LIMIT 3;


-- 4) Запрос с FULL OUTER JOIN и DISTINCT
-- Создать полный список владельцев и стран с обработкой отсутствующих данных
SELECT DISTINCT
    COALESCE(po.name, 'Неизвестно') as owner_name,
    COALESCE(cntr.name, 'Неизвестно') as country_name,
    LOWER(COALESCE(po.surname, '')) as owner_surname_lower
FROM music.private_owners po
FULL OUTER JOIN music.countries cntr ON po.country_id = cntr.country_id
WHERE po.private_owner_id IS NOT NULL
   OR cntr.country_id IS NOT NULL;


-- 5) Запрос с двумя LEFT JOIN
-- Статистика по жанрам с расчетом средней продолжительности
SELECT 
    g.name as genre_name,
    COUNT(mg.music_id) as compositions_count,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (m.duration::time)) / 60
    ), 2) as avg_duration_minutes,
    MIN(EXTRACT(EPOCH FROM (m.duration::time)) / 60) as min_duration_minutes,
    MAX(EXTRACT(EPOCH FROM (m.duration::time)) / 60) as max_duration_minutes
FROM music.genres g
LEFT JOIN music.music_genres mg ON g.genre_id = mg.genre_id
LEFT JOIN music.music m ON mg.music_id = m.music_id
WHERE m.duration IS NOT NULL
GROUP BY g.genre_id, g.name
HAVING COUNT(mg.music_id) > 0
ORDER BY compositions_count DESC;


-- 6) Запрос с LEFT JOIN и RIGHT JOIN
-- Статистика по странам и композиторам
SELECT DISTINCT
    cntr.name as country_name,
    COUNT(DISTINCT comp.composer_id) as total_composers,
    COUNT(DISTINCT m.music_id) as total_compositions,
    STRING_AGG(DISTINCT comp.surname, ', ' ORDER BY comp.surname) as composers_list,
    ROUND(AVG(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM comp.date_birth)), 1) as avg_composer_age,
    SUM(EXTRACT(EPOCH FROM (m.duration::time)) / 60) as total_duration_minutes
FROM music.countries cntr
FULL JOIN music.composer comp ON cntr.country_id = comp.country_id
FULL JOIN music.music m ON comp.composer_id = m.composer_id
WHERE comp.date_birth IS NOT NULL
  AND m.duration IS NOT NULL
  AND EXTRACT(YEAR FROM comp.date_birth) > 1700
GROUP BY cntr.country_id, cntr.name
HAVING COUNT(DISTINCT comp.composer_id) > 0
ORDER BY total_compositions DESC, country_name;


-- 7) Запрос с INNER JOIN
-- Проанализировать характеристики продолжительности произведений
SELECT 
    mus.name as music_title,
    comp.surname as composer,
    mus.duration,
    EXTRACT(HOUR FROM mus.duration::time) * 60 + 
    EXTRACT(MINUTE FROM mus.duration::time) as total_minutes,
    ROUND(POWER(
        EXTRACT(HOUR FROM mus.duration::time) * 60 + 
        EXTRACT(MINUTE FROM mus.duration::time), 1.5
    ), 2) as duration_power
FROM music.music mus
INNER JOIN music.composer comp ON mus.composer_id = comp.composer_id
WHERE mus.duration IS NOT NULL
  AND EXTRACT(HOUR FROM mus.duration::time) * 60 + 
      EXTRACT(MINUTE FROM mus.duration::time) > 30;


-- 8) Запрос с FULL JOIN
-- Aнализ композиторов и их произведений
SELECT 
    comp.surname || ' ' || comp.name as composer_name,
    cntr.name as composer_country,
    COUNT(m.music_id) as total_compositions,
    STRING_AGG(m.name, '; ' ORDER BY m.finished_date) as compositions_list,
    ROUND(AVG(EXTRACT(EPOCH FROM (m.duration::time)) / 60), 1) as avg_composition_minutes,
    SUM(EXTRACT(EPOCH FROM (m.duration::time)) / 60) as total_minutes
FROM music.composer comp
FULL JOIN music.countries cntr ON comp.country_id = cntr.country_id
FULL JOIN music.music m ON comp.composer_id = m.composer_id
WHERE m.finished_date IS NOT NULL
  AND m.duration IS NOT NULL
GROUP BY comp.composer_id, comp.surname, comp.name, cntr.name
HAVING COUNT(m.music_id) >= 1
ORDER BY total_minutes DESC, total_compositions DESC;


-- 9) Запрос с FULL JOIN
-- Собрать статистику по композиторам и странам
SELECT 
    COALESCE(comp.surname, 'Без композитора') as composer_info,
    COALESCE(cntr.name, 'Неизвестная страна') as country_info,
    COUNT(mus.music_id) as music_count,
    MIN(EXTRACT(YEAR FROM mus.finished_date)) as earliest_year,
    MAX(EXTRACT(YEAR FROM mus.finished_date)) as latest_year
FROM music.composer comp
FULL JOIN music.countries cntr ON comp.country_id = cntr.country_id
FULL JOIN music.music mus ON comp.composer_id = mus.composer_id
WHERE mus.finished_date IS NOT NULL
   OR comp.composer_id IS NOT NULL
GROUP BY comp.surname, cntr.name
HAVING COUNT(mus.music_id) > 0
ORDER BY music_count DESC;


-- 10) Запрос с INNER JOIN, LIMIT и ORDER BY
-- Получить ограниченный список современных произведений с округленной продолжительностью
SELECT 
    mus.name as composition,
    comp.surname as composer,
    cntr.name as country,
    TO_CHAR(mus.finished_date, 'Month YYYY') as finished_month_year,
    CEILING(
        EXTRACT(HOUR FROM mus.duration::time) * 60 + 
        EXTRACT(MINUTE FROM mus.duration::time)
    ) as rounded_minutes
FROM music.music mus
INNER JOIN music.composer comp ON mus.composer_id = comp.composer_id
INNER JOIN music.countries cntr ON comp.country_id = cntr.country_id
WHERE mus.finished_date IS NOT NULL
  AND mus.duration IS NOT NULL
  AND EXTRACT(YEAR FROM mus.finished_date) > 1950
ORDER BY mus.finished_date DESC
LIMIT 10;