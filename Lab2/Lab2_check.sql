DELETE FROM music.private_owners_music;
DELETE FROM music.music_organization_owners;
DELETE FROM music.genres;
DELETE FROM music.music;
DELETE FROM music.composer;
DELETE FROM music.private_owners;
DELETE FROM music.organization_owners;
DELETE FROM music.genres;
DELETE FROM music.countries;


-- Добавим пару стран, жанров для разнообразия
INSERT INTO music.countries (country_id, name) VALUES 
(1, 'Россия'),
(2, 'Польша');
INSERT INTO music.genres (genre_id, name, description) VALUES 
(1, 'Симфония', 'Ну симфония, да'),
(2, 'Опера', 'Опера это опера');

-- Проверка "Композитор с одинаковыми ФИО и датой рождения не может существовать"
INSERT INTO music.composer (composer_id, name, surname, second_name, country_id, date_birth) 
VALUES (1, 'Иван', 'Иванов', 'Иванович', 1, '2025-11-26');
INSERT INTO music.composer (composer_id, name, surname, second_name, country_id, date_birth) 
VALUES (2, 'Иван', 'Иванов', 'Иванович', 2, '2025-11-26');

-- Проверка "Дата смерти не может быть раньше даты рождения"
INSERT INTO music.composer (composer_id, name, surname, second_name, country_id, date_birth, date_death) 
VALUES (2, 'Пётр', 'Петров', 'Петрович', 1, '2026-01-01', '2025-12-31');

-- Проверка "Произведение с одинаковым названием у одного композитора"
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date, country_id) 
VALUES (1, 1, 'Произведение 1', '02:45', '26-11-2025', 1);
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date, country_id) 
VALUES (2, 1, 'Произведение 1', '01:30', '13-9-2025', 1);

-- Проверка "Год написания не может быть в будущем"
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date, country_id) 
VALUES (2, 1, 'Будущая симфония', '00:45', '2030-01-01', 1);

-- Проверка "Уникальность стран"
INSERT INTO music.countries (country_id, name) VALUES (3, 'Россия');

-- Проверка "Уникальность жанров"
INSERT INTO music.genres (genre_id, name) VALUES (3, 'Симфония');

-- Проверка "Даты в таблицах владения"
INSERT INTO music.private_owners_music (private_owner_id, music_id, date_buy, date_sell) 
VALUES (1, 1, '2020-01-01', '2019-12-31');
INSERT INTO music.music_organization_owners (music_id, organization_owner_id, date_buy, date_sell) 
VALUES (1, 1, '2020-01-01', '2019-12-31');


-- Попытка вставить музыку с несуществующим composer_id
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date) 
VALUES (10, 999, 'Несуществующая музыка', '00:30', '26-11-2025');

-- Попытка обновить на несуществующий composer_id
INSERT INTO music.music (music_id, composer_id, name, duration, finished_date) 
VALUES (3, 1, 'Существующая музыка', '01:55', '26-11-2025');
UPDATE music.music SET composer_id = 999 WHERE music_id = 3;

-- Попытка удалить композитора, на которого есть ссылки
DELETE FROM music.composer WHERE composer_id = 1;