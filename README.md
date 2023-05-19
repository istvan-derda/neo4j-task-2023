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
MERGE (p)-[:publishedIn]->(v);
```
