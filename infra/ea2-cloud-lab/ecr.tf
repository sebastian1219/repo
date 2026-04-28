resource "aws_ecr_repository" "api" {
  name                 = "ea2-cloud-lab-api-${random_id.suffix.hex}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ea2-api"
  }
}
