trigger "query" "new_aws_iam_access_key" {
  description       = "Fire when a new key appears, call email-notifying pipeline"
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  #schedule          = "* * * * *"    # every minute
  schedule          = "5m"
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



