
# Simple Dockerfile for Foundry VTT

This repository provides a simple Dockerfile to run [Foundry VTT](https://foundryvtt.com/) with [Docker](https://www.docker.com/).

## Requirements
- A Foundry VTT distribution (`foundryvtt-x.y.z.zip` unpacked into a `foundryvtt` directory)
- Docker


## Setup
1. [Download foundryvtt latest Linux version](https://foundryvtt.com/community/leandroparisi/licenses)
2. Extract files from downloaded zip
3. Put all files (raw files, without a top level folder) inside foundryvtt folder
4. Move Dockerfile inside this folder into foundryvtt folder
5. Build the image
```
  docker build -t foundryvtt .
```
6. For local testing, create data folder
```
  mkdir ./data
```
7. Run image
```
  docker run --name fvtt \
  -p 30000:30000 \
  -v `pwd`/data:/home/foundry/data \
  -d foundryvtt
```
8. Test accessing localhost:30000


## Deploy
1. Delete data folder inside foundryvtt
2. Move fly.toml into foundryvtt folder
3. Run (from inside foundryvtt folder)
```
  fly deploy
```

## Scripts
1. Increase volume size (size in GB)
```
  fly volumes extend foundryvtt_data --size 10 
```


_________________________________

# DEPRECATED
## Usage

### Manual

#### Build the Image
Put the `Dockerfile` in the `foundryvtt` directory. Build the image by running within the `foundryvtt` directory:
```shell script
docker build -t foundryvtt .
```

#### Create a container
To create a  container run the following command:
```shell script
docker run --name fvtt \
  -p <port on host>:30000 \
  -v <data directory on host>:/home/foundry/data \
  -d foundryvtt
```

#### Update Container
If new version of Foundry VTT was released and you'd like to update, make sure to stop and remove the existing container:
```shell script
docker stop fvtt
docker rm fvtt
```

Afterwards, repeat the build and creation steps above.

### With docker-compose

#### Setup of Context Directory
Copy the `Dockerfile` into your already downloaded (and unzipped) `foundryvtt` directory.

Then create a `docker-compose.yaml` file within the directory as follows (take care of the placeholders):
```yaml
version: '3.7'

services:
  fvtt:
    build:
      context: ./
      dockerfile: ./Dockerfile
    image: foundryvtt
    ports:
      - '<port on host>:30000'
    volumes:
      - '<data directory on host>:/home/foundry/data'
    restart: always
```

#### Create Image and Run Container
```shell script
docker-compose build
```

## Contributing
Pull requests are very welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
