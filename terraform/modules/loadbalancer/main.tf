resource "aws_lb" "this" {
  name               = "app-alb"
  load_balancer_type = "application"

  subnets = var.subnet_ids

  security_groups = [var.sg_id]
}