terraform {
  backend "gcs" {
    # Configure before terraform init:
    #   bucket = "YOUR_PROJECT-terraform-state"
    #   prefix = "gcp-engineer-agent-mcp/ENV"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Service Account for the MCP Server
resource "google_service_account" "mcp_server_sa" {
  account_id   = "mcp-proxy-agent-sa"
  display_name = "MCP Proxy Agent Service Account"
}

# Grant BigQuery Data Viewer to the Service Account
resource "google_project_iam_member" "bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.mcp_server_sa.email}"
}

# Allow Service Account to access GITHUB_TOKEN from Secret Manager
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = var.github_token_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.mcp_server_sa.email}"
}

# 2. Cloud Run Service Deployment
resource "google_cloud_run_v2_service" "mcp_server" {
  name     = "mcp-proxy-agent"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.mcp_server_sa.email
    
    containers {
      image = var.mcp_image # e.g., us-central1-docker.pkg.dev/...

      env {
        name  = "PORT"
        value = "8080"
      }

      # Inject GITHUB_TOKEN from Secret Manager
      env {
        name = "GITHUB_TOKEN"
        value_source {
          secret_key_ref {
            secret  = var.github_token_secret_id
            version = "latest"
          }
        }
      }
    }
  }
}

# 3. Allow Gemini Agent Studio to invoke the Cloud Run service
# Replace var.agent_studio_sa with the Vertex AI Agent Builder Service Agent
resource "google_cloud_run_v2_service_iam_member" "agent_invoker" {
  name     = google_cloud_run_v2_service.mcp_server.name
  location = google_cloud_run_v2_service.mcp_server.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.agent_studio_sa}"
}
