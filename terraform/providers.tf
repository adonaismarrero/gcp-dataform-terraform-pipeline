provider "google" {
  project = var.project_id
  region  = var.region
}

# Dataform resources are still published in the beta provider.
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
