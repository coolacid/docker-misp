# docker-misp

[![Build Status](https://travis-ci.org/coolacid/docker-misp.svg?branch=master)](https://travis-ci.org/coolacid/docker-misp)

A (nearly) production ready Dockered MISP

This is based on some of the work from the DSCO docker build, nearly all of the details have been rewritten. 

- Components are split out where possible, currently this is only the MISP modules
- Overwritable configuration files
- Allows volumes for file store
- Cron job runs updates, pushes, and pulls - Logs go to docker logs
- Docker-Compose uses off the shelf images for Redis and MySQL
- Images directly from docker hub, no build required
- Slimmed down images by using build stages and slim parent image, removes unnecessary files from images


Getting Started:
- Copy the "default" configs removing "default" and edit the files in `server-configs`
    - Note: A dry run without this step will try and make a sane DEV build for docker-compose
- Run `generate.sh` in `./ssl` to generate some fake certs
- `docker-compose up --build`
- Login with 
    - User: admin@admin.test
    - Password: admin

Server image file sizes:
- Core server
    - Original Image: 3.17GB
    - First attempt: 2.24GB
    - Remove chown: 1.56GB
    - PreBuild python modules, and only pull submodules we need: 800MB
    - PreBuild PHP modules: 664MB
- Saved: 2.5GB

- Modules:
    - Original: 1.36GB
    - Pre-build modules: 750MB
- Saved: 640MB
