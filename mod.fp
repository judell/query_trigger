mod "enrich_ip_address_cited_in_jira" {
  title = "Enrich IP address cited in Jira issue"
  description = "When a Jira issue cites an IP address, correlate with VPC and add results as a comment."
  require {
    mod "github.com/turbot/flowpipe-mod-jira" {
      version = "*"
    }
  }
}