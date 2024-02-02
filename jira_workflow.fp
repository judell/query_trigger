trigger "query" "jira_issue" {
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  schedule = "* * * * *"
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
          j.id,
          j.key,
          i.host,
          i.vpc_id,
          s.account_id,
          s.region
        from
          aws_vpc_security_group s
        join
          ip_info i on s.vpc_id = i.vpc_id
        join
          jira_matched j on i.host = j.matched_host
  EOQ

  capture "insert" {
    pipeline = pipeline.add_comments

    args = {
      rows = self.inserted_rows
    }
  }

}


pipeline "query" {

  step "query" "query_jira" {
    connection_string = "postgres://steampipe@localhost:9193/steampipe"
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
            j.id,
            j.key,
            i.host,
            i.vpc_id,
            s.account_id,
            s.region
          from
            aws_vpc_security_group s
          join
            ip_info i on s.vpc_id = i.vpc_id
          join
            jira_matched j on i.host = j.matched_host
      EOQ
  }

  output "out" {
    value = step.query.query_jira.rows
  }

}

pipeline "add_comments" {

  param "rows" {
    type = "string"
  }

  output "rows" {
    value = param.rows
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