provider "azurerm" {
  features {}
  subscription_id = "a8827913-8a07-4a54-b714-533fa1d335fb"
  skip_provider_registration = true
}

resource "azurerm_resource_group" "Phoenix" {
  name     = "phoenix-resources"
  location = "eastus"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"
  name                = "Confiz"
  resource_group_name = "Phoenix"

  container_type = "compose"

  container_config = <<EOF
version: "3"

services:
  nginx:
    ports:
      - 443:443
      - 80:80
    container_name: sonar-nginx
    image: nginx:latest
    restart: unless-stopped
    #restart: always
    depends_on:
      - sonarqube
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./certs/sonar:/etc/pki/tls/sonar
    networks:
      - sonar-network
  sonarqube:
    image: sonar:latest
    container_name: sonarqube
    build:
      context: .
      dockerfile: sonar.dockerfile
    depends_on:
      - db
    env_file: ./env/sonar.env
    restart: unless-stopped
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    expose:
      - "9000"
    networks:
      - sonar-network
  db:
    image: postgres:12
    container_name: sonar-db
    restart: unless-stopped
    env_file: ./env/db.env
    volumes:
      - postgresql:/var/lib/postgresql
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - sonar-network

networks:
  sonar-network:
    driver: bridge
volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql:
  postgresql_data:
  sonar_es_data:
EOF
}
