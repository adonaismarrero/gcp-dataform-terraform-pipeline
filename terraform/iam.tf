# Service account that executes the Dataform workflows (least privilege).
resource "google_service_account" "dataform" {
  account_id   = "dataform-runner"
  display_name = "Dataform workflow runner (${var.environment})"
}

resource "google_project_iam_member" "dataform_runner" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.dataform.email}"
}

# The raw layer is made of external tables: the runner must read the bucket.
resource "google_storage_bucket_iam_member" "dataform_raw_reader" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.dataform.email}"
}

locals {
  dataform_service_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# The Dataform service agent impersonates the runner when a workflow starts.
resource "google_service_account_iam_member" "dataform_agent_token_creator" {
  service_account_id = google_service_account.dataform.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.dataform_service_agent

  depends_on = [google_dataform_repository.this]
}

# Git token for the Dataform repository. Terraform creates the secret only;
# the value is added outside Terraform so it never ends up in the state:
#   echo -n "<token>" | gcloud secrets versions add dataform-git-token --data-file=-
resource "google_secret_manager_secret" "git_token" {
  count = local.git_enabled ? 1 : 0

  secret_id = "dataform-git-token"
  labels    = local.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.this]
}

resource "google_secret_manager_secret_iam_member" "dataform_agent_git_token" {
  count = local.git_enabled ? 1 : 0

  secret_id = google_secret_manager_secret.git_token[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = local.dataform_service_agent

  depends_on = [google_dataform_repository.this]
}
