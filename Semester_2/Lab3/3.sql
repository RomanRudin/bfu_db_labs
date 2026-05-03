-- 1. CASE в SELECT
-- 1.1 Классифицировать произведения по продолжительности: 
-- короткое (до 30 мин), среднее (30–60 мин), длинное (более 60 мин)
SELECT
    m.name AS Произведение,
    m.duration AS Длительность,
    CASE
        WHEN m.duration::interval < INTERVAL '30 minutes'
            THEN 'Короткое'
        WHEN m.duration::interval <= INTERVAL '1 hour'
            THEN 'Среднее'
        ELSE 'Длинное'
    END AS Категория_длительности
FROM music.music AS m
WHERE m.duration IS NOT NULL
ORDER BY m.duration::interval;

-- 1.2 Вывести список композиторов с пометкой: жив или умер
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    c.date_birth AS Дата_рождения,
    c.date_death AS Дата_смерти,
    CASE
        WHEN c.date_death IS NULL THEN 'Жив'
        ELSE 'Умер'
    END AS Статус
FROM music.composer AS c
ORDER BY c.surname;



-- 2. CASE в SELECT + ORDER BY
-- 2.3 Классифицировать произведения по эпохе премьеры: 
-- Барокко/Классицизм (до 1800), Романтизм (1800–1899), 
-- Современная музыка (с 1900), Неизвестно (нет даты)
SELECT
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    CASE
        WHEN m.premier_date IS NULL
            THEN 'Неизвестно'
        WHEN EXTRACT(YEAR FROM m.premier_date) < 1800
            THEN 'Барокко / Классицизм'
        WHEN EXTRACT(YEAR FROM m.premier_date) BETWEEN 1800 AND 1899
            THEN 'Романтизм'
        ELSE 'Современная музыка'
    END AS Эпоха
FROM music.music AS m
ORDER BY m.premier_date;



-- 3. CASE в SELECT + GROUP BY + ORDER BY
-- 3.4 Подсчитать количество произведений каждого композитора 
-- и присвоить категорию продуктивности: нет произведений, 
-- малопродуктивный (1), продуктивный (2–3), высокопродуктивный (4 и более)
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    COUNT(m.music_id) AS Количество_произведений,
    CASE
        WHEN COUNT(m.music_id) = 0
            THEN 'Нет произведений'
        WHEN COUNT(m.music_id) = 1
            THEN 'Малопродуктивный'
        WHEN COUNT(m.music_id) BETWEEN 2 AND 3
            THEN 'Продуктивный'
        ELSE 'Высокопродуктивный'
    END AS Категория
FROM music.composer AS c
LEFT JOIN music.music AS m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.surname, c.name
ORDER BY Количество_произведений DESC;



-- 4. CASE в SELECT + подзапрос EXISTS
-- 4.5 Вывести список произведений с указанием статуса владения: 
-- есть хотя бы один владелец (частный или организация) или владельцев нет
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    CASE
        WHEN EXISTS (
                 SELECT 1 FROM music.private_owners_music AS pom
                 WHERE pom.music_id = m.music_id)
            OR EXISTS (
                 SELECT 1 FROM music.music_organization_owners AS moo
                 WHERE moo.music_id = m.music_id)
            THEN 'Есть владелец'
        ELSE 'Без владельца'
    END AS Статус_владения
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
ORDER BY m.name;



-- 5. CASE в SELECT + GROUP BY + ORDER BY
-- 5.6 Подсчитать количество произведений в каждом жанре и оценить
-- его популярность: очень популярный (5+), популярный (3–4), 
-- редкий (1–2), не представлен (0)
SELECT
    g.name                 AS Жанр,
    COUNT(mg.music_id)     AS Количество_произведений,
    CASE
        WHEN COUNT(mg.music_id) >= 5 THEN 'Очень популярный'
        WHEN COUNT(mg.music_id) BETWEEN 3 AND 4 THEN 'Популярный'
        WHEN COUNT(mg.music_id) BETWEEN 1 AND 2 THEN 'Редкий'
        ELSE 'Не представлен'
    END AS Популярность
FROM music.genres AS g
LEFT JOIN music.music_genres AS mg ON g.genre_id = mg.genre_id
GROUP BY g.genre_id, g.name
ORDER BY Количество_произведений DESC;

-- 5.7 Вывести организации-владельцы с количеством произведений 
-- и пометкой: отечественная (Россия) или иностранная
SELECT
    oo.name AS Организация,
    co.name AS Страна,
    COUNT(moo.music_id) AS Количество_произведений,
    CASE
        WHEN co.name = 'Россия' THEN 'Отечественная'
        ELSE 'Иностранная'
    END AS Тип_организации
FROM music.organization_owners AS oo
JOIN music.countries AS co
    ON oo.country_id = co.country_id
JOIN music.music_organization_owners AS moo
    ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.organization_owner_id, oo.name, co.name
ORDER BY Тип_организации, oo.name;



-- 6. CASE в WHERE
-- 6.8 Вывести произведения с применением условной фильтрации: 
-- для жанра «Симфония» показывать только произведения после 1800 года, 
--для «Сонаты» — после 1750 года, остальные жанры — без ограничений по дате
SELECT
    m.name AS Произведение,
    g.name AS Жанр,
    m.premier_date AS Дата_премьеры
FROM music.music AS m
JOIN music.music_genres AS mg ON m.music_id = mg.music_id
JOIN music.genres AS g ON mg.genre_id = g.genre_id
WHERE 1 = CASE
    WHEN g.name = 'Симфония'
         AND EXTRACT(YEAR FROM m.premier_date) > 1800 THEN 1
    WHEN g.name = 'Соната'
         AND EXTRACT(YEAR FROM m.premier_date) > 1750 THEN 1
    WHEN g.name NOT IN ('Симфония', 'Соната') THEN 1
    ELSE 0
END
ORDER BY g.name, m.premier_date;



-- 7. CASE в ORDER BY
-- 7.9 Вывести произведения с датой премьеры, отсортировав их по
-- приоритету страны: сначала российские, затем немецкие, австрийские, 
-- и остальные; внутри каждой группы — по дате премьеры
SELECT
    m.name AS Произведение,
    co.name AS Страна_премьеры,
    m.premier_date AS Дата_премьеры
FROM music.music AS m
JOIN music.countries AS co ON m.country_id = co.country_id
ORDER BY
    CASE co.name
        WHEN 'Россия' THEN 1
        WHEN 'Германия' THEN 2
        WHEN 'Австрия' THEN 3
        ELSE 4
    END,
    m.premier_date;



-- 8. CASE в SELECT + WHERE + ORDER BY
-- 8.10 Вывести умерших композиторов с количеством прожитых лет и категорией: 
-- ранняя смерть (до 40 лет), средний возраст (40–70 лет), долгожитель (более 70 лет)
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    EXTRACT(YEAR FROM AGE(c.date_death, c.date_birth))
               AS Прожито_лет,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(c.date_death, c.date_birth)) < 40
            THEN 'Ранняя смерть'
        WHEN EXTRACT(YEAR FROM AGE(c.date_death, c.date_birth)) BETWEEN 40 AND 70
            THEN 'Средний возраст'
        ELSE 'Долгожитель'
    END AS Категория_возраста
FROM music.composer AS c
WHERE c.date_death IS NOT NULL
ORDER BY Прожито_лет;