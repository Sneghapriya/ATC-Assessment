// Configure the terraform google provider
provider "google" {
  project     = "<project-name>"
  region      = "us-central1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.2.0"
    }
  }
  backend "gcs" {
    bucket = "<bucket-name>"
    prefix = "<folder in the bucket>" // Optional: Adjust the prefix as needed
    credentials = "<path/to/json/key>"
  }
}

# Create VPC
resource "google_compute_network" "vpc_network" {
  name = "gke-vpc"
}

# Create Subnet
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# Firewall rule to allow internal communication within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}

# Firewall rule to allow external access to the application
resource "google_compute_firewall" "allow_http" {
  name    = "allow-gke-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "9090"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create GKE Cluster
resource "google_container_cluster" "primary" {
  name               = "gke-cluster"
  location           = "us-central1-c"
  network            = google_compute_network.vpc_network.id
  subnetwork         = google_compute_subnetwork.gke_subnet.id
  initial_node_count = 2

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
