# Test configuration for individual modules
# Use: terraform plan -var-file="test.tfvars"

aws_region   = "us-east-1"
project_name = "defectdojo-mvp-test"

# Basic settings for testing
web_allowed_cidrs = ["0.0.0.0/0"] # Restringir depois
instance_type     = "t3.small"
db_instance_class = "db.t3.micro"

# MVP settings
enable_redis     = false
min_size         = 1
max_size         = 2
desired_capacity = 1

# Database password (use AWS Systems Manager Parameter Store na produção)
db_password = "MySecurePassword123!"

# Django Security Keys (CHANGE FOR PRODUCTION!)
django_secret_key = "hhZCp@D28z!n@NED*yB!ROMt+WzsY*iq-MVP-TEST-ONLY"
django_aes_key    = "&91a*agLqesc*0DJ+2*bAbsUZfR*4nLw"
