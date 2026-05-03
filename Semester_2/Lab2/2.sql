-- 1. GROUP BY 
-- 1.1 Подсчитать количество музыкальных произведений каждого композитора
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    COUNT(m.music_id) AS Количество_произведений
FROM music.composer AS c
JOIN music.music AS m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.surname, c.name;

-- 1.2 Подсчитать количество музыкальных произведений в каждом жанре
SELECT
    g.name AS Жанр,
    COUNT(mg.music_id) AS Количество_произведений
FROM music.genres AS g
JOIN music.music_genres AS mg ON g.genre_id = mg.genre_id
GROUP BY g.genre_id, g.name;

-- 1.3 Подсчитать количество композиторов из каждой страны
SELECT
    co.name AS Страна,
    COUNT(c.composer_id) AS Количество_произведений
FROM music.countries AS co
JOIN music.composer AS c ON co.country_id = c.country_id
GROUP BY co.country_id, co.name;



-- 2. GROUP BY + WHERE
-- 2.4 Подсчитать количество произведений для каждого умершего композитора
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    COUNT(m.music_id) AS Количество_произведений
FROM music.composer AS c
JOIN music.music AS m ON c.composer_id = m.composer_id
WHERE c.date_death IS NOT NULL
GROUP BY c.composer_id, c.surname, c.name;

-- 2.5 Подсчитать количество произведений по жанрам, чья премьера состоялась после 1800 года
SELECT
    g.name AS Жанр,
    COUNT(mg.music_id) AS Количество_произведений
FROM music.genres AS g
JOIN music.music_genres AS mg ON g.genre_id = mg.genre_id
JOIN music.music AS m ON mg.music_id = m.music_id
WHERE m.premier_date > '1800-01-01'
GROUP BY g.genre_id, g.name;



-- 3. GROUP BY + ORDER BY
-- 3.6 Подсчитать количество произведений по странам премьеры, отсортировать по убыванию
SELECT
    co.name AS Страна_премьеры,
    COUNT(m.music_id) AS Количество_произведений
FROM music.countries AS co
JOIN music.music AS m ON co.country_id = m.country_id
GROUP BY co.country_id, co.name
ORDER BY Количество_произведений DESC;

-- 3.7 Подсчитать количество произведений в собственности каждой организации, 
-- отсортировать по названию организации
SELECT
    oo.name AS Организация,
    COUNT(moo.music_id) AS Количество_произведений
FROM music.organization_owners AS oo
JOIN music.music_organization_owners AS moo
    ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.organization_owner_id, oo.name
ORDER BY oo.name ASC;



-- 4. GROUP BY + HAVING
-- 4.8 Найти композиторов, у которых более одного музыкального произведения
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    COUNT(m.music_id) AS Количество_произведений
FROM music.composer AS c
JOIN music.music AS m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.surname, c.name
HAVING COUNT(m.music_id) > 1;

-- 4.9 Найти жанры, которым присвоено более двух произведений
SELECT
    g.name AS Жанр,
    COUNT(mg.music_id) AS Количество_произведений
FROM music.genres AS g
JOIN music.music_genres AS mg ON g.genre_id = mg.genre_id
GROUP BY g.genre_id, g.name
HAVING COUNT(mg.music_id) > 2;



-- 5. GROUP BY + WHERE + HAVING
-- 5.10 Найти частных владельцев, имеющих более одного произведения, 
-- среди тех, у кого указана страна проживания
SELECT
    po.surname AS Фамилия,
    po.name AS Имя,
    COUNT(pom.music_id) AS Количество_произведений
FROM music.private_owners AS po
JOIN music.private_owners_music AS pom
    ON po.private_owner_id = pom.private_owner_id
WHERE po.country_id IS NOT NULL
GROUP BY po.private_owner_id, po.surname, po.name
HAVING COUNT(pom.music_id) > 1;