
#  Lancer tout
## docker compose --profile front up --build 

# relancer après changement de code
## docker compose --profile front down -v
## docker compose --profile front up --build



# URLs :
# - Vitrine     → http://localhost:3002 
# - Backoffice  → http://localhost:3001 
# - pgAdmin     → http://localhost:8081 (login dans docker-compose.yml)
# - backend     → http://localhost:3000 (login dans docker-compose.yml)