#!/usr/bin/env sh

# remove old docker versions
sudo apt-get remove docker docker-engine docker.io

# Install packages to allow apt to use a repository over HTTPS:
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common 

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add docker repo:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#Update the apt package index
sudo apt-get update -y

# Install docker-ce:
sudo apt-get install docker-ce -y

# Install docker-compose
# Download
sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
# Apply permissions
sudo chmod +x /usr/local/bin/docker-compose

# Delete all previously containers
sudo docker rm $(sudo docker ps -a -q) -f
# Delete previously containers images
sudo docker rmi $(sudo docker images -q) -f

#install requirements
sudo apt install mosquitto mosquitto-clients redis-server redis-tools postgresql 

# Configure PostgreSQL
sudo -u postgres psql

-- set up the users and the passwords
-- (note that it is important to use single quotes and a semicolon at the end!)
create role loraserver_as with login password 'dbpassword';
create role loraserver_ns with login password 'dbpassword';

-- create the database for the servers
create database loraserver_as with owner loraserver_as;
create database loraserver_ns with owner loraserver_ns;

-- change to the LoRa App Server database
\c loraserver_as

-- enable the pq_trgm extension
-- (this is needed to facilidate the search feature)
create extension pg_trgm;

-- exit psql
\q

# Clone LoraServer docker-compose repo
git clone https://github.com/brocaar/loraserver-docker.git

# Go to folder for LoraServer deployment
cd loraserver-docker

# Deploy simple LoraServer
sudo docker-compose up -d

# Return to main folder
cd ..

# 1000 - Portainer
# 1001 - cAdvisor
# 1002 - Node-Red
# 1003 - Swagger Editor

# Deploy Portainer for easiest container management
sudo docker run -d -p 1000:9000 --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer

# Deploy Node-Red
sudo docker run -d -p 1002:1880 --network="thingsboard-docker_default" --restart=always --name Node-Red nodered/node-red-docker

# Deploy Swagger Editor
sudo docker run -d -p 1003:8080 --network="thingsboard-docker_default" --restart=always swaggerapi/swagger-editor

#Deploy cAdvisor for monitoring resources
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=1001:8080 \
  --detach=true \
  --restart=always \
  --name=cadvisor \
  google/cadvisor:latest

# Cleaning gurbage
