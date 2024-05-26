# Revenu des ménages américains

## Introduction

Dans ce projet, nous analyserons les données du recensement américain des ménages pour comprendre comment les revenus
sont distribués.
Tout d'abord, nous procéderons au nettoyage des données pour les rendre exploitables.
Ensuite, nous effectuerons une analyse exploratoire des données pour comprendre la distribution des revenus.

## Présentation du jeu de données

L'ensemble de données initial se présente sous la forme de deux fichiers CSV : `USHouseholdIncome.csv`
et `USHouseholdIncome_Statistics.csv`.
Le fichier `USHouseholdIncome.csv` contient des informations démographiques sur les ménages américains dans différents
lieux géographiques, à savoir :

- **row_id**: Un identifiant unique pour chaque ligne.
- **id**: Un autre identifiant unique, peut-être lié à un système externe.
- **State_Code**: Un code numérique représentant un État.
- **State_Name**: Le nom d'un État.
- **State_ab**: L'abréviation de l'État.
- **County**: Le nom d'un comté dans l'État.
- **City**: Le nom d'une ville dans le comté.
- **Place**: Le nom d'un lieu dans la ville.
- **Type**: Le type de lieu (par exemple, "Track").
- **Primary**: Non clair sans plus de contexte, peut-être si le lieu est le principal lieu dans la ville.
- **Zip_Code**: Le code postal du lieu.
- **Area_Code**: Le code de zone du lieu.
- **ALand**: La superficie terrestre du lieu, probablement en mètres carrés.
- **AWater**: La superficie d'eau du lieu, probablement en mètres carrés.
- **Lat**: La latitude du lieu.
- **Lon**: La longitude du lieu.

Le fichier `USHouseholdIncome_Statistics.csv` contient des informations statistiques sur les revenus des ménages
américains dans différentes zones géographiques, à savoir :

- **id**: Un identifiant unique pour chaque ligne.
- **State_Name**: Le nom de l'État.
- **Mean**: La moyenne des revenus des ménages.
- **Median**: La médiane des revenus des ménages.
- **Stdev**: L'écart type des revenus des ménages, qui est une mesure de la variabilité ou de la dispersion des revenus.
- **sum_w**: Non clair sans plus de contexte, mais pourrait représenter le poids total ou la somme des poids pour chaque
  groupe de ménages.

Nous importons ces deux fichiers csv dans une base de données pour les analyser.
Pour ce faire, nous avons créé une base de données `us_household_income` et deux tables `USHouseholdIncome`
et `USHouseholdIncome_Statistics` pour stocker les données des fichiers `USHouseholdIncome.csv`
et `USHouseholdIncome_Statistics.csv` respectivement.

```sql
CREATE
DATABASE IF NOT EXISTS us_household_income;

USE
us_household_income;

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

CREATE TABLE USHouseholdIncome_Statistics
(
    id         INTEGER        NOT NULL PRIMARY KEY,
    State_Name VARCHAR(20)    NOT NULL,
    Mean       INTEGER        NOT NULL,
    Median     INTEGER        NOT NULL,
    Stdev      INTEGER        NOT NULL,
    sum_w      NUMERIC(15, 9) NOT NULL
);
```

Nous avons importé les fichiers CSV.

- Le premier jeu de données à importer est `USHouseholdIncome.csv` :
  32 533 lignes ont été importées.
- Le second jeu de données à importer est `USHouseholdIncome_Statistics.csv` :
  32 534 lignes ont été importées.

Nous nous assurons que les données ont été importées correctement en affichant les premières lignes des
tables `USHouseholdIncome`
et `USHouseholdIncome_Statistics` :

```sql
SELECT *
FROM USHouseholdIncome LIMIT 10;
SELECT COUNT(*)
FROM USHouseholdIncome;

SELECT *
FROM USHouseholdIncome_Statistics LIMIT 10;
SELECT COUNT(*)
FROM USHouseholdIncome_Statistics;
```

## Nettoyage des données

Nous pouvons maintenant commencer à nettoyer les données. En parcourant nos deux tables, nous constatons plusieurs
problèmes :
Par exemple, la colonne `State_Name` de la table `USHouseholdIncome` contient des valeurs en majuscules et en
minuscules (ex: `Alabama` et `alabama`).
L'État de Georgie est mal orthographié (ex: `georia`).
Par ailleurs, dans la table `USHouseholdIncome_Statistics`, certains États n'ont aucune valeur pour les
colonnes `Mean`, `Median`, `Stdev` et `sum_w`.

Il est donc nécessaire de nettoyer les données pour les rendre exploitables.

### Suppression des doublons

