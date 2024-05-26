-- Créer la base de données si elle n'existe pas
CREATE DATABASE IF NOT EXISTS us_household_income;

-- Utiliser la base de données
USE us_household_income;

-- Créer la table USHouseholdIncome
CREATE TABLE USHouseholdIncome
(
    row_id     INTEGER        NOT NULL Primary KEY,
    id         INTEGER        NOT NULL,
    State_Code INTEGER        NOT NULL,
    State_Name VARCHAR(20)    NOT NULL,
    State_ab   VARCHAR(2)     NOT NULL,
    County     VARCHAR(33)    NOT NULL,
    City       VARCHAR(22)    NOT NULL,
    Place      VARCHAR(36),
    `Type`     VARCHAR(12)    NOT NULL,
    `Primary`  VARCHAR(5)     NOT NULL,
    Zip_Code   INTEGER        NOT NULL,
    Area_Code  VARCHAR(3)     NOT NULL,
    ALand      BIGINT         NOT NULL,
    AWater     BIGINT         NOT NULL,
    Lat        NUMERIC(10, 7) NOT NULL,
    Lon        NUMERIC(12, 7) NOT NULL
);

-- Créer la table USHouseholdIncome_Statistics
CREATE TABLE USHouseholdIncome_Statistics
(
    id         INTEGER        NOT NULL PRIMARY KEY,
    State_Name VARCHAR(20)    NOT NULL,
    Mean       INTEGER        NOT NULL,
    Median     INTEGER        NOT NULL,
    Stdev      INTEGER        NOT NULL,
    sum_w      NUMERIC(15, 9) NOT NULL
);

-- Sélectionner les 10 premières lignes de la table USHouseholdIncome
SELECT *
FROM USHouseholdIncome LIMIT 10;

-- Compter le nombre de lignes dans la table USHouseholdIncome
SELECT COUNT(*)
FROM USHouseholdIncome;

-- Sélectionner les 10 premières lignes de la table USHouseholdIncome_Statistics
SELECT *
FROM USHouseholdIncome_Statistics LIMIT 10;

-- Compter le nombre de lignes dans la table USHouseholdIncome_Statistics
SELECT COUNT(*)
FROM USHouseholdIncome_Statistics;

-- Trouver les id en double dans la table USHouseholdIncome
SELECT id, COUNT(id)
FROM USHouseholdIncome
GROUP BY id
HAVING COUNT(id) > 1;

-- Supprimer les lignes en double dans la table USHouseholdIncome
DELETE
FROM USHouseholdIncome
WHERE row_id IN (SELECT row_id
                 FROM (SELECT row_id,
                              id,
                              ROW_NUMBER() OVER (PARTITION BY id ORDER BY id)
                       FROM USHouseholdIncome) duplicates
                 WHERE row_number > 1);

-- Trouver les id en double dans la table USHouseholdIncome_Statistics
SELECT id, COUNT(id)
FROM USHouseholdIncome_Statistics
GROUP BY id
HAVING COUNT(id) > 1;

-- Compter le nombre de lignes par State_Name dans la table USHouseholdIncome
SELECT State_Name, COUNT(State_Name)
FROM USHouseholdIncome
GROUP BY State_Name;

-- Corriger les erreurs de saisie dans la colonne State_Name
UPDATE USHouseholdIncome
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE USHouseholdIncome
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

-- Sélectionner les lignes où Place est vide
SELECT *
FROM USHouseholdIncome
WHERE Place = ''
ORDER BY 1;

-- Sélectionner les lignes où County est 'Autauga County'
SELECT *
FROM USHouseholdIncome
WHERE County = 'Autauga County'
ORDER BY 1;

-- Mettre à jour la colonne Place pour les lignes où County est 'Autauga County' et City est 'Vinemont'
UPDATE USHouseholdIncome
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
  AND City = 'Vinemont';

-- Compter le nombre de lignes par Type
SELECT Type,
       COUNT(Type) GROUP BY Type;

-- Corriger les erreurs de saisie dans la colonne Type
UPDATE USHouseholdIncome
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- Sélectionner les lignes où AWater est 0, NULL ou vide
SELECT ALand, AWater
FROM USHouseholdIncome
WHERE AWater = 0
   OR AWater IS NULL
   OR AWater = '';

-- Sélectionner les lignes où ALand est 0, NULL ou vide
SELECT ALand, AWater
FROM USHouseholdIncome AND (ALand = 0 AND ALand IS  NULL AND ALand = '');

-- Sélectionner le total de ALand et AWater par State_Name
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM USHouseholdIncome
GROUP BY State_Name
ORDER BY 2 DECS
LIMIT 10;

-- Sélectionner le total de ALand et AWater par State_Name
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM USHouseholdIncome
GROUP BY State_Name
ORDER BY 3 DECS
LIMIT 10;

-- Joindre les tables USHouseholdIncome et USHouseholdIncome_Statistics
SELECT *
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0;

-- Sélectionner la moyenne et la médiane par State_Name
SELECT income.State_Name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY income.State_Name
ORDER BY 2 DESC LIMIT 10;

-- Sélectionner la moyenne et la médiane par State_Name
SELECT income.State_Name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY income.State_Name
ORDER BY 3 LIMIT 10;

-- Sélectionner le nombre de lignes, la moyenne et la médiane par Type
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
ORDER BY 3;

-- Sélectionner le nombre de lignes, la moyenne et la médiane par Type
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
ORDER BY 4;

-- Sélectionner les lignes où Type est 'Community'
SELECT *
FROM USHouseholdIncome
WHERE Type = 'Community';

-- Sélectionner le nombre de lignes, la moyenne et la médiane par Type pour les Types avec plus de 100 lignes
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
HAVING COUNT(Type) > 100
ORDER BY 4 DESC;

-- Sélectionner la moyenne par State_Name et City
SELECT income.State_Name, City, ROUND(AVG(Mean), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
GROUP BY income.State_Name, City
ORDER BY City DESC;

-- Sélectionner la moyenne et la médiane par State_Name et City
SELECT income.State_Name, City, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
GROUP BY income.State_Name, City
ORDER BY ROUND(AVG(Mean), 1) DESC;
