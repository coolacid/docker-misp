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
- File Sizes
    - Original Image: 3.17GB
    - First attempt: 2.24GB
    - Remove chown: 1.56GB
- Saved: 1.61GB