Nous commençons par vérifier la présence de doublons dans la table `USHouseholdIncome`.

```sql
SELECT id, COUNT(id)
FROM USHouseholdIncome
GROUP BY id
HAVING COUNT(id) > 1;
```

Cette requête regroupe les lignes par `id` et compte le nombre d'occurrences de chaque `id`. Si un `id` apparaît
plus d'une fois, alors il est considéré comme un doublon. Nous constatons qu'il y a effectivement des doublons.

Pour les identifier et les supprimer, nous utilisons la fonction `ROW_NUMBER()` pour attribuer un numéro à chaque
ligne dans chaque groupe de `id`. Nous identifions ensuite les doublons comme étant les lignes ayant un numéro
supérieur à 1 pour chaque `id` en utilisant la requête suivante :

```sql
DELETE
FROM USHouseholdIncome
WHERE row_id IN (SELECT row_id
                 FROM (SELECT row_id,
                              id,
                              ROW_NUMBER() OVER (PARTITION BY id ORDER BY id)
                       FROM USHouseholdIncome) duplicates
                 WHERE row_number > 1);
```

Dans cette requête, `ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) as row_number` attribue un numéro à chaque ligne
dans chaque groupe de `id`, en ordonnant les lignes par `id`. Les lignes avec un `row_number` supérieur à 1 sont
donc des doublons et sont supprimées par la requête.

On procéde de la même manière pour la table `USHouseholdIncome_Statistics` :

```sql
SELECT id, COUNT(id)
FROM USHouseholdIncome_Statistics
GROUP BY id
HAVING COUNT(id) > 1;
```

Sauf que l'on constate ici qu'il n'y a pas de doublons.

Nous commençons par vérifier la distribution des noms d'États dans notre base de données.

### Correction des noms d'États

```sql
SELECT State_Name, COUNT(State_Name)
FROM USHouseholdIncome
GROUP BY State_Name;
```

Cette requête compte le nombre de fois que chaque `State_Name` apparaît dans la table `USHouseholdIncome`. Cela nous
permet de voir si certains noms d'États sont mal orthographiés ou incohérents.

Nous avons constaté que les noms de certains États sont mal orthographiés. Par exemple, `georia` doit être corrigé
en `Georgia`
et `alabama` en `Alabama`.

```sql
UPDATE USHouseholdIncome
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE USHouseholdIncome
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';
```

Ces requêtes SQL mettent à jour les valeurs incorrectes dans la colonne `State_Name`.

### Remplacement des valeurs nulles dans la colonne `Place`

Nous avons également remarqué que la colonne `Place` contient des valeurs vides pour certaines lignes.

```sql
SELECT *
FROM USHouseholdIncome
WHERE Place = ''
ORDER BY 1;
```

Cette requête sélectionne toutes les lignes de la table `USHouseholdIncome` où la colonne `Place` est nul.

Nous avons constaté que pour `County` égal à `Autauga County`, et `City` égal `Vinemont` que `Place` est nul.
Nous remplaçons ces valeurs nulles `Autaugaville`.

```sql
SELECT *
FROM USHouseholdIncome
WHERE County = 'Autauga County'
ORDER BY 1;

UPDATE USHouseholdIncome
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
  AND City = 'Vinemont';
```

### Normalisation de la colonne `Type`

Cette requête met à jour les valeurs nulles dans la colonne `Place` pour les lignes où `County` est égal
à `Autauga County` et `City` est égal à `Vinemont`.

Nous procédons à une analyse du type de lieu pour voir s'il y a des valeurs nulles ou incohérentes.

```sql
SELECT Type,
       COUNT(Type) GROUP BY Type;
```

Cette requête compte le nombre de fois que chaque `Type` apparaît dans la table `USHouseholdIncome`. Cela nous
permet de voir si certains types de lieux sont mal orthographiés ou incohérents.

Nous avons constaté des incohérences dans les valeurs de `Type`. Par exemple, nous avons des valeurs `Borough` qui sont
présentes 128 fois et `Boroughs` qui est présente 1 fois. Nous supposons que `Boroughs` est mal déclaré.

```sql
UPDATE USHouseholdIncome
SET Type = 'Borough'
WHERE Type = 'Boroughs';
```

### Vérification de la cohérence des colonnes `AWater` et `ALand`

En parcourant notre jeu de données, nous constatons que pour la colonne `AWater` de la table `USHouseholdIncome`, il y a
des
valeurs fixées à 0. Cela peut être dû à une erreur de saisie ou à un manque d'information. Nous vérifions si ces valeurs
sont cohérentes en sélectionnant les zones d'eaux et de terres.

