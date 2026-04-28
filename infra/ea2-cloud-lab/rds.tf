resource "aws_db_subnet_group" "main" {
  name       = "ea2-dbsub-${random_id.suffix.hex}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "ea2-cloud-lab-db"
  }
}

resource "aws_db_instance" "primary" {
  identifier                 = "ea2-mysql-${random_id.suffix.hex}"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  storage_type               = "gp2"
  db_name                    = "labdb"
  username                   = "labadmin"
  password                   = random_password.db_master.result
  skip_final_snapshot        = true
  vpc_security_group_ids     = [aws_security_group.rds.id]
  db_subnet_group_name       = aws_db_subnet_group.main.name
  backup_retention_period    = 1
  multi_az                   = false
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  tags = {
    Name = "ea2-mysql-primary"
    Role = "primary"
  }
}

resource "aws_db_instance" "replica" {
  identifier             = "ea2-mysql-${random_id.suffix.hex}-replica"
  replicate_source_db    = aws_db_instance.primary.identifier
  instance_class         = var.db_instance_class
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  tags = {
    Name = "ea2-mysql-replica"
    Role = "read-replica"
  }

  depends_on = [aws_db_instance.primary]
}
