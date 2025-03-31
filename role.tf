provider "aws" {
  region = "us-west-2"  # 使用 us-west-2 区域
}

variable "bucket_name" {
  default = "vic-info-lab"
}

resource "aws_iam_user" "s3_user" {
  name = "viclab-s3-user"
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "viclab-s3-policy"
  user = aws_iam_user.s3_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:Get*",
          "s3:Put*",
          "s3:List*"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

output "s3_access_key_id" {
  value = aws_iam_access_key.s3_user_key.id
}

output "s3_secret_access_key" {
  value     = aws_iam_access_key.s3_user_key.secret
  sensitive = true
}