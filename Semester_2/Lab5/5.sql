-- 1. RANK / DENSE_RANK / ROW_NUMBER OVER 
-- Ранжировать произведения каждого композитора по длительности: 
-- вывести все три вида ранга — с пропуском позиций, без пропуска и порядковый номер строки
SELECT
    c.surname || ' ' || c.name AS Композитор,
    m.name AS Произведение,
    m.duration AS Длительность,
    RANK() OVER (
        PARTITION BY m.composer_id
        ORDER BY m.duration::interval
    ) AS Ранг,
    DENSE_RANK() OVER (
        PARTITION BY m.composer_id
        ORDER BY m.duration::interval
    ) AS Плотный_ранг,
    ROW_NUMBER() OVER (
        PARTITION BY m.composer_id
        ORDER BY m.duration::interval
    ) AS Порядковый_номер
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.duration IS NOT NULL
ORDER BY c.surname, m.duration::interval;



-- 2. ROW_NUMBER OVER 
-- Пронумеровать композиторов внутри каждой страны в порядке от старшего к младшему по дате рождения
SELECT
    co.name AS Страна,
    c.surname AS Фамилия,
    c.name AS Имя,
    c.date_birth AS Дата_рождения,
    ROW_NUMBER() OVER (
        PARTITION BY c.country_id
        ORDER BY c.date_birth ASC
    )              AS Номер_по_старшинству
FROM music.composer  AS c
JOIN music.countries AS co ON c.country_id = co.country_id
WHERE c.date_birth IS NOT NULL
ORDER BY co.name, c.date_birth;



-- 3. RANK OVER
-- Ранжировать произведения внутри каждого жанра по дате премьеры от самой ранней к самой поздней
SELECT
    g.name AS Жанр,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    RANK() OVER (
        PARTITION BY mg.genre_id
        ORDER BY m.premier_date ASC
    ) AS Ранг_в_жанре
FROM music.music AS m
JOIN music.music_genres AS mg ON m.music_id = mg.music_id
JOIN music.genres AS g  ON mg.genre_id = g.genre_id
WHERE m.premier_date IS NOT NULL
ORDER BY g.name, m.premier_date;



-- 4. DENSE_RANK OVER
-- Присвоить каждому произведению плотный ранг по году премьеры 
-- среди всех произведений базы данных — одинаковый год получает одинаковый ранг без пропуска позиций
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    EXTRACT(YEAR FROM m.premier_date) AS Год_премьеры,
    DENSE_RANK() OVER (
        ORDER BY EXTRACT(YEAR FROM m.premier_date) ASC
    ) AS Ранг_по_году
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY m.premier_date;



-- 5. NTILE(3) OVER
-- Разделить произведения каждого композитора на три хронологических периода
-- творчества (ранний, средний, поздний) по дате премьеры
SELECT
    c.surname AS Фамилия,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    CASE NTILE(3) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
    )
        WHEN 1 THEN '1 — Ранний период'
        WHEN 2 THEN '2 — Средний период'
        WHEN 3 THEN '3 — Поздний период'
    END AS Период_творчества
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY c.surname, m.premier_date;



-- 6. NTILE(4) OVER
-- Разбить всех композиторов на четыре равные группы по дате рождения 
-- и определить исторический квартиль каждого
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    c.date_birth AS Дата_рождения,
    NTILE(4) OVER (
        ORDER BY c.date_birth
    ) AS Исторический_квартиль
FROM music.composer AS c
WHERE c.date_birth IS NOT NULL
ORDER BY c.date_birth;



-- 7. PERCENT_RANK OVER
--Вычислить процентный ранг каждого композитора по дате рождения внутри его страны: 
-- показывает, какую долю коллег из той же страны он старше
SELECT
    co.name AS Страна,
    c.surname AS Фамилия,
    c.name AS Имя,
    c.date_birth AS Дата_рождения,
    ROUND(
        PERCENT_RANK() OVER (
            PARTITION BY c.country_id
            ORDER BY c.date_birth
        )::numeric * 100, 1
    ) AS Процентный_ранг_в_стране
FROM music.composer AS c
JOIN music.countries AS co ON c.country_id = co.country_id
WHERE c.date_birth IS NOT NULL
ORDER BY co.name, c.date_birth;



--  8. CUME_DIST OVER
-- Вычислить накопительную долю произведений по дате премьеры: 
-- показывает, какой процент всех произведений был впервые исполнен не позже данной даты
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    m.premier_date AS Дата_премьеры,
    ROUND(
        CUME_DIST() OVER (
            ORDER BY m.premier_date
        )::numeric * 100, 1
    )  AS Накопительная_доля_процент
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY m.premier_date;



-- 9. ROW_NUMBER в подзапросе — фильтрация TOP-1 на группу
-- Вывести самое раннее (по дате премьеры) произведение каждого композитора, 
-- используя ROW_NUMBER в подзапросе для фильтрации первой строки каждой группы
SELECT Фамилия, Произведение, Дата_премьеры
FROM (
    SELECT
        c.surname AS Фамилия,
        m.name AS Произведение,
        m.premier_date AS Дата_премьеры,
        ROW_NUMBER() OVER (
            PARTITION BY m.composer_id
            ORDER BY m.premier_date ASC
        ) AS Номер
    FROM music.music AS m
    JOIN music.composer AS c ON m.composer_id = c.composer_id
    WHERE m.premier_date IS NOT NULL
) AS ranked
WHERE Номер = 1
ORDER BY Дата_премьеры;



-- 10. RANK OVER 
-- Ранжировать организации-владельцы по количеству произведений внутри каждой страны: 
-- определить лидера среди организаций в каждой стране
SELECT
    co.name AS Страна,
    oo.name AS Организация,
    COUNT(moo.music_id) AS Количество_произведений,
    RANK() OVER (
        PARTITION BY oo.country_id
        ORDER BY COUNT(moo.music_id) DESC
    ) AS Ранг_в_стране
FROM music.organization_owners AS oo
JOIN music.countries AS co
    ON oo.country_id = co.country_id
JOIN music.music_organization_owners AS moo
    ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.organization_owner_id, oo.name, co.name, oo.country_id
ORDER BY co.name, Ранг_в_стране;