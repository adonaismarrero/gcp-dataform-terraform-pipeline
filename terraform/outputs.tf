output "raw_bucket" {
  description = "Landing bucket for the raw CSV files."
  value       = google_storage_bucket.raw.url
}

output "datasets" {
  description = "BigQuery datasets created for each layer."
  value       = { for name, ds in google_bigquery_dataset.layer : name => ds.id }
}

output "dataform_repository" {
  description = "Dataform repository resource ID."
  value       = google_dataform_repository.this.id
}

output "dataform_service_account" {
  description = "Service account that runs the workflows."
  value       = google_service_account.dataform.email
}
