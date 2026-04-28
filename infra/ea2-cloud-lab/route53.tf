resource "aws_route53_record" "nlb_alias" {
  count = var.route53_zone_id != "" && var.dns_record_name != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.dns_record_name
  type    = "A"

  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = true
  }
}
