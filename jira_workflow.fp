trigger "query" "jira_issue" {
  description = "Fire when a Jira issue cites an IP address"
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  schedule = "5m"
  sql = <<EOQ
      with ip_info as (
        select 
          vpc_id, 
          host(cidr_block) as host
        from aws_vpc
      ),
      jira_matched as (
        select
          id,
          key,
          (regexp_matches(summary,'\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}'))[1] as matched_host
        from
          jira_issue
      )
        select distinct
          j.id, j.key, i.host, i.vpc_id,s.account_id,
          s.region
        from
          aws_vpc_security_group s
        join
          ip_info i on s.vpc_id = i.vpc_id
        join
          jira_matched j on i.host = j.matched_host
  EOQ

  capture "insert" {
    pipeline = pipeline.enrich_jira_with_ip_info

    args = {
      rows = self.inserted_rows
    }
  }
}

pipeline "enrich_jira_with_ip_info" {
  description = "When a Jira issue cites an IP address, correlate with VPC and add results as a comment."

  param "rows" {
    type = "list"
  }

  step "pipeline" "jira_add_comments" {
    for_each = param.rows
    pipeline = jira.pipeline.add_comment
    args = {
      issue_id = each.value.id,
      comment_text = jsonencode(each.value)
    }
  }
 
}