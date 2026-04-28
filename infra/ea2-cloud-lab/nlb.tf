resource "aws_lb" "nlb" {
  name                       = "ea2-${random_id.suffix.hex}"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = aws_subnet.public[*].id
  enable_deletion_protection = false

  tags = {
    Name = "ea2-cloud-lab-nlb"
  }
}

resource "aws_lb_target_group" "tcp" {
  for_each = { for p in local.forward_ports : tostring(p) => p }

  name        = substr("tg${random_id.suffix.hex}-${each.key}", 0, 32)
  port        = each.value
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    port                = each.value
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "ea2-tg-${each.key}"
  }
}

resource "aws_lb_listener" "tcp" {
  for_each = { for p in local.forward_ports : tostring(p) => p }

  load_balancer_arn = aws_lb.nlb.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp[each.key].arn
  }
}

resource "aws_lb_target_group_attachment" "tcp" {
  for_each = {
    for combo in flatten([
      for p in local.forward_ports : [
        for idx in [0, 1] : {
          key  = "${p}-${idx}"
          port = p
          idx  = idx
        }
      ]
    ]) : combo.key => combo
  }

  target_group_arn = aws_lb_target_group.tcp[tostring(each.value.port)].arn
  target_id        = aws_instance.k3s[each.value.idx].id
  port             = each.value.port
}
