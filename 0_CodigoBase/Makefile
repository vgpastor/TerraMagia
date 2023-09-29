REPO_URL=your_ecr_repository_url
IMAGE_NAME=your_image_name
TAG=latest
CLUSTER_NAME=your_cluster_name
SERVICE_NAME=your_service_name

.PHONY: all build push deploy

all: build push deploy

# Construye la imagen Docker
build:
	@echo "Construyendo imagen Docker..."
	docker build -t $(IMAGE_NAME):$(TAG) -f /etc/docker/backend/Dockerfile /apps/backend


# Iniciar sesión en ECR y subir la imagen
push:
	@echo "Iniciando sesión en ECR..."
	aws ecr get-login-password --region your_region | docker login --username AWS --password-stdin $(REPO_URL)
	@echo "Subiendo imagen a ECR..."
	docker tag $(IMAGE_NAME):$(TAG) $(REPO_URL):$(TAG)
	docker push $(REPO_URL):$(TAG)

# Desplegar la nueva imagen en ECS
deploy:
	@echo "Desplegando en ECS..."
	aws ecs update-service --cluster $(CLUSTER_NAME) --service $(SERVICE_NAME) --force-new-deployment
