#!/bin/bash
yum update -y
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone the repository
git clone https://github.com/philschmid/open-webui-sagemaker-example.git /home/ec2-user/open-webui-sagemaker-example
cd /home/ec2-user/open-webui-sagemaker-example

# Create .env file
cat << EOF > .env
AWS_DEFAULT_REGION=${AWS::Region}
SAGEMAKER_ENDPOINT_NAME=${EndpointName}
EOF

# Create docker-compose.yml
cat << EOF > docker-compose.yaml
version: '3'
services:
  pipelines:
    image: ghcr.io/open-webui/pipelines:latest
    ports:
      - '9099:9099'
    volumes:
      - ./pipelines-remote:/app/pipelines
    env_file:
      - .env
    extra_hosts:
      - 'host.docker.internal:host-gateway'
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - '3000:8080'
    volumes:
      - ./open-webui:/app/backend/data
    environment:
      - WEBUI_AUTH=False # Set to True to enable authentication
      - OPENAI_API_BASE_URL=http://host.docker.internal:9099 # URL for the pipelines service
      - OPENAI_API_KEY=0p3n-w3bu! # API key for the pipelines service (default)
    depends_on:
      - pipelines
EOF

# Start the services
docker-compose up -d