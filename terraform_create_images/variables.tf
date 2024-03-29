// --- RELEASE INFORMATION --- //

variable "config_script_name" {
  description = "Open Targets Genetics script name, not related to any configuration parameter."
  type        = string
  default     = "gos"
}

variable "config_release_name" {
  description = "Open Targets Genetics release name: used to identify created disks."
  type        = string
  default     = "release"
}

variable "config_branch" {
  description = "Branch of genetics-output-support from which to fetch SQL and other scripts."
  type        = string
  default     = "main"
}
variable "config_vm_elastic_search_version" {
  description = "Elastic search version to deploy"
  type        = string
  default     = "7.10.2"
}
variable "config_vm_clickhouse_version" {
  description = "Clickhouse (Docker) version to deploy"
  type        = string
  default     = "22.3.12.19-alpine"
}
variable "config_gcp_default_region" {
  description = "Default region when not specified in the module"
  type        = string
  default     = "europe-west1"
}

variable "config_gcp_default_zone" {
  description = "Default zone when not specified in the module"
  type        = string
  default     = "europe-west1-d"
}

variable "config_project_id" {
  description = "Default project to use when not specified in the module"
  type        = string
  default     = "open-targets-genetics-dev"
}

// --- ETL info --- //
variable "config_gs_etl" {
  description = "Output of the ETL [root]. Eg. gs://open-targets-genetics-data-releases/21.04/output"
  type        = string
  default     = "gs://genetics-portal-dev-data/22.09.0/outputs"
}

// --- POS VM Configuration --- //
variable "config_vm_pos_boot_image" {
  description = "Boot image configuration for POS VM"
  type        = string
  default     = "debian-10"
}

variable "config_vm_pos_boot_disk_size" {
  description = "POS VM boot disk size, default '500GB'"
  type        = string
  default     = 500
}

variable "config_vm_pos_machine_type" {
  description = "Machine type for POS vm"
  type        = string
  # 16 CPU, 128GB ram
  default = "e2-highmem-16"
}
