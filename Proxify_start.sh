#!/bin/bash

# Exit if non-root try to run the script
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

# $1: var to read
read_val()
{
    varName="${1}"
    grep "${varName}" ./environment.env | cut -d "=" -f 2- | xargs
}

ROOTUSERDB=$(read_val ROOTUSERDB)
ROOTPASSDB=$(read_val ROOTPASSDB)
YOURMONGODB=$(read_val YOURMONGODB)
YOURPROXMOXURL=$(read_val YOURPROXMOXURL)
YOURTOKENID=$(read_val YOURTOKENID)
YOURSECRET=$(read_val YOURSECRET)
JWTSECRETKEY=$(read_val JWTSECRETKEY)

# Installing dependencies
if ! dnf install -y nodejs docker; then 
  echo "Error installing dependencies" >&2
  exit 1
fi
if ! dnf update -y; then 
  echo "Error updating" >&2
  exit 1
fi
systemctl start docker
systemctl enable docker

# Making and running a mongodb on docker
mkdir -p ~/mongoDB
cd ~/mongoDB
if ! docker pull mongo:4.4.6; then
  echo "Error pulling mongodb image" >&2
  exit 1
fi
docker run -d \
  --name mongo-container \
  -e MONGO_INITDB_ROOT_USERNAME="${ROOTUSERDB}" \
  -e MONGO_INITDB_ROOT_PASSWORD="${ROOTPASSDB}" \
  -p 27017:27017 \
  -v "$PWD"/mongo-entrypoint/:/docker-entrypoint-initdb.d/ \
  mongo:4.4.6 mongod

# Cloning proxify from github
cd ~/
if ! git clone https://github.com/sbendarsky/Proxify.git; then
  echo "Error cloning repository" >&2
  exit 1
fi

# Adding env strings to config file
cd ~/Proxify
sed -i "s|YOURMONGODB|${YOURMONGODB}|" ~/Proxify/next.config.js
sed -i "s|YOURPROXMOXURL|${YOURPROXMOXURL}|" ~/Proxify/next.config.js
sed -i "s|YOURTOKENID|${YOURTOKENID}|" ~/Proxify/next.config.js
sed -i "s|YOURSECRET|${YOURSECRET}|" ~/Proxify/next.config.js
sed -i "s|JWTSECRETKEY|${JWTSECRETKEY}|" ~/Proxify/next.config.js

#installing and running proxify
if ! npm install; then
  echo "Error installing Proxify"
  exit 1
fi
firefox -new-tab "http://localhost:3000"
npm run dev
