resource "aws_db_subnet_group" "this" {
  name = "main-db-subnet"

  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "this" {
  allocated_storage = 20

  engine         = "postgres"
  instance_class  = "db.t3.micro"

  db_name  = var.db_name
  username = "dbadmin"
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.this.name

  publicly_accessible = false
  skip_final_snapshot  = true

#Multi A-Z enabled
  multi_az = true
}
