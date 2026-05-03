SHOW client_encoding;

-- Тип 1: Поиск сущности по идентификатору (SELECT)
-- 1. music.найти_композитора_по_id
-- Поиск композитора по идентификатору
-- Открывает REFCURSOR с полными данными о композиторе: ФИО, страна, даты рождения и смерти. 
-- Если запись с переданным ID не найдена — выводит предупреждение через RAISE NOTICE и возвращает 
-- пустой курсор.
CREATE OR REPLACE PROCEDURE music.найти_композитора_по_id(
    p_id INT,
    INOUT cur REFCURSOR DEFAULT 'cur_result'
)
LANGUAGE plpgsql AS '
BEGIN
    OPEN cur FOR
        SELECT c.composer_id, c.surname || '' '' || c.name AS ФИО, co.name AS Страна,
                c.date_birth AS Дата_рождения, c.date_death AS Дата_смерти
        FROM music.composer AS c
        JOIN music.countries AS co ON c.country_id = co.country_id
        WHERE c.composer_id = p_id;
    IF NOT FOUND THEN
        RAISE NOTICE ''Композитор с ID % не найден.'', p_id;
    END IF;
END;
';

-- Вызов процедуры:
BEGIN;
CALL music.найти_композитора_по_id(2);
FETCH ALL FROM cur_result;
COMMIT;

-- Несуществующий ID:
BEGIN;
CALL music.найти_композитора_по_id(99);
FETCH ALL FROM cur_result;
COMMIT;




 
-- 2. music.найти_произведение_по_id
-- Поиск произведения по идентификатору
-- Открывает REFCURSOR с данными об одном произведении: название, длительность, 
-- дата написания, дата и место премьеры, страна и ФИО композитора. Если запись не 
-- найдена — выбрасывает RAISE EXCEPTION с текстом ошибки.
CREATE OR REPLACE PROCEDURE music.найти_произведение_по_id(
    p_id INT,
    INOUT cur REFCURSOR DEFAULT 'cur_result'
)
LANGUAGE plpgsql AS '
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM music.music WHERE music_id = p_id
    ) THEN
        RAISE EXCEPTION ''Произведение с ID % не найдено.'', p_id;
    END IF;

    OPEN cur FOR
        SELECT m.music_id,  m.name AS Произведение, c.surname AS Композитор, m.duration AS Длительность,
                m.finished_date AS Дата_написания, m.premier_date AS Дата_премьеры,
                m.premier_place AS Место_премьеры, co.name AS Страна_премьеры
        FROM music.music AS m
        JOIN music.composer AS c ON m.composer_id = c.composer_id
        LEFT JOIN music.countries AS co ON m.country_id = co.country_id
        WHERE m.music_id = p_id;
END;
';

-- Вызов процедуры:
BEGIN;
CALL music.найти_произведение_по_id(4);
FETCH ALL FROM cur_result;
COMMIT;

-- Несуществующий ID — ошибка:
BEGIN;
CALL music.найти_произведение_по_id(99);
FETCH ALL FROM cur_result;
COMMIT;




-- Тип 2: Поиск сущности по части названия (SELECT)
-- 3. music.найти_произведение_по_названию
-- Поиск произведений по части названия
-- Ищет произведения, название которых содержит переданную строку (регистронезависимый ILIKE). 
-- Возвращает через REFCURSOR: название, фамилию композитора, жанры, дату премьеры. 
-- Результаты упорядочены по дате премьеры
CREATE OR REPLACE PROCEDURE music.найти_произведение_по_названию(
    p_name_part TEXT,
    INOUT cur REFCURSOR DEFAULT 'cur_result'
)
LANGUAGE plpgsql AS '
BEGIN
    OPEN cur FOR
        SELECT m.music_id, m.name AS Произведение, c.surname AS Композитор,
                STRING_AGG(g.name, '', '') AS Жанры, m.premier_date AS Дата_премьеры
        FROM music.music AS m
        JOIN music.composer AS c ON m.composer_id = c.composer_id
        LEFT JOIN music.music_genres AS mg ON m.music_id = mg.music_id
        LEFT JOIN music.genres AS g ON mg.genre_id = g.genre_id
        WHERE m.name ILIKE ''%'' || p_name_part || ''%''
        GROUP BY m.music_id, m.name, c.surname, m.premier_date
        ORDER BY m.premier_date;
