terraform {
  required_version = ">= 1.3.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}

# Networking Rules: Isolated Staging Bridge Network
resource "docker_network" "staging_network" {
  name   = "${var.environment}_${var.network_name}"
  driver = "bridge"
}

# Database Layer: PostgreSQL Image & Container
resource "docker_image" "postgres_img" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_container" "staging_db" {
  name  = "${var.environment}_postgres_db"
  image = docker_image.postgres_img.image_id

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}"
  ]

  ports {
    internal = 5432
    external = var.db_port
  }

  networks_advanced {
    name = docker_network.staging_network.name
  }
}

# Application Server Layer: Nginx App Server Image & Container
resource "docker_image" "nginx_img" {
  name         = "nginx:stable-alpine"
  keep_locally = true
}

resource "docker_container" "staging_app" {
  name  = "${var.environment}_app_server"
  image = docker_image.nginx_img.image_id

  ports {
    internal = 80
    external = var.app_port
  }

  networks_advanced {
    name = docker_network.staging_network.name
  }

  depends_on = [docker_container.staging_db]
}
