-- 2.1
CREATE TABLE music.music_archive (
    music_id integer,
    composer_id integer,
    name text,
    duration text,
    finished_date date,
    premier_date date,
    premier_place text,
    country_id integer
);

-- 2.2
CREATE TABLE music.composer_countries (
    composer_id integer,
    composer_name text,
    country_name text
);

-- 2.3
CREATE TABLE music.long_compositions (
    music_id integer,
    name text,
    duration text,
    finished_date date
);

-- 2.4
CREATE TABLE music.russian_composers_works (
    composer_id integer,
    composer text,
    composition text,
    finished_date date
);

-- 2.5
CREATE TABLE music.genres_simple (
    genre_id integer,
    genre_name text
);