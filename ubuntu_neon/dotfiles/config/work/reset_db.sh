sudo docker compose -f docker-compose.db.yml down

sudo rm -rf data

docker compose -f docker-compose.db.yml up -d
