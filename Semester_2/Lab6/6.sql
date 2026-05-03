DROP VIEW IF EXISTS music.v_composer_works;
DROP VIEW IF EXISTS music.v_russian_composers;
DROP VIEW IF EXISTS music.v_symphony_works;

-- 1. music.v_composer_works
--Представление на основе нескольких таблиц
-- Объединяет таблицы composer, music и countries. Выводит полное имя композитора, 
-- его страну, название произведения, дату премьеры и длительность
CREATE VIEW music.v_composer_works AS
SELECT
    c.composer_id,
    c.surname || ' ' || c.name AS Композитор,
    co.name AS Страна,
    m.music_id,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    m.duration AS Длительность
FROM music.composer AS c
JOIN music.music AS m ON c.composer_id = m.composer_id
JOIN music.countries AS co ON c.country_id = co.country_id;

SELECT *
FROM music.v_composer_works
ORDER BY Страна, Композитор, Дата_премьеры;



-- 2. music.v_russian_composers
-- Обновляемое представление (WITH CHECK OPTION)
-- Фильтрует таблицу composer по стране «Россия»
CREATE VIEW music.v_russian_composers AS
SELECT
    composer_id,
    name,
    surname,
    second_name,
    country_id,
    date_birth,
    date_death
FROM music.composer
WHERE country_id = (SELECT country_id
    FROM music.countries
    WHERE name = 'Россия')
WITH CHECK OPTION;

-- Вставка допустимой строки — российский композитор
INSERT INTO music.v_russian_composers
    (composer_id, name, surname, country_id, date_birth)
VALUES
    (8, 'Сергей', 'Рахманинов', 1, '1873-04-01');

--Попытка вставить иностранного композитора — нарушение CHECK OPTION
INSERT INTO music.v_russian_composers
    (composer_id, name, surname, country_id, date_birth)
VALUES
    (9, 'Рихард', 'Вагнер', 2, '1813-05-22');

-- Выборка:
SELECT surname, name, date_birth, date_death
FROM music.v_russian_composers
ORDER BY date_birth;



-- 3. music.v_symphony_works
-- Изменение (ALTER VIEW) и удаление (DROP VIEW)]
CREATE VIEW music.v_symphony_works AS
SELECT
    m.name AS Произведение,
    c.surname AS Композитор
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
JOIN music.music_genres AS mg ON m.music_id = mg.music_id
JOIN music.genres AS g ON mg.genre_id = g.genre_id
WHERE g.name = 'Симфония';

-- Изменение представления:
CREATE OR REPLACE VIEW music.v_symphony_works AS
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    m.premier_date AS Дата_премьеры,
    co.name AS Страна_премьеры
FROM music.music AS m
    JOIN music.composer AS c ON m.composer_id = c.composer_id
    JOIN music.countries AS co ON m.country_id = co.country_id
    JOIN music.music_genres AS mg ON m.music_id = mg.music_id
    JOIN music.genres AS g ON mg.genre_id = g.genre_id
WHERE g.name = 'Симфония';

SELECT *
FROM music.v_symphony_works
ORDER BY Дата_премьеры;

-- Удаление представления:
DROP VIEW IF EXISTS music.v_symphony_works;