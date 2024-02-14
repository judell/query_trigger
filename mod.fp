mod "local" {
  description = "When a Jira issue cites an IP address, correlate with VPC and add results as a comment."
  require {
    mod "github.com/turbot/flowpipe-mod-jira" {
      version = "*"
    }
  }
}