```sql
SELECT ALand, AWater
FROM USHouseholdIncome
WHERE AWater = 0
   OR AWater IS NULL
   OR AWater = ''; 
```

Cette requête sélectionne toutes les lignes de la table USHouseholdIncome où la colonne `AWater` est égale à 0, nulle ou
vide.

Nous vérifions également s'il existe des valeurs nulles pour `ALand`.

```sql
SELECT ALand, AWater
FROM USHouseholdIncome AND (ALand = 0 AND ALand IS  NULL AND ALand = ''); 
```

Cette requête sélectionne toutes les lignes de la table `USHouseholdIncome` où la colonne `ALand` est égale à 0, nulle
ou vide.

Nous constatons qu'il n'y a pas de valeur là où il n'y a pas de terre et d'eau. Nous pouvons donc conclure que les
valeurs à 0 pour `AWater` et `ALand` sont cohérentes.

Maintenant que nous avons nettoyé les données, nous pouvons les analyser.

## Analyse exploratoire des données sur les revenus des ménages américains

### Vérification de la cohérence des données

Procédons à une analyse exploratoire des données pour comprendre la distribution des revenus des ménages américains.

Nous commençons par vérifier la cohérence des données en examinant la somme des superficies terrestres et aquatiques
pour chaque État.

```sql
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM USHouseholdIncome
GROUP BY State_Name
ORDER BY 2 DECS
LIMIT 10;
```

Cette requête nous donne le top 10 des États en termes de superficie terrestre. Les résultats semblent cohérents, avec
des États comme le `Texas` et la `Californie` en tête de liste.

Nous faisons de même pour la superficie aquatique.

```sql
SELECT State_Name, SUM(ALand), SUM(AWater)
FROM USHouseholdIncome
GROUP BY State_Name
ORDER BY 3 DECS
LIMIT 10;
```

Encore une fois, les résultats semblent cohérents, avec des États comme le `Michigan` et la `Floride` en tête de liste.

### Jointure des tables et filtrage des données

Maintenant, joignons ensuite les deux tables `USHouseholdIncome` et `USHouseholdIncome_Statistics` pour obtenir des
statistiques sur les revenus des ménages.

Pour ce faire, nous utilisons une jointure interne sur la colonne `id` avec cette reqête de `INNER JOIN` :

```sql
SELECT *
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0;
```

Cette requête nous donne des données plus pertinentes en excluant les États qui n'ont aucune valeur pour les
colonnes `Mean`, `Median`, `Stdev` et `sum_w`.

### Analyse de la distribution des revenus

Nous sélectionnons ensuite des informations sur les États et certaines statistiques pour analyser la distribution des
revenus.

```sql
SELECT income.State_Name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY income.State_Name
ORDER BY 2 DESC LIMIT 10;
```

Cette requête sélectionne le nom de l'État, la moyenne des revenus des ménages et la médiane des revenus des ménages.

Il est important de noté que le terme `Ménage` peut être utilisé pour désigner une famille, un individu ou un groupe de
personnes.

On remarque que les États `Maryland`, `New Jersey` et `Hawaii` ont les plus hauts revenus moyens des ménages. Avec des
revenus moyens de 84 000, 83 000 et 82 000 dollars respectivement.

Et que les États `Mississippi`, `West Virginia` et `Arkansas` ont les plus bas revenus moyens des ménages. Avec des
revenus moyens de 45 000, 46 000 et 46 000 dollars respectivement.

Nous pouvons également ordonner les États par revenu médian.

```sql
SELECT income.State_Name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY income.State_Name
ORDER BY 3 LIMIT 10;
```

Cette requête nous donne le top 10 des États avec les revenus médians les plus élevés. Les États du `Maryland`, du `New
Jersey` et d'`Hawaii` sont encore en tête de liste.

### Analyse par type de lieu

Nous pouvons également analyser les données par type de lieu.

```sql
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
ORDER BY 3;
```

Cette requête sélectionne le type de lieu, la moyenne des revenus des ménages et la médiane des revenus des ménages.
On constate que les `Cities` ont les plus hauts revenus moyens et médians des ménages. Avec des revenus moyens et
médians de 60 000 dollars respectivement.
Et que les `Towns` ont les plus bas revenus moyens et médians des ménages. Avec des revenus moyens et médians de 50 000
dollars respectivement.
Comparé aux `Cities`, les `Towns` ont des revenus moyens et médians inférieurs de 10 000 dollars.
Ce qui est une différence significative.
Il est important de noter que les `Cities` sont des zones urbaines densément peuplées, tandis que les `Towns` sont des
zones plus petites et moins peuplées.
Ce qui pourrait expliquer la différence de revenus entre les deux types de lieux.

