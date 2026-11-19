resource "google_dataform_repository" "this" {
  provider = google-beta

  name            = "sales-pipeline"
  region          = var.region
  display_name    = "Sales analytics pipeline"
  service_account = google_service_account.dataform.email
  labels          = local.labels

  dynamic "git_remote_settings" {
    for_each = local.git_enabled ? [1] : []

    content {
      url                                 = var.git_remote_url
      default_branch                      = var.git_default_branch
      authentication_token_secret_version = "${google_secret_manager_secret.git_token[0].id}/versions/latest"
    }
  }

  workspace_compilation_overrides {
    default_database = var.project_id
  }

  depends_on = [google_project_service.this]
}

# Compiles the Git branch into a release on a schedule.
resource "google_dataform_repository_release_config" "this" {
  provider = google-beta
  count    = local.git_enabled ? 1 : 0

  project       = var.project_id
  region        = var.region
  repository    = google_dataform_repository.this.name
  name          = "${var.environment}-release"
  git_commitish = var.git_default_branch
  cron_schedule = var.compile_cron
  time_zone     = var.time_zone

  code_compilation_config {
    default_database = var.project_id
    default_location = var.data_location
    assertion_schema = "dataform_assertions"

    vars = {
      environment = var.environment
    }
  }
}

# Runs the whole workflow (all actions and their dependencies) every day.
resource "google_dataform_repository_workflow_config" "daily" {
  provider = google-beta
  count    = local.git_enabled ? 1 : 0

  project        = var.project_id
  region         = var.region
  repository     = google_dataform_repository.this.name
  name           = "${var.environment}-daily"
  release_config = google_dataform_repository_release_config.this[0].id
  cron_schedule  = var.run_cron
  time_zone      = var.time_zone

  invocation_config {
    transitive_dependencies_included         = true
    transitive_dependents_included           = false
    fully_refresh_incremental_tables_enabled = false
    service_account                          = google_service_account.dataform.email
  }
}
