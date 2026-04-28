output "vpc_cidr" {
  value       = local.vpc_cidr
  description = "CIDR de la VPC desplegada"
}

output "nlb_dns_name" {
  value       = aws_lb.nlb.dns_name
  description = "DNS del NLB (TCP NodePorts). Alias interno AWS."
}

output "public_endpoint_hint" {
  value       = "Usa http(s)://${aws_lb.nlb.dns_name}:<nodeport> segun servicio (Grafana ${var.grafana_nodeport}, API segun manifest)."
  description = "Referencia rapida"
}

output "k3s_server_public_ip" {
  value       = aws_instance.k3s[0].public_ip
  description = "IP publica del nodo k3s server (SSH / kubeconfig)"
}

output "k3s_server_private_ip" {
  value       = aws_instance.k3s[0].private_ip
  description = "IP privada del server (agent -> apiserver)"
}

output "k3s_agent_public_ip" {
  value       = aws_instance.k3s[1].public_ip
  description = "IP publica del nodo k3s agent"
}

output "k3s_agent_private_ip" {
  value       = aws_instance.k3s[1].private_ip
  description = "IP privada del agent"
}

output "ssh_user" {
  value = "ubuntu"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.api.repository_url
  description = "URL para docker push de la API de ejemplo"
}

output "rds_primary_endpoint" {
  value       = aws_db_instance.primary.address
  description = "Endpoint MySQL primario (escritura)"
}

output "rds_replica_endpoint" {
  value       = aws_db_instance.replica.address
  description = "Endpoint MySQL replica (solo lectura)"
}

output "rds_master_username" {
  value       = aws_db_instance.primary.username
  description = "Usuario maestro RDS"
}

output "rds_master_password" {
  value       = random_password.db_master.result
  sensitive   = true
  description = "Password maestro (se crea secret en K8s en CI)"
}

output "route53_fqdn" {
  value       = length(aws_route53_record.nlb_alias) > 0 ? aws_route53_record.nlb_alias[0].fqdn : ""
  description = "FQDN si se configuro Route53"
}
