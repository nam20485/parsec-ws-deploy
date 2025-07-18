# main.tf

# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

# # enable the Compute Engine API
# resource "google_project_service" "compute" {
#   project = var.gcp_project
#   service = "compute.googleapis.com"
# }

# # enable billing with existing billing account named "name"
# resource "google_billing_account" "billing" {
#   billing_account_name = "name" 
#   open                 = true
# }
# # create project
# resource "google_project" "project" {
#   name       = var.gcp_project
#   project_id = var.gcp_project
# }

# Define variables for your project and region.
# You can change these default values or override them.
variable "gcp_project" {
  description = "The GCP project ID to deploy to."
  default     = "parsec-ws-deploy" # <-- CHANGE THIS to your project ID
}

variable "gcp_zone" {
  description = "The GCP zone to deploy to."
  default     = "us-west1-a" # T4 GPUs are widely available here. Check for availability in your region.
}

variable "instance_name" {
  description = "Name for the Parsec workstation VM."
  default     = "parsec-workstation"
}

# Explicitly set the billing account to ensure the project is recognized as billable.
variable "gcp_billing_account" {
  description = "The GCP billing account ID to use."
  default     = "01FD32-9F0EF2-099DD7"
}

provider "google" {
  project         = var.gcp_project
  billing_project = var.gcp_billing_account
}

# Define the Compute Engine instance
resource "google_compute_instance" "parsec_workstation" {
  project      = var.gcp_project
  zone         = var.gcp_zone
  name         = var.instance_name
  machine_type = "n1-standard-8" # 8 vCPUs, 30 GB RAM. Adjust as needed.
  tags         = ["parsec-rdp"]

  # Define the boot disk with Windows Server 2022
  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size  = 100 # Boot disk size in GB
      type  = "pd-ssd"
    }
  }

  # Attach two Local SSDs for the RAID 0 array.
  # Each Local SSD is 375 GB.
  scratch_disk {
    interface = "NVME"
  }
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

  # Define the network interface and allow RDP access
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  # Pass the startup script to the instance.
  # This script will run on the first boot to configure the RAID array and install Parsec.
  metadata = {
    windows-startup-script-ps1 = file("../scripts/startup.ps1")
  }

  # Allow the instance to be deleted even if disks are attached
  allow_stopping_for_update = true
}

# Firewall rule to allow RDP from any IP address.
# For better security, you can restrict the source_ranges to your own IP.
resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-parsec-rdp"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  target_tags   = ["parsec-rdp"]
  source_ranges = ["50.47.212.98/32"]
  }

# Output the external IP of the instance after it's created
output "instance_ip" {
  value = google_compute_instance.parsec_workstation.network_interface[0].access_config[0].nat_ip
}
