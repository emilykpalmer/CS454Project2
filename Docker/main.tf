terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 2.23.1"
    }
  }
}

provider "docker" {}

# Custom network
resource "docker_network" "docker_project_network" {
  name = "docker_project_network"
}

# Postgres image
resource "docker_image" "postgres_image" {
    name = "postgres:latest"
    keep_locally = true
}

# Variable for Postgres database password
variable "database_password" {
  type = string
  sensitive = true
}

# Postgres volume
resource "docker_volume" "postgres_volume" {
    name = "postgres_volume"
}

# Postgres container
resource "docker_container" "postgres_container" {
    name = "postgres-container"
    image = docker_image.postgres_image.image_id

    env = [
        "POSTGRES_USER=emilypalmer",
        "POSTGRES_PASSWORD=${var.database_password}",
        "POSTGRES_DB=Project2DB"
    ]

    ports {
        internal = 5432
        external = 5432
    }

    # Use custom network for the container
    networks_advanced {
      name = docker_network.docker_project_network.name
    }

    # Mounts the persistent volume
    mounts {
      target = "/var/lib/postgresql/18/docker"
      source = docker_volume.postgres_volume.name
      type = "volume"
    }
}

# Python backend image
resource "docker_image" "python_image" {
    name = "python_image:latest"
    build {
        path = "." 
        dockerfile = "Dockerfile"
    }

    keep_locally = true
}

# Python backend container
resource "docker_container" "python_container" {
    name = "python_container"
    image = docker_image.python_image.image_id

    ports {
        internal = 5000
        external = 5000
    }

    # Use custom network for the container
    networks_advanced {
      name = docker_network.docker_project_network.name
    }

    depends_on = [docker_container.postgres_container]

    must_run = true
}

# Nginx image
resource "docker_image" "nginx_image" {
  name = "nginx:latest"
  keep_locally = true
}

# Nginx container
resource "docker_container" "nginx_container" {
  name  = "custom_nginx_server"
  image = docker_image.nginx_image.image_id

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path = abspath("${path.module}/test_nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only = true 
  }

  # Use custom network for the container
  networks_advanced {
      name = docker_network.docker_project_network.name
    }

  must_run = true

  depends_on = [docker_container.python_container]
}

# Redis image
resource "docker_image" "redis_image" {
  name = "redis:latest"
  keep_locally = true
}

# Redis container
resource "docker_container" "redis_container" {
  name = "redis_container"
  image = docker_image.redis_image.image_id

  ports {
    internal = 6379
    external = 6379
  }

  # Use custom network for the conatiner
  networks_advanced {
    name = docker_network.docker_project_network.name
  }
}