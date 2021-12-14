# Nmap Monitor

This app in docker container will do an nmap scan of whatever network or servers you give it, then post webhook to slack if it finds a difference.


# Run
```bash
cp .env.sample .env

docker-compose up -d
```


# Scripts tests
Run the command:
```bash
clear && ./tests/run.sh
```
