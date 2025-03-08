# React Flask PostgreSQL Boilerplate with Docker and Kubernetes

A modern web application boilerplate featuring React frontend, Flask backend, and PostgreSQL database, all containerized with Docker and orchestrated with Kubernetes. Used as a demo for local Kubernetes deployments on MacOS with several nodes.

## Development

Initially this was forked off https://github.com/tomahim/react-flask-postgres-boilerplate-with-docker

I chose this project because this is a tech stack I am familiar and comfortable working with. Although the project itself is out of date so I had to regenerate the react frontend and use an updated flask for the backend. I updated the database to have multiple baseball players as that is my favourite sport.

Several things came up during development. when generating docker images to use in the kubernetes deployment you must make sure that you generate the images with the minikube docker daemon and not the base daemon on MacOS. Also for the ingress you have to update /etc/hosts to connect through 127.0.0.1 rather than minikupe ip and make sure you have a tunnel running locally to handle the ingress traffic while deploying locally.

Overall I believe this project is a good demonstration of how to deploy a multi-node cluster using ingress and secret management locally on MacOS.

## Features

- **Frontend**: React application with modern hooks and clean architecture
- **Backend**: Flask REST API with SQLAlchemy ORM
- **Database**: PostgreSQL for reliable data storage
- **Container**: Docker for consistent development and deployment
- **Orchestration**: Kubernetes for container orchestration
- **Ingress**: NGINX Ingress Controller with SSL/TLS support
- **Development**: Local development support with Docker Compose
- **Security**: Proper secrets management and TLS configuration

## Prerequisites

- Docker and Docker Compose
- MiniKube Kubernetes Cluster
- kubectl CLI tool
- Node.js and npm (for local development)
- Python 3.8+ (for local development)
- OpenSSL (for TLS certificate generation)

## Security Setup

### TLS Certificate Generation (Development)
```bash
# Generate self-signed certificate for local development
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=baseball-app.test"
```

### Secrets Management
The project uses Kubernetes secrets for sensitive data. Example files are provided with `.example` suffix.

1. Create your own secret files from examples:
   ```bash
   cp kubernetes/postgres-secret.example.yaml kubernetes/postgres-secret.yaml
   ```

2. Edit the secret files with your secure values:
   ```bash
   # Edit kubernetes/postgres-secret.yaml with your credentials
   ```

3. Apply secrets to cluster:
   ```bash
   kubectl apply -f kubernetes/postgres-secret.yaml
   kubectl create secret tls baseball-app-tls --cert=tls.crt --key=tls.key
   ```

⚠️ **Important Security Notes**:
- Never commit real secrets or certificates to version control
- The `.gitignore` file is configured to exclude:
  - `.secrets/` directory
  - `.certs/` directory
  - `*.key`, `*.crt`, `*.pem` files
  - Environment files (`.env*`)
- For production:
  - Use a proper certificate authority for TLS certificates
  - Use a secure secret management solution (e.g., HashiCorp Vault, AWS Secrets Manager)
  - Consider using Kubernetes external secrets operator
  - Regularly rotate credentials

## Quick Start with Docker Compose

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/react-flask-postgres-boilerplate-with-docker.git
   cd react-flask-postgres-boilerplate-with-docker
   ```

2. Start the application:
   ```bash
   docker-compose up --build
   ```

3. Access the application:
   - Frontend: http://localhost:80
   - Backend API: http://localhost:5000
   - API Health Check: http://localhost:5000/health

## Kubernetes Deployment (Minikube on MacOS)

1. Create the required secrets:
   ```bash
   kubectl create secret tls baseball-app-tls --cert=tls.crt --key=tls.key
   kubectl create secret generic postgres-credentials \
     --from-literal=username=myuser \
     --from-literal=password=mypassword \
     --from-literal=database-url="postgresql://myuser:mypassword@postgres:5432/sport_stats"
   ```

2. Make sure you are using the Docker Daemon of minikube when starting it:
   ```bash
   minikube start --driver=docker
   eval $(minikube docker-env)
   ```

3. Build the docker images:
   ```bash
   docker build -t flask:latest backend
   docker build -t frontend:latest frontend
   ```

4. Apply Kubernetes configurations:
   ```bash
   kubectl apply -f kubernetes/postgres-pvc.yaml
   kubectl apply -f kubernetes/postgres-deployment.yaml
   kubectl apply -f kubernetes/postgres-service.yaml
   kubectl apply -f kubernetes/backend-deployment.yaml
   kubectl apply -f kubernetes/backend-service.yaml
   kubectl apply -f kubernetes/frontend-deployment.yaml
   kubectl apply -f kubernetes/frontend-service.yaml
   kubectl apply -f kubernetes/ingress.yaml
   ```

5. Add DNS entry (local development):
   ```bash
   # Add to /etc/hosts
   127.0.0.1 baseball-app.test
   ```

6. Open a ssh tunnel on minikube for the ingress:
   ```bash
   sudo minikube tunnel
   ```

7. Access the application:
   - Web UI: https://baseball-app.test
   - API Endpoint: https://baseball-app.test/api/data
   - Health Check: https://baseball-app.test/api/health

## Project Structure

```
.
├── backend/                 # Flask backend application
│   ├── Dockerfile          # Backend container configuration
│   ├── app.py             # Main application file
│   └── requirements.txt    # Python dependencies
├── frontend/               # React frontend application
│   ├── Dockerfile         # Frontend container configuration
│   ├── package.json       # Node.js dependencies
│   └── src/               # React source code
├── database/              # Database initialization
│   └── init.sql          # PostgreSQL initialization script
├── kubernetes/           # Kubernetes configuration files
│   ├── backend/         # Backend deployments and services
│   ├── frontend/        # Frontend deployments and services
│   └── postgres/        # Database deployments and services
└── docker-compose.yml    # Local development configuration
```

## Development

### Local Development without Docker

1. Backend Setup:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # or `venv\Scripts\activate` on Windows
   pip install -r requirements.txt
   export DATABASE_URL="postgresql://myuser:mypassword@localhost:5432/sport_stats"
   python app.py
   ```

2. Frontend Setup:
   ```bash
   cd frontend
   npm install
   export REACT_APP_API_URL=http://localhost:5000/api
   npm start
   ```

### Building Docker Images

```bash
# Build frontend
docker build -t frontend:latest ./frontend

# Build backend
docker build -t flask:latest ./backend
```

## API Endpoints

- `GET /api/health` - Health check endpoint
- `GET /api/data` - Retrieve all baseball players

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.