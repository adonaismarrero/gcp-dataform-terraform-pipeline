resource "google_bigquery_dataset" "layer" {
  for_each = local.datasets

  dataset_id                 = each.key
  location                   = var.data_location
  description                = each.value
  delete_contents_on_destroy = !local.is_prod
  labels                     = merge(local.labels, { layer = each.key })

  depends_on = [google_project_service.this]
}

# Raw layer: external tables reading the CSV files straight from GCS.
resource "google_bigquery_table" "raw" {
  for_each = local.raw_tables

  dataset_id          = google_bigquery_dataset.layer["raw"].dataset_id
  table_id            = each.key
  description         = "Raw ${each.key} files from gs://${google_storage_bucket.raw.name}/${each.key}/"
  deletion_protection = local.is_prod
  labels              = merge(local.labels, { layer = "raw" })

  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.raw.name}/${each.key}/*.csv"]
    schema        = jsonencode([for column in each.value : { name = column, type = "STRING", mode = "NULLABLE" }])

    csv_options {
      quote             = "\""
      skip_leading_rows = 1
    }
  }
}
