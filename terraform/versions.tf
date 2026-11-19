terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # Remote state in GCS. Partial configuration: the bucket and prefix are passed
  # at init time, e.g.  terraform init -backend-config=environments/dev.gcs.tfbackend
  backend "gcs" {}
}
