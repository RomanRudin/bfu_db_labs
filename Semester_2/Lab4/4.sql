-- 1. AVG / MIN / MAX OVER с PARTITION BY
-- 1.1 Для каждого произведения вывести его длительность и сравнить со средней, 
-- минимальной и максимальной длительностью всех произведений того же композитора
SELECT
    c.surname || ' ' || c.name AS Композитор,
    m.name AS Произведение,
    m.duration AS Длительность,
    AVG(m.duration::interval)
        OVER (PARTITION BY m.composer_id) AS Средняя_длительность,
    MIN(m.duration::interval)
        OVER (PARTITION BY m.composer_id) AS Мин_длительность,
    MAX(m.duration::interval)
        OVER (PARTITION BY m.composer_id) AS Макс_длительность
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.duration IS NOT NULL
ORDER BY c.surname, m.duration::interval;



-- 2. COUNT OVER с PARTITION BY
-- 2.2 Для каждого композитора вывести количество его коллег из той же страны, 
-- а также его порядковый номер внутри страны по дате рождения
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    co.name AS Страна,
    COUNT(c.composer_id)
        OVER (PARTITION BY c.country_id)
            AS Композиторов_в_стране,
    ROW_NUMBER()
        OVER (PARTITION BY c.country_id
            ORDER BY c.date_birth) AS Номер_в_стране
FROM music.composer AS c
JOIN music.countries AS co ON c.country_id = co.country_id
ORDER BY co.name, c.date_birth;



-- 3. ROW_NUMBER OVER с PARTITION BY и RDER BY
-- 3.3 Пронумеровать произведения каждого композитора в хронологическом 
--- порядке по дате премьеры
SELECT
    c.surname AS Фамилия,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    ROW_NUMBER() OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
    ) AS Порядковый_номер
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY c.surname, m.premier_date;



-- 4. RANK / DENSE_RANK OVER с ORDER BY
-- 4.4 Ранжировать композиторов по количеству произведений по убыванию. 
-- Вывести оба варианта ранга: с пропуском позиций и без
SELECT
    c.surname AS Фамилия,
    c.name AS Имя,
    COUNT(m.music_id) AS Количество_произведений,
    RANK() OVER (
        ORDER BY COUNT(m.music_id) DESC
    ) AS Ранг,
    DENSE_RANK() OVER (
        ORDER BY COUNT(m.music_id) DESC
    ) AS Плотный_ранг
FROM music.composer  AS c
LEFT JOIN music.music AS m ON c.composer_id = m.composer_id
GROUP BY c.composer_id, c.surname, c.name
ORDER BY Ранг;



-- 5. COUNT OVER с ORDER BY и ROWS UNBOUNDED PRECEDING
-- 5.5 Вывести произведения в хронологическом порядке и 
--накопительным итогом показать, сколько всего произведений было 
-- впервые исполнено к каждой дате
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    m.premier_date AS Дата_премьеры,
    COUNT(*) OVER (
        ORDER BY m.premier_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Накопительное_количество
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY m.premier_date;



-- 6. LAG / LEAD OVER с PARTITION BY и ORDER BY
-- 6.6 Для каждого произведения показать дату предыдущей
-- и следующей премьеры того же композитора, а также
-- интервал между ними
SELECT
    c.surname AS Фамилия,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    LAG(m.premier_date) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
    ) AS Предыдущая_премьера,
    LEAD(m.premier_date) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
    ) AS Следующая_премьера,
    m.premier_date - LAG(m.premier_date) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
    ) AS Дней_с_предыдущей
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY c.surname, m.premier_date;



-- 7. FIRST_VALUE / LAST_VALUE OVER с PARTITION BY и ROWS UNBOUNDED
-- 7.7 Для каждого произведения вывести первое и последнее произведение
-- того же композитора по дате премьеры
SELECT
    c.surname AS Фамилия,
    m.name AS Произведение,
    m.premier_date AS Дата_премьеры,
    FIRST_VALUE(m.name) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS Первое_произведение,
    LAST_VALUE(m.name) OVER (
        PARTITION BY m.composer_id
        ORDER BY m.premier_date
        ROWS BETWEEN UNBOUNDED PRECEDING
            AND UNBOUNDED FOLLOWING
    ) AS Последнее_произведение
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY c.surname, m.premier_date;



-- 8. NTILE OVER (ORDER BY)
-- 8.8 Разбить все произведения на 4 равные группы (квартили)
-- по году написания и определить, к какому квартилю относится каждое произведение
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    EXTRACT(YEAR FROM m.finished_date) AS Год_написания,
    NTILE(4) OVER (
        ORDER BY m.finished_date
    ) AS Квартиль
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.finished_date IS NOT NULL
ORDER BY m.finished_date;



-- 9. PERCENT_RANK / CUME_DIST OVER (ORDER BY)
-- 9.9 Для каждого произведения вычислить его процентный ранг
-- и накопительную долю по дате премьеры среди всех произведений
SELECT
    m.name AS Произведение,
    c.surname AS Композитор,
    m.premier_date AS Дата_премьеры,
    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY m.premier_date
        )::numeric * 100, 2
    ) AS Процентный_ранг,
    ROUND(
        CUME_DIST() OVER (
            ORDER BY m.premier_date
        )::numeric * 100, 2
    ) AS Накопительная_доля_процент
FROM music.music AS m
JOIN music.composer AS c ON m.composer_id = c.composer_id
WHERE m.premier_date IS NOT NULL
ORDER BY m.premier_date;



-- 10. SUM / COUNT OVER с PARTITION BY с долей
-- 10.10 Для каждой организации-владельца показать 
-- количество её произведений, суммарное количество произведений 
-- у всех организаций из той же страны и долю организации внутри своей страны в процентах
SELECT
    oo.name AS Организация,
    co.name AS Страна,
    COUNT(moo.music_id) AS Произведений,
    SUM(COUNT(moo.music_id)) OVER (
        PARTITION BY oo.country_id
    ) AS Итого_по_стране,
    ROUND(
        COUNT(moo.music_id)::numeric /
        SUM(COUNT(moo.music_id)) OVER (
            PARTITION BY oo.country_id
        ) * 100, 1
    ) AS Доля_в_стране_процент
FROM music.organization_owners AS oo
JOIN music.countries AS co
    ON oo.country_id = co.country_id
JOIN music.music_organization_owners AS moo
    ON oo.organization_owner_id = moo.organization_owner_id
GROUP BY oo.organization_owner_id, oo.name,co.name, oo.country_id
ORDER BY co.name, oo.name;