END;
';

-- Вызов процедуры:
BEGIN;
CALL music.найти_произведение_по_названию('Симфония');
FETCH ALL FROM cur_result;
COMMIT;

-- Поиск по слову Концерт:
BEGIN;
CALL music.найти_произведение_по_названию('Концерт');
FETCH ALL FROM cur_result;
COMMIT;





-- 4. music.найти_композитора_по_фамилии
-- Поиск композитора по части фамилии
-- Ищет композиторов, чья фамилия содержит переданную строку (регистронезависимый ILIKE). 
-- Возвращает через REFCURSOR: ФИО, страну, годы жизни и количество произведений в базе. 
-- Результаты упорядочены по фамилии.
CREATE OR REPLACE PROCEDURE music.найти_композитора_по_фамилии(
    p_surname_part TEXT,
    INOUT cur REFCURSOR DEFAULT 'cur_result'
)
LANGUAGE plpgsql AS '
BEGIN
    OPEN cur FOR
        SELECT c.composer_id,
                c.surname || '' '' || c.name AS ФИО,
                co.name AS Страна,
                c.date_birth AS Дата_рождения,
                c.date_death AS Дата_смерти,
                COUNT(m.music_id) AS Кол_произведений
        FROM music.composer AS c
        JOIN music.countries AS co ON c.country_id = co.country_id
        LEFT JOIN music.music AS m ON c.composer_id = m.composer_id
        WHERE c.surname ILIKE ''%'' || p_surname_part || ''%''
        GROUP BY c.composer_id, c.surname, c.name,
                 co.name, c.date_birth, c.date_death
        ORDER BY c.surname;
END;
';

-- Поиск по началу фамилии:
BEGIN;
CALL music.найти_композитора_по_фамилии('Бет');
FETCH ALL FROM cur_result;
COMMIT;





-- 3: Добавление сущности с проверкой (INSERT)
-- 5. music.добавить_жанр
-- Добавление нового жанра с проверкой уникальности
-- Добавляет новую запись в таблицу genres. Перед вставкой проверяет, что жанр с таким 
-- названием ещё не существует. При нарушении уникальности выбрасывает RAISE EXCEPTION. 
-- При успешной вставке выводит подтверждение через RAISE NOTICE.
CREATE OR REPLACE PROCEDURE music.добавить_жанр(
    p_genre_id INT,
    p_name TEXT,
    p_description TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS '
BEGIN
    IF EXISTS (SELECT 1 FROM music.genres WHERE name = p_name) THEN
        RAISE EXCEPTION
            ''Жанр с названием "%" уже существует.'', p_name;
    END IF;

    INSERT INTO music.genres (genre_id, name, description)
    VALUES (p_genre_id, p_name, p_description);

    RAISE NOTICE ''Жанр "%" (ID=%) успешно добавлен.'',
                 p_name, p_genre_id;
END;
';

--Вызов процедуры:
-- Успешная вставка:
CALL music.добавить_жанр(6, 'Прелюдия',
    'Короткое вступительное произведение');
SELECT * FROM music.genres ORDER BY genre_id;

-- Ошибка уникальности:
CALL music.добавить_жанр(7, 'Прелюдия', NULL);





-- 6. music.добавить_произведение
-- Добавление нового произведения с бизнес-проверками
-- Добавляет новое произведение в таблицу music с двумя проверками: (1) существование 
-- композитора по переданному composer_id; (2) отсутствие у данного композитора произведения 
-- с таким же названием. При нарушении любого условия операция прерывается с RAISE EXCEPTION.
CREATE OR REPLACE PROCEDURE music.добавить_произведение(
    p_music_id INT, p_composer_id INT, p_name TEXT,
    p_duration TEXT DEFAULT NULL, p_finished_date DATE DEFAULT NULL,
    p_premier_date DATE DEFAULT NULL, p_premier_place TEXT DEFAULT NULL,
    p_country_id INT DEFAULT NULL
)
LANGUAGE plpgsql AS '
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM music.composer WHERE composer_id = p_composer_id
    ) THEN
        RAISE EXCEPTION ''Композитор с ID % не найден.'', p_composer_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM music.music
        WHERE composer_id = p_composer_id AND name = p_name
    ) THEN
        RAISE EXCEPTION
            ''У композитора (ID=%) уже есть произведение "%".'',
            p_composer_id, p_name;
    END IF;

    INSERT INTO music.music
        (music_id, composer_id, name, duration,
         finished_date, premier_date, premier_place, country_id)
    VALUES
        (p_music_id, p_composer_id, p_name, p_duration,
         p_finished_date, p_premier_date, p_premier_place, p_country_id);

    RAISE NOTICE ''Произведение "%" (ID=%) добавлено.'',
                 p_name, p_music_id;
