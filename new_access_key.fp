trigger "query" "new_aws_iam_access_key" {
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  schedule          = "daily"
  primary_key       = "message"
  sql               = <<EOQ
    select json_agg(t)::text as message
    from (
      select user_name, access_key_id
      from aws_iam_access_key
      where create_date > now() - interval '1 day'
    ) t;  
  EOQ

  capture "insert" {
    pipeline = pipeline.email

    args = {
      subject       = "New access key(s) detected"
      message       = self.inserted_rows[0].message
      smtp_username = "judell@turbot.com"
      smtp_host     = "smtp.gmail.com"
    }
  }
}

pipeline "email" {
  param "subject"       { type = string }
  param "message"       { type = string }
  param "smtp_username" { type = string }
  param "smtp_host"     { type = string }

  step "email" "send_it" {
    to            = ["${param.smtp_username}"]
    from          = "${param.smtp_username}"
    smtp_username = "${param.smtp_username}"
    smtp_password = env("FLOWPIPE_EMAIL_APP_PW")
    host          = "${param.smtp_host}"
    port          = 587
    subject       = "${param.subject}"
    content_type  = "text/html"
    body          = "New access key ${param.message}"
  }
}