En ajoutant `COUNT(TYPE)` à la requête, on peut voir le nombre de `Cities` et de `Towns` dans notre base de données.
On remarque également que les `Municipalities` ont des très hauts revenus moyens et médians des ménages. Avec des
revenus moyens et médians de 80 000 dollars respectivement.
Cependant, il y a seulement 1 `Municipality` dans notre base de données. Ce qui signifie que les données pourraient ne
pas être représentatives.

Si on met la valeur de `ORDER BY 4 DESCS`, on se base sur la médiane des revenus des ménages.

```sql
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
ORDER BY 4;
```

Là on voit que `Borough` qui font référence aux arrondissement de New York, ont les plus hauts revenus médians des
ménages. Avec des revenus médians supérieur à 110 000 dollars.
On voit également que les `Communities` ont les plus bas revenus médians des ménages. Avec des revenus médians de 40 000
dollars.
Sauf que l'on ne sait pas ce que représente `Communities` dans notre base de données.
Pour ce faire, on peut filtrer dessus dans la table `USHouseholdIncome`.

```sql
SELECT *
FROM USHouseholdIncome
WHERE Type = 'Community';
```

On constate que `Communities` sont des zones résidentielles avec l'États de `Puerto Rico` qui est un territoire non
incorporé des États-Unis. Ce qui explique les bas revenus médians des ménages comparé aux autres types de lieux compte
tenu de la situation économique du territoire.

Dans notre analyse, on constate par l'ajout de `COUNT(TYPE)` que certains types de lieux sont très peu représentés dans
la base de données. Par exemple, il n'y a qu'un seul `Municipality` dans notre base de données.
Cela signifie que les données pourraient ne pas être représentatives pour ce type de lieu. Pour obtenir des résultats
plus fiables, il serait préférable d'effectuer un filtrage sur les types de lieux qui sont plus représentés dans la base
de données.

```sql
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
WHERE Mean <> 0
GROUP BY 1
HAVING COUNT(Type) > 100
ORDER BY 4 DESC;
```

On remarque que les type d'état les plus présent sont les `CDP`, `Track`, `Borough`, `Village`, `City`, `Town`. On peut
donc se baser sur ces types d'état pour avoir des résultats plus fiables.

### Analyse des grandes villes

On peut se pencher sur le cas des grandes villes comme `Dallas` ou bien `Los Angeles` pour voir la distribution des
revenus des ménages.

```sql
SELECT income.State_Name, City, ROUND(AVG(Mean), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
GROUP BY income.State_Name, City
ORDER BY City DESC;
```

On obtient une liste des villes avec les moyennes et médianes des revenus des ménages regroupées par État.
Si on veut se concentrer sur une ville en particulier, on peut ordonner les villes par moyenne ou médiane des revenus

```sql
SELECT income.State_Name, City, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM USHouseholdIncome AS income
         JOIN USHouseholdIncome_Statistics AS statistics
              ON income.id = statistics.id
GROUP BY income.State_Name, City
ORDER BY ROUND(AVG(Mean), 1) DESC;
```

Cela nous permet de voir les villes avec les plus hauts revenus moyens regroupées par État.
Par exemple, la ville de `San Francisco` en Californie a les plus hauts revenus moyens des ménages avec 120 000 dollars.

## Conclusion

En conclusion, notre analyse exploratoire des données sur les revenus des ménages américains a révélé des informations
précieuses. Les États du `Maryland`, du `New Jersey` et d'`Hawaii` se distinguent par leurs revenus moyens élevés, tandis que
le `Mississippi`, la `Virginie occidentale` et l'`Arkansas` ont les revenus moyens les plus bas.

En examinant les types de lieux, nous avons constaté que les arrondissements de `New York`, désignés comme `Boroughs`, ont
les revenus médians les plus élevés, dépassant 110 000 dollars. Par contraste, les `Towns` ont les revenus moyens et
médians les plus bas, autour de 50 000 dollars. Les `Communities` sont peu représentées dans notre base de données, ce
qui pourrait nécessiter une collecte de données supplémentaire pour une analyse plus approfondie.

Enfin, en se concentrant sur les grandes villes, `San Francisco` en `Californie` se distingue avec les revenus moyens les
plus élevés, atteignant 120 000 dollars.

Ces informations peuvent être utiles pour comprendre les disparités économiques à travers les États-Unis.

## Sources

Les données utilisées dans ce projet proviennent
de [Kaggle](https://www.kaggle.com/goldenoakresearch/us-household-income-stats-geo-locations).
Elles ont été collectées par Golden Oak Research Group.
Les données sont issus d'un site gouvernemental américain.