END;
';

-- Вызов процедуры:
-- Успешная вставка:
CALL music.добавить_произведение(
    13, 2, 'Иоланта', '01:40:00',
    '1891-11-01', '1892-12-18',
    'Императорский театр, Санкт-Петербург', 1
);

-- Ошибка — дубликат у Чайковского:
CALL music.добавить_произведение(
    14, 2, 'Лебединое озеро', NULL, NULL, NULL, NULL, NULL
);





-- Тип 4: Добавление сущности с проверкой — второй вариант (INSERT)
-- 7. music.добавить_владельца_произведения
-- Передача произведения частному владельцу с проверкой
-- Регистрирует факт владения произведением у частного лица. Перед вставкой проверяет: 
-- (1) существование произведения; (2) существование владельца; (3) что данный владелец 
-- ещё не владеет этим произведением. При нарушении любого условия — RAISE EXCEPTION.
CREATE OR REPLACE PROCEDURE music.добавить_владельца_произведения(
    p_owner_id INT, p_music_id INT, p_date_buy DATE
)
LANGUAGE plpgsql AS '
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM music.music WHERE music_id = p_music_id
    ) THEN
        RAISE EXCEPTION ''Произведение с ID % не найдено.'', p_music_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM music.private_owners
        WHERE private_owner_id = p_owner_id
    ) THEN
        RAISE EXCEPTION ''Владелец с ID % не найден.'', p_owner_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM music.private_owners_music
        WHERE private_owner_id = p_owner_id
          AND music_id = p_music_id
    ) THEN
        RAISE EXCEPTION
            ''Владелец (ID=%) уже владеет произведением (ID=%).'',
            p_owner_id, p_music_id;
    END IF;

    INSERT INTO music.private_owners_music
        (private_owner_id, music_id, date_buy, date_sell)
    VALUES
        (p_owner_id, p_music_id, p_date_buy, NULL);

    RAISE NOTICE
        ''Произведение (ID=%) передано владельцу (ID=%) от %.'',
        p_music_id, p_owner_id, p_date_buy;
END;
';

--Вызов процедуры:
-- Успешная запись:
CALL music.добавить_владельца_произведения(3, 10, '2024-01-15');
SELECT * FROM music.private_owners_music
WHERE private_owner_id = 3;

-- Ошибка — дубликат:
CALL music.добавить_владельца_произведения(3, 10, '2024-03-01');





