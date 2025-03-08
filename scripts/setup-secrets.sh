#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_message "❌ $1 is not installed. Please install it first." "$RED"
        exit 1
    fi
}

# Check required commands
print_message "Checking required tools..." "$YELLOW"
check_command "openssl"
check_command "kubectl"

# Create necessary directories
print_message "\nCreating directories..." "$YELLOW"
mkdir -p .secrets .certs

# Generate TLS certificates
print_message "\nGenerating TLS certificates..." "$YELLOW"
if [ -f "tls.key" ] || [ -f "tls.crt" ]; then
    print_message "⚠️  TLS certificates already exist. Do you want to regenerate them? (y/N)" "$YELLOW"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        rm -f tls.key tls.crt
    else
        print_message "Skipping TLS certificate generation." "$GREEN"
    fi
fi

if [ ! -f "tls.key" ] && [ ! -f "tls.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout tls.key -out tls.crt \
        -subj "/CN=baseball-app.test" \
        -addext "subjectAltName=DNS:baseball-app.test"
    
    if [ $? -eq 0 ]; then
        print_message "✅ TLS certificates generated successfully" "$GREEN"
        # Move certificates to .certs directory
        mv tls.key tls.crt .certs/
    else
        print_message "❌ Failed to generate TLS certificates" "$RED"
        exit 1
    fi
fi

# Setup environment files
print_message "\nSetting up environment files..." "$YELLOW"
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_message "✅ Created .env file from example" "$GREEN"
    else
        print_message "❌ .env.example not found" "$RED"
        exit 1
    fi
fi

# Generate random credentials for PostgreSQL
POSTGRES_USER="dbuser_$(openssl rand -hex 4)"
POSTGRES_PASSWORD=$(openssl rand -base64 20)
DB_NAME="sport_stats"

# Create Kubernetes secrets
print_message "\nSetting up Kubernetes secrets..." "$YELLOW"

# Create PostgreSQL credentials secret
cat << EOF > .secrets/postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
type: Opaque
stringData:
  username: "${POSTGRES_USER}"
  password: "${POSTGRES_PASSWORD}"
  database-url: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${DB_NAME}"
EOF

print_message "✅ Created PostgreSQL secrets file" "$GREEN"

# Apply secrets to Kubernetes
print_message "\nApplying secrets to Kubernetes cluster..." "$YELLOW"

# Check if kubectl can connect to the cluster
if ! kubectl get nodes &> /dev/null; then
    print_message "❌ Cannot connect to Kubernetes cluster. Is it running?" "$RED"
    exit 1
fi

# Apply PostgreSQL secrets
kubectl apply -f .secrets/postgres-secret.yaml
if [ $? -eq 0 ]; then
    print_message "✅ Applied PostgreSQL secrets to cluster" "$GREEN"
else
    print_message "❌ Failed to apply PostgreSQL secrets" "$RED"
    exit 1
fi

# Create TLS secret
kubectl create secret tls baseball-app-tls --cert=.certs/tls.crt --key=.certs/tls.key --dry-run=client -o yaml | kubectl apply -f -
if [ $? -eq 0 ]; then
    print_message "✅ Applied TLS secret to cluster" "$GREEN"
else
    print_message "❌ Failed to apply TLS secret" "$RED"
    exit 1
fi

# Update local environment file
print_message "\nUpdating local environment file..." "$YELLOW"
sed -i '' "s/POSTGRES_USER=.*/POSTGRES_USER=${POSTGRES_USER}/" .env
sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/" .env
sed -i '' "s#DATABASE_URL=.*#DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${DB_NAME}#" .env

# Add entry to /etc/hosts if not present
print_message "\nChecking /etc/hosts entry..." "$YELLOW"
if ! grep -q "baseball-app.test" /etc/hosts; then
    print_message "Adding baseball-app.test to /etc/hosts (requires sudo)..." "$YELLOW"
    echo "127.0.0.1 baseball-app.test" | sudo tee -a /etc/hosts
    if [ $? -eq 0 ]; then
        print_message "✅ Added baseball-app.test to /etc/hosts" "$GREEN"
    else
        print_message "❌ Failed to update /etc/hosts" "$RED"
        print_message "Please manually add: 127.0.0.1 baseball-app.test" "$YELLOW"
    fi
else
    print_message "✅ baseball-app.test already in /etc/hosts" "$GREEN"
fi

print_message "\n🎉 Setup completed successfully!" "$GREEN"
print_message "\nGenerated credentials:" "$YELLOW"
print_message "PostgreSQL User: ${POSTGRES_USER}" "$YELLOW"
print_message "PostgreSQL Password: ${POSTGRES_PASSWORD}" "$YELLOW"
print_message "\nPlease save these credentials in a secure location!" "$RED"
print_message "\nNext steps:" "$YELLOW"
print_message "1. Start your Kubernetes cluster if not already running" "$YELLOW"
print_message "2. Run: kubectl apply -f kubernetes/" "$YELLOW"
print_message "3. Access the application at https://baseball-app.test" "$YELLOW" 