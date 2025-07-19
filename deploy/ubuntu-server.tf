# ubuntu-server.tf

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
# You can change these default values or override them.
variable "gcp_project_ubuntu" {
  description = "The GCP project ID to deploy to."
  default     = "parsec-ws-deploy" # <-- CHANGE THIS to your project ID
}

variable "gcp_zone_ubuntu" {
  description = "The GCP zone to deploy to."
  default     = "us-east1-c" # T4 GPUs are widely available here. Check for availability in your region.
}

variable "instance_name_ubuntu" {
  description = "Name for the Ubuntu server VM."
  default     = "ubuntu-server"
}

# Explicitly set the billing account to ensure the project is recognized as billable.
variable "gcp_billing_account_ubuntu" {
  description = "The GCP billing account ID to use."
  default     = "01FD32-9F0EF2-099DD7"
}

provider "google" {
  alias           = "ubuntu"
  project         = var.gcp_project_ubuntu
  billing_project = var.gcp_billing_account_ubuntu
}

# Define the Compute Engine instance for Ubuntu server
resource "google_compute_instance" "ubuntu_server" {
  provider     = google.ubuntu
  project      = var.gcp_project_ubuntu
  zone         = var.gcp_zone_ubuntu
  name         = var.instance_name_ubuntu
  machine_type = "n1-standard-8" # 8 vCPUs, 30 GB RAM. Adjust as needed.
  tags         = ["ubuntu-server"]

  # Define the boot disk with Ubuntu 22.04 LTS (latest LTS)
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20 # Small boot disk size in GB
      type  = "pd-ssd"
    }
  }

  # First persistent disk for RAID storage (using Hyperdisk Balanced)
  attached_disk {
    source      = google_compute_disk.storage_disk_1.id
    device_name = "storage-disk-1"
  }

  # Second persistent disk for RAID storage (using Hyperdisk Balanced)
  attached_disk {
    source      = google_compute_disk.storage_disk_2.id
    device_name = "storage-disk-2"
  }

  # Add a small scratch disk (Local SSD)
  scratch_disk {
    interface = "NVME"
  }

  # Attach the NVIDIA T4 GPU with the vWS (GRID) license
  guest_accelerator {
    type  = "nvidia-tesla-t4-vws" # This specific type enables the virtual workstation license
    count = 1
  }

  # This setting is required for vWS GPUs
  scheduling {
    on_host_maintenance = "TERMINATE"
  }

  # Define the network interface and allow SSH access
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  # Pass the startup script to the instance.
  # This script will run on the first boot to configure the RAID array
  metadata = {
    startup-script = file("../scripts/ubuntu-startup.sh")
  }

  # Allow the instance to be deleted even if disks are attached
  allow_stopping_for_update = true
}

# Create the first persistent disk for RAID storage (Hyperdisk Balanced)
resource "google_compute_disk" "storage_disk_1" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-storage-disk-1"
  type     = "hyperdisk-balanced" # Using Hyperdisk Balanced for better performance
  size     = 500                  # Size in GB - adjust as needed

  # Hyperdisk specific settings
  provisioned_iops = 3000 # Adjust IOPS as needed
}

# Create the second persistent disk for RAID storage (Hyperdisk Balanced)
resource "google_compute_disk" "storage_disk_2" {
  provider = google.ubuntu
  project  = var.gcp_project_ubuntu
  zone     = var.gcp_zone_ubuntu
  name     = "${var.instance_name_ubuntu}-storage-disk-2"
  type     = "hyperdisk-balanced" # Using Hyperdisk Balanced for better performance
  size     = 500                  # Size in GB - adjust as needed

  # Hyperdisk specific settings
  provisioned_iops = 3000 # Adjust IOPS as needed
}

# Firewall rule to allow SSH from specific IP address.
# For better security, you can restrict the source_ranges to your own IP.
resource "google_compute_firewall" "allow_ssh_ubuntu" {
  provider = google.ubuntu
  name     = "allow-ubuntu-ssh"
  network  = "default"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["ubuntu-server"]
  source_ranges = ["50.47.212.98/32"]
}

# Output the external IP of the instance after it's created
output "ubuntu_instance_ip" {
  value = google_compute_instance.ubuntu_server.network_interface[0].access_config[0].nat_ip
}

# Output the disk names for reference
output "storage_disk_1_name" {
  value = google_compute_disk.storage_disk_1.name
}

output "storage_disk_2_name" {
  value = google_compute_disk.storage_disk_2.name
}
