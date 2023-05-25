# NoSQL Neo4j task

## Importing the Data

Add Author Nodes

```cypher
CREATE INDEX iauthor IF NOT EXISTS
FOR (n:Author)
ON n.name;
     

CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
UNWIND value.authors AS author MERGE (a:Author {name:author});
```

Add Publication Nodes

```cypher
CREATE INDEX ipublication IF NOT EXISTS 
FOR (n:Publication) 
ON n.id;

CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
MERGE (p:Publication {
    id: value.id,
    abstract: COALESCE(value.abstract, ''),
    title: value.title,
    n_citation: value.n_citation,
    year: value.year
    }
);
```

Add Venue Nodes

```cypher
CREATE INDEX ivenue IF NOT EXISTS 
FOR (n:Venue) 
ON n.name;

CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
FOREACH(
    _ IN CASE WHEN value.venue = '' THEN [] ELSE [value.venue] END |
    MERGE (
        v:Venue {
            name: value.venue
        }
    )
);
```

Add authorOf Edges

```cypher
CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
MATCH (p:Publication) WHERE p.id = value.id
UNWIND range(1, size(value.authors)) AS pos
WITH p, pos, value.authors[pos-1] AS author
MATCH (a:Author {name: author}) 
MERGE (a)-[:authorOf {position: pos}]->(p);
```

Add publishedIn Edges

```cypher
CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
MATCH (p:Publication) WHERE p.id = value.id
MATCH (v:Venue) WHERE v.name = value.venue
CREATE (p)-[:publishedIn]->(v);
```

Add cites Edges

```cypher
CALL apoc.load.json('file:///dblp-ref-3.json') YIELD value
MATCH (p:Publication) WHERE p.id = value.id
UNWIND value.references AS ref_id
MATCH (p2:Publication) WHERE p2.id = ref_id
CREATE (p)-[:cites]->(p2);
```

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
#wip find buddies
MATCH (a:Author)-[:authorOf]-(p:Publication)-[:authorOf]-(b:Author)
WITH a, b, COUNT(p) AS c
WHERE c >= 4 
AND a.name < b.name // remove duplicate results
RETURN a.name, b.name, c
LIMIT 10
```

