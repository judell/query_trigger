trigger "query" "new_aws_iam_access_key" {
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
#  schedule          = "5m"           # every 5 minutes
 schedule          = "* * * * *"    # every minute
  primary_key       = "message"
  sql               = <<EOQ
    select jsonb_pretty(jsonb_agg(t))::text as message
    from (
      select user_name, access_key_id
      from aws_iam_access_key
      where create_date > now() - interval '1 day'
    ) t;  
  EOQ

  capture "insert" {
    pipeline = pipeline.email

    args = {
      smtp_username = "judell@turbot.com"
      smtp_host     = "smtp.gmail.com"
      subject       = "New access key(s) detected"
      message       = "<pre>${self.inserted_rows[0].message}</pre>"
    }
  }
}



