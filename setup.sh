docker run -p 7474:7474 -p 7687:7687 \
--name neo4j --user="$(id -u):$(id -g)" \
-e apoc.export.file.enabled=true \
-e apoc.import.file.enabled=true \
-e apoc.import.file.use_neo4j_config=true \
-e NEO4J_PLUGINS=\[\"apoc\"\,\"graph-data-science\"\] \
--volume=$HOME/git/nosql2023/data:/data \
--volume=$HOME/git/nosql2023/import:/import \
--volume=$HOME/git/nosql2023/logs:/logs \
--volume=$HOME/git/nosql2023/plugins:/plugins \
neo4j:5.6.0

