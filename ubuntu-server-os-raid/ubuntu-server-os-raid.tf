# ubuntu-server-os-raid.tf

# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

# Define variables for your project and region.
variable "gcp_project_ubuntu" {
  description = "The GCP project ID to deploy to."
  default     = "parsec-ws-deploy"
}

variable "gcp_zone_ubuntu" {
  description = "The GCP zone to deploy to."
  default     = "us-east1-c"
}

variable "instance_name_ubuntu" {
  description = "Name for the Ubuntu server VM."
  default     = "ubuntu-server-raid"
}

variable "gcp_billing_account_ubuntu" {
  description = "The GCP billing account ID to use."
  default     = "01FD32-9F0EF2-099DD7"
}

provider "google" {
  alias           = "ubuntu"
  project         = var.gcp_project_ubuntu
  billing_project = var.gcp_billing_account_ubuntu
}

# Create the first OS disk
resource "google_compute_disk" "os_disk_1" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-os-disk-1"
  type     = "hyperdisk-balanced"
  size     = 50 # Larger OS disk for RAID
  image    = "ubuntu-os-cloud/ubuntu-2204-lts"

  provisioned_iops = 3000
}

# Create the second OS disk (for RAID)
resource "google_compute_disk" "os_disk_2" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-os-disk-2"
  type     = "hyperdisk-balanced"
  size     = 50 # Same size as first disk

  provisioned_iops = 3000
}

# Define the Compute Engine instance for Ubuntu server with OS RAID
resource "google_compute_instance" "ubuntu_server_raid" {
  provider     = google.ubuntu
  project      = var.gcp_project_ubuntu
  zone         = var.gcp_zone_ubuntu
  name         = var.instance_name_ubuntu
  machine_type = "n1-standard-8"
  tags         = ["ubuntu-server"]

  # Use the first disk as boot disk
  boot_disk {
    source = google_compute_disk.os_disk_1.id
  }

  # Attach the second OS disk for RAID
  attached_disk {
    source      = google_compute_disk.os_disk_2.id
    device_name = "os-disk-2"
  }

  # Storage RAID disks
  attached_disk {
    source      = google_compute_disk.storage_disk_1.id
    device_name = "storage-disk-1"
  }

  attached_disk {
    source      = google_compute_disk.storage_disk_2.id
    device_name = "storage-disk-2"
  }

  # Add a small scratch disk (Local SSD)
  scratch_disk {
    interface = "NVME"
  }

  # Attach the NVIDIA T4 GPU
  guest_accelerator {
    type  = "nvidia-tesla-t4-vws"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  # Use custom startup script for OS RAID setup
  metadata = {
    startup-script = file("../scripts/ubuntu-os-raid-startup.sh")
  }

  allow_stopping_for_update = true
}

# Storage disks (same as before)
resource "google_compute_disk" "storage_disk_1" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-storage-disk-1"
  type     = "hyperdisk-balanced"
  size     = 500

  provisioned_iops = 3000
}

resource "google_compute_disk" "storage_disk_2" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-storage-disk-2"
  type     = "hyperdisk-balanced"
  size     = 500

  provisioned_iops = 3000
}

# Firewall rule
resource "google_compute_firewall" "allow_ssh_ubuntu" {
  provider = google.ubuntu
  name     = "allow-ubuntu-ssh-raid"
  network  = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["ubuntu-server"]
  source_ranges = ["50.47.212.98/32"]
}

# Outputs
output "ubuntu_instance_ip" {
  value = google_compute_instance.ubuntu_server_raid.network_interface[0].access_config[0].nat_ip
}

output "os_disk_1_name" {
  value = google_compute_disk.os_disk_1.name
}

output "os_disk_2_name" {
  value = google_compute_disk.os_disk_2.name
}
