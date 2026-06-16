import os
from mcp.server.fastmcp import FastMCP
from google.cloud import bigquery
from github import Github

# Initialize FastMCP Server
mcp = FastMCP("gcp-proxy-agent")

@mcp.tool()
def inspect_bq_discrepancy(query: str, project_id: str) -> str:
    """Queries BigQuery for sample data based on user input to investigate discrepancies.
    
    Args:
        query: The read-only SQL query to execute.
        project_id: The GCP project ID containing the BigQuery dataset.
    """
    client = bigquery.Client(project=project_id)
    try:
        query_job = client.query(query)
        results = query_job.result()
        rows = [dict(row) for row in results]
        return f"Query executed successfully. Returned {len(rows)} rows.\nData: {rows}"
    except Exception as e:
        return f"Error executing BigQuery query: {str(e)}"

@mcp.tool()
def push_hotfix_to_github(repo_name: str, file_path: str, new_content: str, commit_message: str, tag_version: str) -> str:
    """Uses the GitHub API to update a file, commit the change, and create a semantic version tag.
    
    Args:
        repo_name: Repository in the format 'owner/repo'.
        file_path: Path to the file to update.
        new_content: The new content of the file.
        commit_message: The commit message.
        tag_version: The semantic version tag to create (e.g., 'v1.0.1').
    """
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        return "Error: GITHUB_TOKEN environment variable is not set."
        
    g = Github(token)
    try:
        repo = g.get_repo(repo_name)
        
        # Get the file's current SHA
        contents = repo.get_contents(file_path)
        
        # Update the file
        repo.update_file(contents.path, commit_message, new_content, contents.sha)
        
        # Get the latest commit SHA on the default branch
        branch = repo.get_branch(repo.default_branch)
        
        # Create a tag
        repo.create_git_tag(tag_version, commit_message, branch.commit.sha, "commit")
        repo.create_git_ref(f"refs/tags/{tag_version}", branch.commit.sha)
        
        return f"Successfully updated {file_path}, committed, and tagged as {tag_version}."
    except Exception as e:
        return f"Error interacting with GitHub API: {str(e)}"

if __name__ == "__main__":
    # Start the FastMCP server with SSE (Server-Sent Events) transport for HTTP hosting
    # NOTE: We bind to 0.0.0.0 and the PORT environment variable for Cloud Run.
    port = int(os.environ.get("PORT", 8080))
    mcp.run(transport='sse', host='0.0.0.0', port=port)
