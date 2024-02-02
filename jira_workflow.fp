/*
trigger "query" "jira_issue" {
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  schedule = "* * * * *"
  primary_key = "message"
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
    select  json_agg(t)::text as message from (
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
    ) t
  EOQ

  capture "insert" {
    pipeline = pipeline.jira

    args = {
      message = self.inserted_rows[0].message
    }
  }

}
*/

pipeline "jira_query" {

  step "query" "query_jira_vpc" {
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

  step "pipeline" "jira_add_comments" {
    for_each = step.query.query_jira_vpc.rows
    pipeline = pipeline.add_comment
    args = {
      id = each.value.id,
      message = jsonencode(each.value)
    }
  }

}


pipeline "add_comment" {

  param "id" {
    type = string
  }
  
  param "message" {
    type = string
  }

  step "pipeline" "add_the_comment" {
    pipeline = jira.pipeline.add_comment
    args = {
      issue_id = param.id
      comment_text = param.message
    }
  }
  
}