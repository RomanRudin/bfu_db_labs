-- Композитор с одинаковыми ФИО и датой рождения не может существовать
ALTER TABLE music.composer 
ADD CONSTRAINT composer_unique_name_birth 
UNIQUE (name, surname, second_name, date_birth);

-- Дата смерти не может быть раньше даты рождения
ALTER TABLE music.composer 
ADD CONSTRAINT composer_dates_check 
CHECK (date_death IS NULL OR date_death > date_birth);

-- Произведение с одинаковым названием у одного композитора
ALTER TABLE music.music 
ADD CONSTRAINT music_unique_composer_name 
UNIQUE (composer_id, name);

-- Год написания не может быть в будущем
ALTER TABLE music.music 
ADD CONSTRAINT music_date_check 
CHECK (
    finished_date IS NULL OR 
    EXTRACT(YEAR FROM finished_date) <= EXTRACT(YEAR FROM CURRENT_DATE)
);

-- Countries
ALTER TABLE music.countries 
ADD CONSTRAINT country_name_unique UNIQUE (name);

-- Genres
ALTER TABLE music.genres 
ADD CONSTRAINT genre_name_unique UNIQUE (name);

-- Даты в таблицах владения
ALTER TABLE music.music_organization_owners 
ADD CONSTRAINT org_dates_check 
CHECK (date_sell IS NULL OR date_sell > date_buy);

ALTER TABLE music.private_owners_music 
ADD CONSTRAINT priv_dates_check 
CHECK (date_sell IS NULL OR date_sell > date_buy);