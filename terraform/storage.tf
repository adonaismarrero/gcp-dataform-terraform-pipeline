resource "google_storage_bucket" "raw" {
  name                        = local.raw_bucket
  location                    = var.data_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = !local.is_prod
  labels                      = local.labels

  versioning {
    enabled = true
  }

  # Keep the last 3 versions of every file.
  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.this]
}

# One folder per table: <bucket>/<table>/*.csv
resource "google_storage_bucket_object" "sample" {
  for_each = var.upload_sample_data ? local.raw_tables : {}

  name   = "${each.key}/${each.key}.csv"
  bucket = google_storage_bucket.raw.name
  source = "${path.module}/../data/raw/${each.key}.csv"
}
