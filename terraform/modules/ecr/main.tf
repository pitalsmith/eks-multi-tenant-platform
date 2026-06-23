resource "aws_ecr_repository" "backend" {
  name = var.repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}