-- 8. music.добавить_организацию_владельца
-- Добавление организации-владельца с проверкой
-- Добавляет новую организацию в таблицу organization_owners. Принимает все 
-- поля записи. Перед вставкой проверяет: (1) существование указанной страны по 
-- country_id; (2) отсутствие организации с таким же названием в той же стране. 
-- При нарушении — RAISE EXCEPTION.
CREATE OR REPLACE PROCEDURE music.добавить_организацию_владельца(
    p_org_id INT, p_name TEXT, p_address TEXT DEFAULT NULL,
    p_country_id INT DEFAULT NULL
)
LANGUAGE plpgsql AS '
BEGIN
    IF p_country_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM music.countries WHERE country_id = p_country_id
    ) THEN
        RAISE EXCEPTION ''Страна с ID % не найдена.'', p_country_id;
    END IF;

    IF EXISTS (
        SELECT 1 FROM music.organization_owners
        WHERE name = p_name
          AND country_id = p_country_id
    ) THEN
        RAISE EXCEPTION
            ''Организация "%" уже существует в стране ID=%.'',
            p_name, p_country_id;
    END IF;

    INSERT INTO music.organization_owners
        (organization_owner_id, name, address, country_id)
    VALUES
        (p_org_id, p_name, p_address, p_country_id);

    RAISE NOTICE ''Организация "%" (ID=%) добавлена.'',
                 p_name, p_org_id;
END;
';

-- Вызов процедуры:
-- Успешная вставка:
CALL music.добавить_организацию_владельца(
    5, 'Театр Ла Скала',
    'Piazza della Scala, Милан', 5
);
SELECT * FROM music.organization_owners ORDER BY organization_owner_id;

-- Ошибка — дубликат в той же стране:
CALL music.добавить_организацию_владельца(
    6, 'Театр Ла Скала', NULL, 5
);

-- Ошибка — несуществующая страна:
CALL music.добавить_организацию_владельца(
    7, 'Новая сцена', NULL, 99
);





-- Тип 5: Обновление одного поля по идентификатору (UPDATE)
-- 9. music.обновить_дату_премьеры
-- Обновление даты премьеры произведения по ID
-- Обновляет поле premier_date у одного произведения, найденного по music_id. 
-- Сначала проверяет существование записи. Если произведение не найдено — RAISE EXCEPTION. 
-- После успешного обновления выводит новое значение через RAISE NOTICE.
CREATE OR REPLACE PROCEDURE music.обновить_дату_премьеры(
    p_music_id INT, p_premier_date DATE
)
LANGUAGE plpgsql AS '
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM music.music WHERE music_id = p_music_id
    ) THEN
        RAISE EXCEPTION ''Произведение с ID % не найдено.'', p_music_id;
    END IF;

    UPDATE music.music
    SET premier_date = p_premier_date
    WHERE music_id = p_music_id;

    RAISE NOTICE
        ''Дата премьеры произведения ID=% обновлена на %.'',
        p_music_id, p_premier_date;
END;
';

-- Вызов процедуры:
-- Успешное обновление:
CALL music.обновить_дату_премьеры(10, '1942-03-05');

SELECT music_id, name, premier_date
FROM music.music WHERE music_id = 10;

-- Ошибка — несуществующий ID:
CALL music.обновить_дату_премьеры(99, '2000-01-01');





-- 10. music.обновить_страну_композитора
-- Обновление страны композитора по ID
-- Обновляет поле country_id у одного композитора, найденного по composer_id. 
-- Выполняет две проверки: (1) существование записи композитора; (2) существование 
-- новой страны в таблице countries. Если любая проверка не пройдена — RAISE EXCEPTION.
CREATE OR REPLACE PROCEDURE music.обновить_страну_композитора(
    p_composer_id INT, p_country_id INT
)
LANGUAGE plpgsql AS '
DECLARE
    v_name TEXT;
BEGIN
    SELECT surname || '' '' || name INTO v_name
    FROM music.composer
    WHERE composer_id = p_composer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            ''Композитор с ID % не найден.'', p_composer_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM music.countries WHERE country_id = p_country_id
    ) THEN
        RAISE EXCEPTION ''Страна с ID % не найдена.'', p_country_id;
    END IF;

    UPDATE music.composer
    SET country_id = p_country_id
    WHERE composer_id = p_composer_id;

    RAISE NOTICE
        ''Страна композитора % (ID=%) обновлена на country_id=%.'',
        v_name, p_composer_id, p_country_id;
