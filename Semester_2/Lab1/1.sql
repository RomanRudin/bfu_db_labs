-- 1 Скалярные подзапросы
-- 1.1 Произведение с самой поздней датой премьеры
SELECT m.name, 
       c.name || ' ' || c.surname AS composer_name, 
       m.premier_date
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE m.premier_date = (SELECT MAX(premier_date) 
       FROM music.music 
       WHERE premier_date IS NOT NULL);

-- 1.2 Композиторы, у которых произведений больше среднего
SELECT c.composer_id, 
       c.name, 
       c.surname, 
       COUNT(m.music_id) AS music_count
FROM music.composer c
LEFT JOIN music.music m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.name, c.surname
HAVING COUNT(m.music_id) > (SELECT AVG(music_count) 
       FROM (SELECT COUNT(music_id) AS music_count 
             FROM music.music 
             GROUP BY composer_id) AS avg_counts);

-- 1.3 Произведение с самой ранней датой завершения
SELECT m.name, 
       m.finished_date, 
       c.name, 
       c.surname
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE m.finished_date = (SELECT MIN(finished_date) 
       FROM music.music 
       WHERE finished_date IS NOT NULL);

-- 1.4 Жанры, чей средний год завершения выше общего среднего
SELECT g.name AS genre_name, 
       AVG(EXTRACT(YEAR FROM m.finished_date)) AS avg_finish_year
FROM music.genres g
JOIN music.music_genres mg ON g.genre_id = mg.genre_id
JOIN music.music m ON mg.music_id = m.music_id
WHERE m.finished_date IS NOT NULL
GROUP BY g.name
HAVING AVG(EXTRACT(YEAR FROM m.finished_date)) > (SELECT AVG(EXTRACT(YEAR FROM finished_date)) 
       FROM music.music 
       WHERE finished_date IS NOT NULL);

-- 1.5 Организации‑владельцы с количеством произведений больше суммарного количества организаций из России
SELECT oo.name, 
       COUNT(moo.music_id) AS total_music
FROM music.organization_owners oo
JOIN music.music_organization_owners moo ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.organization_owner_id, oo.name
HAVING COUNT(moo.music_id) > (SELECT SUM(sub.cnt) 
       FROM (SELECT COUNT(moo2.music_id) AS cnt 
              FROM music.organization_owners oo2
              JOIN music.music_organization_owners moo2 ON oo2.organization_owner_id = moo2.organization_owner_id
              JOIN music.countries c ON oo2.country_id = c.country_id
              WHERE c.name = 'Россия'
              GROUP BY oo2.organization_owner_id) sub);



-- 2 Табличные подзапросы
-- 2.1 Произведения в жанре Симфония
SELECT m.name, 
       m.duration, 
       c.name || ' ' || c.surname AS composer_name
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE m.music_id IN (SELECT mg.music_id 
       FROM music.music_genres mg 
       JOIN music.genres g ON mg.genre_id = g.genre_id 
       WHERE g.name = 'Симфония');

-- 2.2 Произведения без зарегистрированных владельцев
SELECT m.name, 
       m.composer_id
FROM music.music m
WHERE m.music_id NOT IN (SELECT music_id FROM music.private_owners_music
       UNION
       SELECT music_id FROM music.music_organization_owners);

-- 2.3 Произведения, премьера которых позже хотя бы одной премьеры композитора из России
SELECT m.name, 
       m.premier_date, 
       c.name, 
       c.surname
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE m.premier_date > ANY (SELECT m2.premier_date 
       FROM music.music m2
       JOIN music.composer c2 ON m2.composer_id = c2.composer_id
       WHERE c2.country_id = (SELECT country_id 
              FROM music.countries 
              WHERE name = 'Россия')
              AND m2.premier_date IS NOT NULL);

-- 2.4 Организации, владеющие бóльшим числом произведений, чем все частные владельцы
SELECT oo.name, 
       COUNT(moo.music_id) AS music_count
FROM music.organization_owners oo
JOIN music.music_organization_owners moo ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.name
HAVING COUNT(moo.music_id) > ALL (SELECT COUNT(pom.music_id) 
       FROM music.private_owners po
       JOIN music.private_owners_music pom ON po.private_owner_id = pom.private_owner_id
       GROUP BY po.private_owner_id);

-- 2.5 Композиторы, у которых есть произведение, когда‑либо проданное частному владельцу
SELECT c.composer_id, 
       c.name, 
       c.surname
FROM music.composer c
WHERE EXISTS (SELECT 1 
       FROM music.music m 
       JOIN music.private_owners_music pom ON m.music_id = pom.music_id 
       WHERE m.composer_id = c.composer_id);



-- 3. Объединение подзапросов
-- 3.1 Все владельцы (частные и организации) с указанием типа
SELECT 'Часрник' AS owner_type, 
       po.name || ' ' || po.surname AS full_name, 
       c.name AS country
FROM music.private_owners po
LEFT JOIN music.countries c ON po.country_id = c.country_id
UNION
SELECT 'Организация', 
       oo.name, 
       c.name
FROM music.organization_owners oo
LEFT JOIN music.countries c ON oo.country_id = c.country_id;

-- 3.2. Произведения, сгруппированные по дате завершения (до/после 1800), с дублями
SELECT m.name, 
       c.name || ' ' || c.surname AS composer, 
       'После 1800' AS period
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE EXTRACT(YEAR FROM m.finished_date) > 1800
UNION ALL
SELECT m.name, 
       c.name || ' ' || c.surname, 
       'Иное'
FROM music.music m
JOIN music.composer c ON m.composer_id = c.composer_id
WHERE EXTRACT(YEAR FROM m.finished_date) <= 1800 OR m.finished_date IS NULL;

-- 3.3. Произведения, имеющие одновременно жанры Симфония и Соната
SELECT m.name, 
       m.music_id
FROM music.music m
WHERE m.music_id IN (SELECT music_id 
       FROM music.music_genres mg 
       JOIN music.genres g ON mg.genre_id = g.genre_id 
       WHERE g.name = 'Симфония'
       INTERSECT
       SELECT music_id 
       FROM music.music_genres mg 
       JOIN music.genres g ON mg.genre_id = g.genre_id 
       WHERE g.name = 'Соната');

-- 3.4. Произведения в жанре Симфония, но не в жанре Концерт
SELECT m.name
FROM music.music m
WHERE m.music_id IN (SELECT music_id 
       FROM music.music_genres mg 
       JOIN music.genres g ON mg.genre_id = g.genre_id 
       WHERE g.name = 'Симфония'
       EXCEPT
       SELECT music_id 
       FROM music.music_genres mg 
       JOIN music.genres g ON mg.genre_id = g.genre_id 
       WHERE g.name = 'Концерт');

-- 3.5. Количество произведений по композиторам и общее количество с сортировкой
SELECT 'Композитор: ' || c.name || ' ' || c.surname AS description, 
       COUNT(m.music_id) AS count
FROM music.composer c
LEFT JOIN music.music m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.name, c.surname
UNION
SELECT 'Всего по композиторам: ', 
       COUNT(*)
FROM music.music
ORDER BY count DESC;