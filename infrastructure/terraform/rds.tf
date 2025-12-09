resource "aws_db_subnet_group" "main" {
  name = "cs3-rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = merge(
    var.default_tags,
    { Name = "cs3-rds-subnet-group" }
  )
}

resource "aws_security_group" "rds_sg" {
  name        = "cs3-rds-sg"
  description = "Allow DB access from ECS"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.default_tags,
    { Name = "cs3-rds-sg" }
  )
}

resource "aws_db_instance" "employee_db" {
  identifier          = "cs3-employee-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = var.db_username
  password            = var.db_password
  db_name             = var.db_name
  publicly_accessible = false

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true

  tags = merge(
    var.default_tags,
    { Name = "cs3-employee-db" }
  )
}
