SET SEARCH_PATH TO kurs;

-- Zadanie 1 --

SELECT sub.nazwisko,
       sub.imie,
       sub.typ
FROM
(
    SELECT 
        w.nazwisko,
        w.imie,
        'W' AS typ
    FROM wykladowca w
    UNION ALL
    SELECT
        u.nazwisko,
        u.imie,
        'U' AS typ
    FROM uczestnik u
) AS sub
ORDER BY 
  CASE 
    WHEN sub.typ = 'W' THEN 1 
    WHEN sub.typ = 'U' THEN 2
    ELSE 3
  END,
  sub.nazwisko,
  sub.imie;

-- Zadanie 2 --

SELECT u.imie,
       u.nazwisko,
       SUM(uk.oplata) AS suma_oplat
FROM uczestnik u
JOIN uczest_kurs uk 
     ON u.id_uczestnik = uk.id_uczest
GROUP BY u.id_uczestnik, u.imie, u.nazwisko
HAVING SUM(uk.oplata) > 2000
ORDER BY suma_oplat DESC;

-- Zadanie 3 --

SELECT 
    k.id_kurs, 
    ko.opis AS kurs_opis, 
    AVG(uk.oplata) AS srednia_oplata
FROM uczest_kurs uk
JOIN kurs k ON uk.id_kurs = k.id_kurs
JOIN kurs_opis ko ON k.id_nazwa = ko.id_nazwa
GROUP BY k.id_kurs, ko.opis
ORDER BY srednia_oplata DESC;

-- Zadanie 4 --

SELECT 
    k.id_kurs,
    ko.opis AS kurs_opis,
    podzapytanie.suma_oplat
FROM kurs k
JOIN kurs_opis ko ON k.id_nazwa = ko.id_nazwa
JOIN (
    SELECT 
        id_kurs, 
        SUM(oplata) AS suma_oplat
    FROM uczest_kurs
    GROUP BY id_kurs
) AS podzapytanie ON k.id_kurs = podzapytanie.id_kurs
ORDER BY podzapytanie.suma_oplat DESC;

-- Zadanie 5 --

SELECT DISTINCT 
    u.imie, 
    u.nazwisko
FROM uczest_kurs uk
JOIN uczestnik u ON uk.id_uczest = u.id_uczestnik
WHERE uk.ocena >= 5 -- ocena 5 to "bardzo dobra"
ORDER BY u.nazwisko, u.imie;

-- Zadanie 6 --

SELECT u.nazwisko,
       u.imie,
       CASE WHEN COUNT(uk.id_kurs) < 4 
            THEN 'liczba kursów poniżej 4'
            ELSE 'liczba kursów co najmniej 4 lub więcej'
       END AS info_o_liczbie
FROM uczestnik u
LEFT JOIN uczest_kurs uk 
       ON u.id_uczestnik = uk.id_uczest
GROUP BY u.id_uczestnik, u.nazwisko, u.imie
ORDER BY u.nazwisko, u.imie;

-- Zadanie 7 --

SELECT DISTINCT 
    w.imie, 
    w.nazwisko
FROM wykladowca w
JOIN wykl_kurs wk ON w.id_wykladowca = wk.id_wykl
JOIN uczest_kurs uk ON wk.id_kurs = uk.id_kurs
WHERE uk.id_uczest IN (1, 2, 3)
ORDER BY w.nazwisko, w.imie;

-- Zadanie 8 --

WITH suma_oplat AS (
    SELECT 
        uk.id_uczest, 
        SUM(uk.oplata) AS suma_oplat
    FROM uczest_kurs uk
    GROUP BY uk.id_uczest
)
SELECT 
    u.imie, 
    u.nazwisko, 
    s.suma_oplat
FROM suma_oplat s
JOIN uczestnik u ON s.id_uczest = u.id_uczestnik
ORDER BY s.suma_oplat DESC;

-- Zadanie 9 --

CREATE OR REPLACE FUNCTION lista_zajec() 
RETURNS TABLE (imie TEXT, nazwisko TEXT, zajecia TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        w.imie::TEXT, 
        w.nazwisko::TEXT, 
        COALESCE(STRING_AGG(ko.opis, ', '), '')::TEXT AS zajecia
    FROM wykladowca w
    LEFT JOIN wykl_kurs wk ON w.id_wykladowca = wk.id_wykl
    LEFT JOIN kurs k ON wk.id_kurs = k.id_kurs
    LEFT JOIN kurs_opis ko ON k.id_nazwa = ko.id_nazwa
    GROUP BY w.id_wykladowca, w.imie, w.nazwisko
    ORDER BY w.nazwisko, w.imie;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM lista_zajec();