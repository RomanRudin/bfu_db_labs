DELETE FROM music.private_owners_music;
DELETE FROM music.music_organization_owners;
DELETE FROM music.genres;
DELETE FROM music.music;
DELETE FROM music.composer;
DELETE FROM music.private_owners;
DELETE FROM music.organization_owners;
DELETE FROM music.genres;
DELETE FROM music.countries;

DELETE FROM music.music_archive;
DELETE FROM music.composer_countries;
DELETE FROM music.long_compositions;
DELETE FROM music.russian_composers_works;
DELETE FROM music.genres_simple;

--  INSERT операции:
-- 1.1) Добавление нескольких стран одной командой
INSERT INTO music.countries (country_id, name) VALUES
(1, 'Россия'),
(2, 'Польша');

-- 1.2) Добавление нескольких жанров одной командой
INSERT INTO music.genres (genre_id, name, description) VALUES
(1, 'Симфония', 'Ну симфония, да'),
(2, 'Опера', 'Опера это опера');

-- 1.3) Добавление нескольких композиторов одной командой
INSERT INTO music.composer (composer_id, name, surname, second_name, country_id, date_birth, date_death) VALUES
(1, 'Иван', 'Иванов', 'Иванович', 1, '26-11-2024', NULL),
(2, 'Петр', 'Петров', 'Петрович', 1, '26-11-2024', NULL),
(3, 'Семён', 'Семёнов', 'Семёнович', 2, '25-11-2024', '26-11-2024');

-- 1.4) Добавление музыкальных произведений одной командой
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date, premier_date, premier_place, country_id) VALUES
(1, 1, 'Симфония 1', '02:20', '26-11-2024', '26-11-2024', 'Калининград', 2),
(2, 2, 'Симфония 2', '01:15', '26-11-2024', '26-11-2024', 'Калининград', 2);

-- 1.5) Добавление частных владельцев одной командой
INSERT INTO music.private_owners (private_owner_id, name, surname, second_name, address, country_id) VALUES
(1, 'Иван', 'Петров', 'Семёнович', 'Москва, 10', 1),
(2, 'Петр', 'Иванов', 'Семёнович', 'Санкт-Петербург', 1);

-- Добавление связей произведений с жанрами
INSERT INTO music.music_genres (music_id, genre_id) VALUES
(1, 1), (1, 2), -- Симфония 1 - симфония, опера
(2, 1); -- Симфония 2 - симфония




--  INSERT INTO ... SELECT операции:
-- 2.1) Копирование всех произведений в архивную таблицу
INSERT INTO music.music_archive 
SELECT * FROM music.music;
SELECT * FROM music.music_archive;

-- 2.2) Создание списка композиторов с названиями их стран
INSERT INTO music.composer_countries 
SELECT 
    c.composer_id,
    c.surname || ' ' || c.name as composer_name,
    (SELECT name FROM music.countries WHERE country_id = c.country_id) as country_name
FROM music.composer c;
SELECT * FROM music.composer_countries;

-- 2.3) Копирование только произведений более 30 минут
INSERT INTO music.long_compositions 
SELECT music_id, name, duration, finished_date
FROM music.music 
WHERE duration > '00:30';
SELECT * FROM music.long_compositions;

-- 2.4) Создание списка российских композиторов и их произведений
INSERT INTO music.russian_composers_works 
SELECT 
    music.composer.composer_id,
    music.composer.surname || ' ' || music.composer.name as composer,
    (SELECT name FROM music.music WHERE composer_id = music.composer.composer_id AND music_id = 
	(SELECT MIN(music_id) FROM music.music WHERE composer_id = music.composer.composer_id)) as composition,
    (SELECT finished_date FROM music.music WHERE composer_id = music.composer.composer_id AND music_id = 
	(SELECT MIN(music_id) FROM music.music WHERE composer_id = music.composer.composer_id)) as finished_date
FROM music.composer
WHERE music.composer.country_id = 1;
SELECT * FROM music.russian_composers_works;

-- 2.5) Создание упрощенного списка жанров
INSERT INTO music.genres_simple 
SELECT 
    genre_id,
    UPPER(name) as genre_name
FROM music.genres;
SELECT * FROM music.genres_simple;



--  UPDATE операции:
-- 3.1) Обновление страны для всех произведений композитора
UPDATE music.music
SET country_id = (
    SELECT country_id
    FROM music.composer
    WHERE composer_id = 1
)
WHERE composer_id = 1;

-- 3.2) Исправление дат премьер для произведений определенного периода
UPDATE music.music
SET premier_date = finished_date + INTERVAL '1 year',
    premier_place = 'Москва'
WHERE finished_date BETWEEN '25-11-2024' AND '25-12-2024'
AND country_id = 1;

-- 3.3) Копирование произведений длительностью более 30 минут
INSERT INTO music.long_music 
SELECT music_id, name, duration, finished_date
FROM music.music 
WHERE duration > '00:30';

-- 3.4) Создание статистики по странам и композиторам
INSERT INTO music.country_composer_stats 
SELECT 
    co.country_id,
    co.name as country_name,
    c.composer_id,
    c.surname || ' ' || c.name as composer_name,
    COUNT(m.music_id) as music_count
FROM music.countries co
JOIN music.composer c ON co.country_id = c.country_id
LEFT JOIN music.music m ON c.composer_id = m.composer_id
GROUP BY co.country_id, co.name, c.composer_id, c.surname, c.name;

-- 3.5) Исправление опечатки в названии произведения
UPDATE music.music
SET name = 'Симфония #2'
WHERE name = 'Симфония 2'
AND composer_id = (
    SELECT composer_id
    FROM music.composer
    WHERE surname = 'Петров'
);




--  DELETE операции:
-- 4.1) Удаление произведений, у которых длительность более 1.5 минуты
DELETE FROM music.music
WHERE duration > '01:30';

-- 4.2) Удаление частных владельцев, у которых нет произведений
DELETE FROM music.private_owners as owner
USING music.private_owners_music as owner_music
WHERE owner.private_owner_id = owner_music.private_owner_id
AND owner_music.music_id IS NULL;

-- 4.3) Удаление связей жанров для произведений определенного композитора
DELETE FROM music.music_genres
USING music.music
WHERE music.music_genres.music_id = music.music.music_id
AND music.music.composer_id = 1;

-- 4.4) Удаление композиторов из определенной страны
DELETE FROM music.composer
USING music.countries
WHERE music.composer.country_id = music.countries.country_id
AND music.countries.name = 'Польша';