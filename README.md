# docker-misp
A (nearly) production ready Dockered MISP

This is based on some of the work from the DSCO docker build. 

Getting Started:
- Copy the "default" configs removing "default" and edit the files in `server-configs`
    - Note: A dry run without this step will try and make a sane DEV build for docker-compose
- [Don't] run `generate.sh` in `./ssl` to generate some fake certs
- `docker-compose up --build`
- Login with 
    - User: admin@admin.test
    - Password: admin

Server image notes:
- Server file sizes
    - Original Image: 3.17GB
    - First attempt: 2.24GB
    - Remove chown: 1.56GB
    - PreBuild python modules, and only pull submodules we need: 800MB
    - PreBuild PHP modules: 664MB
- Server Saved: 2.5GB

- Modules file sizes:
    - Original: 1.36GB
    - Pre-build modules: 750MB
- Modules Saved: 640MB

