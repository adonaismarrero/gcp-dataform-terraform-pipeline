variable "project_id" {
  description = "GCP project that hosts the pipeline. One project per environment is recommended."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Used for labels, resource names and safety settings."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "region" {
  description = "Region for regional resources (Dataform repository)."
  type        = string
  default     = "europe-west1"
}

variable "data_location" {
  description = "Location for BigQuery datasets and the raw bucket (multi-region or region)."
  type        = string
  default     = "EU"
}

variable "raw_bucket_name" {
  description = "Name of the raw landing bucket. Defaults to <project_id>-raw-<environment>."
  type        = string
  default     = null
}

variable "upload_sample_data" {
  description = "Upload the synthetic CSV files in data/raw to the landing bucket."
  type        = bool
  default     = true
}

variable "git_remote_url" {
  description = "HTTPS URL of the Git repository with the Dataform code. Empty = no Git link, no schedules."
  type        = string
  default     = ""
}

variable "git_default_branch" {
  description = "Branch that the scheduled releases compile."
  type        = string
  default     = "main"
}

variable "compile_cron" {
  description = "Cron for compiling a new release from the Git branch."
  type        = string
  default     = "0 5 * * *"
}

variable "run_cron" {
  description = "Cron for executing the full workflow."
  type        = string
  default     = "0 6 * * *"
}

variable "time_zone" {
  description = "Time zone for the schedules."
  type        = string
  default     = "Europe/Madrid"
}

variable "labels" {
  description = "Extra labels applied to every resource that supports them."
  type        = map(string)
  default     = {}
}
