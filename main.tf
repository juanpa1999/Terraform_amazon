terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAXWHDLRER2NOWHZ4B"
  secret_key = "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"
}

# 🔹 Crear un S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "pablodevops-bucket-terraform"
  acl    = "private"

  tags = {
    Name = "pablodevops-bucket"
  }
}

# 🔹 Crear un rol de IAM para EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# 🔹 Adjuntar política de permisos al rol (para S3)
resource "aws_iam_policy" "s3_policy" {
  name        = "EC2S3AccessPolicy"
  description = "Permite acceso de escritura a S3 desde la EC2"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::pablodevops-bucket-terraform",
        "arn:aws:s3:::pablodevops-bucket-terraform/*"
      ]
    }
  ]
}
EOF
}

# 🔹 Adjuntar la política al rol
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# 🔹 Crear una instancia de IAM para asociar con EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_s3_role.name
}

# 🔹 Instancia EC2 con acceso a S3
resource "aws_instance" "app_server" {
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = "pablodevops key"
  vpc_security_group_ids = ["sg-0a4c10ba2054b6f05"]  # Reemplaza con el SG existente
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "Pablo devops ec2"
  }
}
