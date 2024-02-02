trigger "query" "new_aws_iam_access_key" {
  connection_string = "postgres://steampipe@localhost:9193/steampipe"
  schedule = "* * * * *"
  primary_key = "message"
  sql = <<EOQ
    SELECT json_agg(t)::text AS message
    FROM (
      SELECT user_name, access_key_id
      FROM aws_iam_access_key
      WHERE create_date > NOW() - INTERVAL '1 day'
    ) t;  
  EOQ

  capture "insert" {
    pipeline = pipeline.email

    args = {
      message = self.inserted_rows[0].message
    }
  }

}

pipeline "email" {

  param "message" {
    type = string
  }

  output "test" {
    value = env("FLOWPIPE_EMAIL_APP_PW")
  }

  step "email" "send_it" {
      to                = ["judell@turbot.com"]
      from              = "judell@turbot.com"
      smtp_username     = "judell@turbot.com"
      #smtp_password     = "gsrvoiaeojgklpht"
      smtp_password     = env("FLOWPIPE_EMAIL_APP_PW")
      host              = "smtp.gmail.com"
      port              = 587
      subject           = "new access key"
      content_type      = "text/html"
      body              = <<EOT
        "New access key ${param.message}"
      EOT
  }

}