END;
';

-- Вызов процедуры:
-- Успешное обновление:
CALL music.обновить_страну_композитора(7, 2);
SELECT composer_id, surname, name, country_id
FROM music.composer WHERE composer_id = 7;

-- Ошибка — несуществующая страна:
CALL music.обновить_страну_композитора(7, 99);





-- Тип 6: Массовое обновление по условию (UPDATE)
-- 11. music.массовое_обновление_страны_премьеры
-- Перенос страны премьеры всех произведений
-- Массово обновляет поле country_id в таблице music: заменяет одну 
-- страну на другую для всех произведений сразу. Перед выполнением проверяет 
-- существование обеих стран. Количество изменённых строк считывается через 
-- GET DIAGNOSTICS и выводится в RAISE NOTICE.
CREATE OR REPLACE PROCEDURE music.массов_обновление_страны_премьеры(
    p_old_country_id INT, p_new_country_id INT
)
LANGUAGE plpgsql AS '
DECLARE
    v_count INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM music.countries WHERE country_id = p_old_country_id
    ) THEN
        RAISE EXCEPTION
            ''Исходная страна с ID % не найдена.'', p_old_country_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM music.countries WHERE country_id = p_new_country_id
    ) THEN
        RAISE EXCEPTION
            ''Целевая страна с ID % не найдена.'', p_new_country_id;
    END IF;

    UPDATE music.music
    SET country_id = p_new_country_id
    WHERE country_id = p_old_country_id;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE
        ''Обновлено % произведений: страна ID=% -> ID=%.'',
        v_count, p_old_country_id, p_new_country_id;
END;
';

-- Вызов процедуры:
-- Перенести все австрийские премьеры в Германию:
CALL music.массов_обновление_страны_премьеры(3, 2);
SELECT m.name, co.name AS Страна
FROM music.music AS m
JOIN music.countries AS co ON m.country_id = co.country_id
ORDER BY m.name;

-- Ошибка — несуществующая страна:
CALL music.массов_обновление_страны_премьеры(99, 2);





-- 12. music.массово_установить_дату_продажи
-- Массовая установка даты продажи для записей владения
-- Устанавливает поле date_sell для всех записей в таблице private_owners_music, 
-- где date_sell IS NULL и date_buy раньше указанной граничной даты. Это позволяет 
-- массово закрыть устаревшие записи владения. Выводит количество обновлённых строк 
-- через GET DIAGNOSTICS.
CREATE OR REPLACE PROCEDURE music.массово_установить_дату_продажи(
    p_buy_before DATE, p_sell_date DATE
)
LANGUAGE plpgsql AS '
DECLARE
    v_count INT;
BEGIN
    IF p_sell_date < p_buy_before THEN
        RAISE EXCEPTION
            ''Дата продажи (%) не может быть раньше даты покупки (%).'',
            p_sell_date, p_buy_before;
    END IF;

    UPDATE music.private_owners_music
    SET date_sell = p_sell_date
    WHERE date_sell IS NULL
      AND date_buy < p_buy_before;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    IF v_count = 0 THEN
        RAISE NOTICE
            ''Записей для обновления не найдено (покупка до %).'',
            p_buy_before;
    ELSE
        RAISE NOTICE
            ''Дата продажи % установлена для % записей.'',
            p_sell_date, v_count;
    END IF;
END;
';

-- Вызов процедуры:
-- Закрыть все старые записи владения (до 2015):
CALL music.массово_установить_дату_продажи(
    '2015-01-01', '2024-12-31'
);
SELECT * FROM music.private_owners_music
ORDER BY date_buy;

-- Некорректные даты — ошибка:
CALL music.массово_установить_дату_продажи(
    '2020-01-01', '2010-01-01'
);