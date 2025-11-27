terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "~> 2.0"
        }
    }
}

provider "kubernetes" {
    config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "ns" {
    metadata {
        name = "project2-namespace"
    }
}

# Nginx service
resource "kubernetes_service" "nginx_service" {
    metadata {
        namespace = kubernetes_namespace.ns.metadata[0].name
        name = "nginx-service"
    }

    spec {
        selector = {
            app = "nginx"
        }
        port {
            protocol = "TCP"
            port = 80
            target_port = 80
        }

        type = "ClusterIP"
    }
}

# Nginx deployement 
resource "kubernetes_deployment" "kubernetes_nginx_deployment" {
    metadata {
        namespace = kubernetes_namespace.ns.metadata[0].name
        name = "nginx-deployment"
        labels = {
            app = "nginx"
        }
    } 

    spec {
        replicas = 1 

        selector {
            match_labels = {
                app = "nginx"
            }
        }

        template {
            metadata {
                labels = {
                    app = "nginx"
                }
            }

            spec {
                container {
                    name  = "nginx-container"
                    image = "nginx:latest" 

                    port {
                        container_port = 80
                    }

                    resources {
                        requests = {
                            cpu    = "100m"
                            memory = "200Mi"
                        }
                    }
                }
            }
        }
    }
}

# HPA for nginx deployement
resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
    metadata {
        name      = "kubernetes-hpa"
        namespace = kubernetes_namespace.ns.metadata[0].name
    }

    spec {
        max_replicas = 5 
        min_replicas = 1 

        scale_target_ref {
            api_version = "apps/v1"
            kind = "Deployment"
            name = kubernetes_deployment.kubernetes_nginx_deployment.metadata[0].name
        }

        target_cpu_utilization_percentage = 50 
    }
}