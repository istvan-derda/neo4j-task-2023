docker run -d -p 7474:7474 -p 7687:7687 \
--name neo4j --user="$(id -u):$(id -g)" \
-e apoc.export.file.enabled=true \
-e apoc.import.file.enabled=true \
-e apoc.import.file.use_neo4j_config=true \
-e NEO4J_PLUGINS=\[\"apoc\"\,\"graph-data-science\"\] \
--volume=$(pwd)/data:/data \
--volume=$(pwd)/import:/import \
--volume=$(pwd)/logs:/logs \
--volume=$(pwd)/plugins:/plugins \
--volume=$(pwd)/scripts:/scripts \
neo4j:5.6.0 

docker exec neo4j neo4j-admin dbms set-initial-password datenbanken

