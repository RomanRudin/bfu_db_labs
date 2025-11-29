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
ORDER BY comp.surname;


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


-- 3) Запрос с RIGHT JOIN
-- Найти произведения с длинными названиями и преобразовать имена композиторов
SELECT 
    mus.name as music_name,
    comp.surname as composer_surname,
    LENGTH(mus.name) as title_length,
    SUBSTRING(mus.name FROM 1 FOR 20) as short_title,
    LOWER(comp.surname) as lower_surname
FROM music.music mus
RIGHT JOIN music.composer comp ON mus.composer_id = comp.composer_id
WHERE mus.duration IS NOT NULL
  AND LENGTH(mus.name) > 15
ORDER BY title_length DESC;


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


-- 5) Запрос с двумя INNER JOIN
-- Рассчитать среднюю продолжительность произведений по композиторам и жанрам
SELECT 
    comp.surname || ' ' || LEFT(comp.name, 1) || '.' as composer_short,
    gen.name as genre_name,
    COUNT(mg.music_id) as compositions_count,
    ROUND(AVG(
        EXTRACT(HOUR FROM mus.duration::time) * 60 + 
        EXTRACT(MINUTE FROM mus.duration::time)
    ), 1) as avg_duration_minutes
FROM music.composer comp
INNER JOIN music.music mus ON comp.composer_id = mus.composer_id
INNER JOIN music.music_genres mg ON mus.music_id = mg.music_id
INNER JOIN music.genres gen ON mg.genre_id = gen.genre_id
WHERE mus.duration IS NOT NULL
  AND mus.finished_date IS NOT NULL
GROUP BY comp.composer_id, comp.surname, comp.name, gen.genre_id, gen.name
HAVING COUNT(mg.music_id) >= 2
ORDER BY avg_duration_minutes DESC;


-- 6) Запрос с LEFT JOIN и RIGHT JOIN
-- Получить информацию о произведениях и организациях владельцах за определенный перио
SELECT 
    mus.name as composition_name,
    TO_CHAR(mus.finished_date, 'YYYY-MM-DD') as formatted_date,
    comp.surname as composer_surname,
    org.name as organization_name,
    DATE_PART('year', mus.finished_date) as composition_year
FROM music.music mus
LEFT JOIN music.composer comp ON mus.composer_id = comp.composer_id
RIGHT JOIN music.music_organization_owners moo ON mus.music_id = moo.music_id
RIGHT JOIN music.organization_owners org ON moo.organization_owner_id = org.organization_owner_id
WHERE mus.finished_date BETWEEN '1900-01-01' AND '2000-01-01'
ORDER BY mus.finished_date;


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


-- 8) Запрос с несколькими JOIN
-- Получить подробную информацию о произведениях
SELECT 
    comp.surname || ' ' || comp.name as full_composer_name,
    cntr.name as composer_country,
    mus.name as music_name,
    gen.name as genre_name,
    REVERSE(comp.surname) as reversed_surname,
    REPEAT('*', LENGTH(comp.surname) / 2) as surname_stars
FROM music.composer comp
INNER JOIN music.countries cntr ON comp.country_id = cntr.country_id
INNER JOIN music.music mus ON comp.composer_id = mus.composer_id
INNER JOIN music.music_genres mg ON mus.music_id = mg.music_id
INNER JOIN music.genres gen ON mg.genre_id = gen.genre_id
WHERE comp.date_birth IS NOT NULL
  AND gen.name LIKE '%симфония%'
ORDER BY comp.surname, mus.name;


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