# NoSQL Neo4j task

## Setup

- `./setup.sh` to setup neo4j in a docker container (needs an internet connection)

- `./import.sh` to initialize the database with the data from the provided .json file

- `./nuke.sh` to delete the database and the neo4j container
- `docker stop neo4j` and `docker start neo4j` to stop/start neo4j container

**Interactive shell**

Open [localhost:7474/](localhost:7474/) in your browser to run the queries shown below.

- username: neo4j
- password: datenbanken

## Queries

**Q1** \- Ausgabe aller Publikationen, bei denen "Erhard Rahm" einer der Autoren ist.

```cypher
MATCH n=(p:Publication)<-[:authorOf]-(a:Author {name: "Erhard Rahm"})
RETURN count(n)
```

11

**Q2** - Ausgabe aller Koautoren von "Erhard Rahm".

```cypher
MATCH (b:Author)-[:authorOf]->(p:Publication)<-[:authorOf]-(a:Author {name: "Erhard Rahm"})
RETURN DISTINCT b
```

21 authors

**Q3** - Ausgabe aller Publikationen (Titel), die Publikationen von dem Autor "Wei Wang" zitieren.

```cypher
MATCH (p2:Publication)-[:cites]->(p:Publication)<-[:authorOf]-(a:Author {name: "Wei Wang"})
RETURN p.title
```

6 titles

**Q4** - Ausgabe aller Venues, deren Publikationen mindestens eine im Titel das Wort "graph" und das Wort "temporal" (beide case insensitive) enthält. Neben dem duplikatfreien Venue-Namen in der ersten Spalte soll in einer zweiten Spalte auch eine duplikatfreie Liste der Publikations-Titel  ausgegeben werden, bei denen beide gesuchten Worte vorkommen.

```cypher
MATCH (v:Venue)<-[:publishedIn]-(p:Publication)
WHERE p.title CONTAINS 'graph' AND p.title CONTAINS 'temporal'
RETURN v.name, COLLECT(p.title)
```

5 venues with 1 publication each

**Q5** - Wie viele Autoren haben pro Jahr bei der Venue mit dem Namen "Lecture Notes in Computer Science" veröffentlicht? Ausgabe aufsteigend sortiert nach Jahr.

```cypher
MATCH (a:Author)-[:authorOf]->(p:Publication)-[pi:publishedIn]->(v:Venue) 
WHERE v.name = "Lecture Notes in Computer Science" 
RETURN p.year, COUNT(a) 
ORDER BY p.year
```

result year range from 1988 to 2017
most authors in 2006 with 4438

**Q6** - Wie viele Verbindungen/Pfade (ohne Einschränkung von Label und Richtung) gibt es zwischen den Autoren 'Ioanna Tsalouchidou' und 'Charu C. Aggarwal', die eine exakte Länge von 4 Kanten haben?

```cypher
MATCH n=(a:Author {name: "Charu C. Aggarwal"})-[*4]-(b:Author {name: "Ioanna Tsalouchidou"})
RETURN COUNT(n)
```

0 - but with a length of 6 there is 2 paths.

**Q7** - Auf welchen Venues hat der Autor 'Charu C.  Aggarwal' schon Publikationen veröffentlicht? Ausgabe einer  duplikatfreien Liste von Venue-Namen sowie einer duplikatfreien Liste  von Jahren, indem die Publikationen erfolgt sind.

```cypher
MATCH (a:Author {name: "Charu C. Aggarwal"})-[:authorOf]->(p:Publication)-[:publishedIn]->(v:Venue)
RETURN COLLECT(DISTINCT v.name), COLLECT(DISTINCT p.year)
```

["international conference on data mining", "international conference on data engineering", "web search and data mining", "IEEE Intelligent Systems"]
[2016, 2017]

**Q8** - Von welchen der in Q7 genannten Venues war 'Charu C. Aggarwal' als Zweitautor einer entsprechenden Publikation involviert?

```cypher
MATCH (a:Author {name: "Charu C. Aggarwal"})-[:authorOf {position: 2}]->(p:Publication)-[:publishedIn]->(v:Venue)
RETURN v.name
```

"international conference on data mining"
"web search and data mining"

**Q9** - Es gibt Autoren, die bereits zusammen Publikationen veröffentlicht  haben (Koautoren). Jeder der Autoren kann nun jeweils auch Publikationen ohne diesen Koautor veröffentlicht haben. Wenn sich diese  "unabhängigen" Publikationen zitieren, kann man das als Buddy-Citation  bezeichnen. Ermitteln Sie alle Autor-Paare, die mindestens 4 gemeinsame Publikationen veröffentlicht haben und deren unabhängige Publikationen sich mindestens in eine Richtung zitieren (A zitiert B oder B zitiert A).

```cypher
MATCH (a:Author)-[:authorOf]->(p:Publication)<-[:authorOf]-(b:Author)
WHERE a.name<b.name //no duplicates
WITH a, b, COUNT(DISTINCT p) AS c, COLLECT(p.title) as publications
WHERE c >= 4
WITH a, b, publications
MATCH buddy_citation=(a)-[:authorOf]->(pa:Publication)-[:cites]-(pb:Publication)<-[:authorOf]-(b)
WHERE NOT pa.title IN publications
AND NOT pb.title  IN publications
RETURN a.name, b.name, pa.title, pb.title, publications
```

2 pairs of authors in dataset

**Q10** - Ermitteln Sie das am meisten zitierte Papier im Jahr 2016 und geben  sie alle Venues der Publikationen aus, die dieses Top-Papier zitieren,  sowie die Anzahl der Publikationen pro Venue. Sortieren Sie die Ausgabe  absteigend nach der Anzahl. Hinweis: mit dem CALL Operator können  Subqueries realisiert werden. 
