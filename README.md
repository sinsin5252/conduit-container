# Conduit-container

This project is a containerized web application consisting of three main components:

- **Frontend:** Angular
- **Backend:** Django
- **Database:** PostgreSQL

Each component runs in its own Docker container and communicates with the other services through the Docker network.

## Table of Contents

- [Quickstart](#quickstart)
    - [Prerequisities](#prerequisities)
    - [Run on Docker](#run-on-docker)
- [Usage](#usage)
    - [Frontend Configuration](#frontend-configuration)
        - [Webserver](#webserver)
        - [Ports](#ports)
        - [Volume](#volume)
    - [Backend Configuration](#backend-configuration)
        - [Image](#image)
        - [Enviroment](#environment)
        - [Volume](#volume-1)
    - [Database Configuration](#database-configuration)
        - [Image](#image-1)
        - [Enviroment](#environment-1)
        - [Volume](#volume-2)
    - [CI/CD Pipeline](#cicd-pipeline)

## Quickstart

In order to quickly get started with the project follow these steps:

### Prerequisities

- [Docker](https://www.docker.com/products/docker-desktop)

1. Clone the repositorys
```
git clone --recurse-submodules https://github.com/SinSin5252/conduit-container.git
cd conduit-container
```

2. Create a `.env` based on the `.env.example` file in the `conduit-container` directory.
```
cp .env.example .env
```

3. Before starting the containers, you need to change the `IP_ADDRESS_SERVER` in the `.env` file to the IP-Address of your server. 

### Run on Docker

Make sure Docker Desktop is running and that you are in the root directory of the project.

1. Start the the conduit container with:

```
docker compose up -d --build
```

3. Check whether all containers is running:

```
docker compose ps
```

4. To view all container logs:

```
docker compose logs
```

Once the containers started successfully, the Angular page can be accessed by entering [IP-Server]:8282 in the browser's address bar.

Alternatively, the containers can be started manually using docker run.

1. Build the frontend and backend images:
```
docker build -f Dockerfile.frontend -t conduit-frontend .
docker build -f Dockerfile.backend -t conduit-backend .
```

2. Create a Docker network for the containers:
```
docker network create conduit-network
```

3. Start the PostgreSQL database container:
```
docker run -d --name database --network conduit-network -e POSTGRES_DB=${POSTGRES_DB} -e POSTGRES_USER=${POSTGRES_USER} -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} postgres:10-alpine
```
4. Start the Django backend container:
```
docker run -d --name backend --network conduit-network -e DB_NAME=${POSTGRES_DB} -e DB_USER=${POSTGRES_USER} -e DB_PASSWORD=${POSTGRES_PASSWORD} -e DB_HOST=database -e DB_PORT=5432 -p 8000:8000 conduit-backend
```

5. Start the Angular frontend container:
```
docker run -d --name frontend --network conduit-network -p 8282:80 conduit-frontend
```

6. Check whether all containers are running:
```
docker ps
```

7. To view all container logs:
```
docker logs frontend
docker logs backend
docker logs database
```

## Usage

In this section you can read about the project a bit more in detail.


### Frontend Configuration

The Angular frontend container can be configured in the `docker-compose.yml` and `Dockerfile.frontend` file. The main important configuration options are `Webserver`, `ports`, and `volumes`.

#### Webserver

The Angular frontend uses Nginx as its web server. The Nginx configuration is defined in the `angular.conf` file and can be customized to configure settings such as the listening port, document root, routing, and proxy rules.

The default.conf file is copied into the frontend container during the Docker image build and can be modified to adapt the web server configuration to your requirements.

Nginx can be replaced with other web servers such as Apache HTTP Server or Caddy. When using a different web server, the `angular.conf` file and `Dockerfile.frontend` must be adapted accordingly.

#### Ports

The ports configuration defines which ports are exposed from the container to the host system.

For example:
```
ports:
  - "8282:80"
```

The first port (8282) is the port on the host machine, while the second port (80) is the port inside the frontend container.

This means that requests `http://[SERVER-IP]:8282` are forwarded to port 80 inside the Nginx frontend container.

#### Volume

The volumes configuration is used to persist Angular data outside the container.

For example:
```
volumes:
  - frontend_data:/frontend
```

The Angular files are stored in the Docker volume `frontend_data`. This ensures that the data is not lost when the Angular frontend container is stopped, restarted, or recreated.

Without a persistent volume, important files and uploaded content could be lost when the container is removed.

### Backend Configuration

#### Image

The backend container uses Django with Python 3.5.2. The Docker image is built using the `Dockerfile.backend` file.

The base image can be changed in the `Dockerfile.backend` file if a different Python version or Linux distribution is required.

#### Environment

he backend can be configured using environment variables defined in the docker-compose.yml file or in the `.env` file.

The main environment variables are:

DB_NAME – Name of the PostgreSQL database.
DB_USER – PostgreSQL username.
DB_PASSWORD – PostgreSQL password.
DB_HOST – Hostname of the database container.
DB_PORT – Port used by PostgreSQL.
IP_ADDRESS_SERVER – IP address used for server-specific configuration.

#### Volume

The backend container uses a Docker volume to persist or share backend application files.

The volume can be configured in the docker-compose.yml file:

volumes:
  - backend_data:/backend

The volume can be modified or removed depending on the application's requirements.

### Database Configuration

The database container is responsible for storing the application's data, including posts, pages, users, settings, and other relevant information. The database can be configured through the `docker-compose.yml` file.

#### Image

The image specifies which database software and version are used.

For example:

`image: postgres:10-alpine`

This uses `PostgreSQL 10` as the database container with `Alpine Linux` as its lightweight base distrobution.

#### Environment

The database credentials and database name are configured using environment variables.

For example:
```
environment:
  POSTGRES_DB: ${POSTGRES_DB}
  POSTGRES_USER: ${POSTGRES_USER}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

```
The values are taken from the `.env` file as example.

For example:
```
POSTGRES_DB=conduit
POSTGRES_USER=conduit
POSTGRES_PASSWORD=mysecretpassword
```

`POSTGRES_PASSWORD` defines the password for the PostgreSQL user.

`POSTGRES_DB` defines the database name that will be created for backend .

`POSTGRES_USER` defines the database user that backend uses to connect to PostgreSQL.

#### Volume

The PostgreSQL database should also use a persistent volume:

```
volumes:
  - postgres_data:/var/lib/postgresql
```

The volume stores the PostgreSQL database files outside the container.

This is important because removing and recreating the database container without a persistent volume can result in the loss of the entire database.

### CI/CD Pipeline

This project uses GitHub Actions to test the Docker Compose environment and deploy the application to a V-Server.

The workflow is defined in `.github/workflows/deployment.yaml.`

1. Triggering the workflow

The pipeline can be triggered in two ways:

Push to featurebranch/deployment: Automatically starts the workflow when changes are pushed to this branch.

Manual execution: The workflow can be started manually from the Actions tab in the GitHub repository using workflow_dispatch.

2. Test stage

Before deployment, the workflow runs the following checks on GitHub Actions Runner:

- Checks out the repository, including its Git submodules.

- Creates the .env file from .env.example.

- Starts the application using Docker Compose.

- Checks the container status.

- Sends an HTTP request to http://localhost:8282 to verify that the website responds.

- Verifies the container connections. 

- The deployment job runs only if the test job succeeds.

3. Deployment stage

After successful tests, GitHub Actions connects to the V-Server via SSH and performs the following steps:

- Changes to the conduit-container directory.

- Switches to the main branch if necessary.

- Pulls the latest changes from GitHub.

- Initializes and updates the Git submodules.

- Stops the existing Docker Compose containers.

- Rebuilds the Docker images and starts the updated containers.

4. Required GitHub Secrets

The following repository secrets must be configured under `Settings` → `Secrets and variables` → `Actions`:

VM_HOST : The IP address or hostname of the target V-Server.

VM_USER : The username of the user account used to connect to the V-Server via SSH.

VM_SSH_KEY: The private SSH key used by GitHub Actions to establish an SSH connection to the V-Server.

To configure this access:

1. Generate a separate SSH key pair on the V-Server for repository access.

2. Add the public key to the GitHub account under Settings → SSH and GPG keys → New SSH key, selecting Authentication Key.

3. Store the corresponding private key on the V-Server and configure SSH to use it when connecting to GitHub.

4. Verify the connection using ssh -T git@github.com.



The V-Server must also have Git access to the repository over ssh in `Profile` → `Settings` → `SSH and GPG keys` → `Authentication keys`.

Security note: Private SSH keys must never be committed to the repository or shared publicly. Store the GitHub Actions deployment key in repository secrets and restrict access to the server and repository keys.

5. Deployment requirements

Before running the pipeline, ensure that:

- Docker and the Docker Compose plugin are installed on the V-Server.

- The repository is available at ~/conduit-container for the configured SSH user.

- The main branch exists on the V-Server and on GitHub.

- The .env file on the V-Server contains the required production configuration.

- The application exposes its website on port 8282 for the test stage.

Note: The workflow deploys the main branch to the V-Server, even though automatic workflow execution is triggered by pushes to featurebranch/deployment. Make sure the changes intended for production have been merged into main before deployment.
