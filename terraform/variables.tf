variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "mcp_image" {
  description = "The Docker image for the MCP server in Artifact Registry"
  type        = string
}

variable "github_token_secret_id" {
  description = "The Secret Manager ID containing the GitHub PAT"
  type        = string
}

variable "agent_studio_sa" {
  description = "The Service Account email used by Vertex AI Agent Builder"
  type        = string
}
