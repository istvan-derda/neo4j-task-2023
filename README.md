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
WITH a, b, COUNT(DISTINCT p) AS c, COLLECT(p.title) as shared_publications
WHERE c >= 4
WITH a, b, shared_publications
MATCH buddy_citation=(a)-[:authorOf]->(pa:Publication)-[:cites]-(pb:Publication)<-[:authorOf]-(b)
WHERE NOT pa.title IN shared_publications
AND NOT pb.title  IN shared_publications
RETURN a.name, b.name, pa.title, pb.title, shared_publications
```

2 pairs of authors in dataset

**Q10** - Ermitteln Sie das am meisten zitierte Papier im Jahr 2016 und geben  sie alle Venues der Publikationen aus, die dieses Top-Papier zitieren,  sowie die Anzahl der Publikationen pro Venue. Sortieren Sie die Ausgabe  absteigend nach der Anzahl. Hinweis: mit dem CALL Operator können  Subqueries realisiert werden. 

Assumption: looking for the paper, that was cited most in papers from the year 2016, not the paper from 2016 that has the most citations.

```cypher
MATCH (cited_p:Publication)<-[:cites]-(citing_p:Publication {year: 2016})
WITH cited_p, COUNT(citing_p) AS c_count, COLLECT(citing_p) AS citing_ps
ORDER BY c_count DESC
LIMIT 1
UNWIND citing_ps as citing_p
MATCH (v:Venue)<-[:publishedIn]-(citing_p)
RETURN v.name, COUNT(citing_p) AS c_count
ORDER BY c_count DESC
```

Note: this returns only the venues of 10 publications, although the most cited paper was cited 20 times in 2016. Of these 20 publications only 10 have venue data though.

**Q11** - Welche 5 Publikationen haben die meisten Autoren? Ausgabe der Publikation (Titel) sowie der Anzahl der Autoren.

```cypher
MATCH (p:Publication)<-[:authorOf]-(a:Author)
RETURN p.title, COUNT(a) AS authors_count
ORDER BY authors_count DESC
LIMIT 5
```

Paper with most authors is "Construction and Analysis of Weighted Brain Networks from SICE for the Study of Alzheimer's Disease" with 351.

On 5th place is "In Memoriam: Gunter Menz" with 44 authors.

**Q12** - Welche 5 Autoren haben die meisten  Selbstzitierungen? D.h. Ein Autor hat min. zwei Publikationen A und B,  wo mindestens eine die andere zitiert. Ausgabe Autor (Name) sowie der  Anzahl der Selbstzitierungen.

```cypher
MATCH (pa:Publication)<-[:authorOf]-(a:Author)-[:authorOf]->(pb:Publication),
(pa)-[self_citation:cites]->(pb)
RETURN a.name, COUNT(self_citation) AS self_citation_count
ORDER BY self_citation_count DESC
LIMIT 5
```

First place to "Haiying Shen" with 19 self-citations.

Second place has 16, and 3rd, 4th and 5th have 13 self-citations.

**Q13** - Wie viele Publikationen zitieren sich (A  zitiert B oder B zitiert A), haben jedoch vollständig unterschiedliche  Autoren? Ausgabe der Anzahl von solchen Publikations-Paaren.

```cypher
MATCH (a:Author)-[:authorOf]->(pa:Publication)-[:cites]-(pb:Publication)<-[:authorOf]-(b:Author)
WITH pa, COLLECT(a.name) AS authors_a, pb, COLLECT(b.name) as authors_b
WHERE ALL(a IN authors_a WHERE ALL(b IN authors_b WHERE NOT a = b))
RETURN COUNT(*)
```

2267

**Q14.1** - Löschen sie die property "n_citation" von allen Publikationen.

```cypher
MATCH (p:Publication)
REMOVE p.n_citation
```

**Q14.2** - Alle Publikationen, die von anderen  Publikationen zitiert werden, sollen ihre tatsächliche Anzahl der  Zitierungen erhalten. Erstellen Sie eine Query, die für jede Publikation die zitierenden Publikationen zählt und eine neue Property "cite_count" anlegt, die den aggregierten Wert zugewiesen bekommt.

```cypher
MATCH (cited_p:Publication)<-[:cites]-(citing_p:Publication)
WITH cited_p, COUNT(citing_p) AS c_count
SET cited_p.cite_count = c_count
```

**Q14.3** - Lassen Sie sich die Top 10 Publikationen  (d.h., die mit den meisten Zitierungen) (Publikations-Id, Titel,  cite_count) ausgeben. Was fällt Ihnen auf?

```cypher
MATCH (cited_p:Publication)<-[:cites]-(citing_p:Publication)
WITH cited_p, COUNT(citing_p) AS c_count
RETURN cited_p, c_count
ORDER BY c_count
LIMIT 10
```

Note:  not using the cite_count property, because it isn't hard to count the current citation edges in the query. This query would still work on a live database, where new citations could be added continiously.

Observation: 8 out of the top ten most cited papers have very short titles.

**Q15** - Autoren, die zusammen eine Publikation  verfasst haben, werden als Koautoren bezeichnet. Erstellen sie zwischen  jeden Koautor-Paar eine neue Kante mit dem Label "coAuthor" und der  Property mit dem Namen "since", welche das Jahr speichert, an dem beide  Autoren die erste/früheste Publikation zusammen verfasst haben. Die  Richtung der neuen Kante spielt hierbei keine Rolle. 

```cypher
MATCH (a:Author)-[:authorOf]->(p:Publication)<-[:authorOf]-(b:Author)
WHERE a.name<b.name //only create edge in one direction - see: https://graphaware.com/blog/neo4j/neo4j-bidirectional-relationships.html
WITH a, b, min(p.year) AS first_collab_year
CREATE (a)<-[:coAuthor {since: first_collab_year}]-(b)
```

