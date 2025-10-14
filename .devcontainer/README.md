# Devcontainer

This folder contains the configuration files for a development container (devcontainer) that can be used to create a consistent development environment (e.g., using Visual Studio Code with the Remote - Containers extension).

## Contents

- `devcontainer.json`: The main configuration file for the devcontainer, specifying settings, extensions, and other options.
- `Dockerfile`: A custom Dockerfile that defines the base image and additional setup for the devcontainer.

## Usage

1. Ensure you have Docker installed and running on your machine.
2. Install Visual Studio Code and the Remote - Containers extension.
3. Open this project in Visual Studio Code.
4. Use the Command Palette (Ctrl+Shift+P) and select "Remote-Containers: Open Folder in Container..." to open the project in the devcontainer.
5. Visual Studio Code will build the container based on the provided configuration and open the project inside the container.

## Envio Deployment Conflict in Dev Container

The core issue was a fundamental networking conflict between our Dev Container environment and the envio dev tool's requirements.

The envio dev process internally launches its own dependencies (Postgres, Hasura) using a self-contained Docker Compose setup and expects to connect to them via internal service names (e.g., envio-postgres).

First we went for Docker-Outside-of-Docker (DooD) that uses the Host's Docker daemon (DooD). But it placed the Dev Container and the services on two different, isolated networks. This prevented envio dev from resolving the service names, resulting in a persistent health check timeout.

The resolution was to switch the Dev Container to a Docker-in-Docker (DinD) setup. DinD runs a nested Docker daemon inside the Dev Container. envio dev launches its services using this nested daemon, guaranteeing that the envio tool and its services are all on the same internal network.

Service name resolution works instantly, resolving the timeout.
