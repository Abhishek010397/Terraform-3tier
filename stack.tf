resource "aws_vpc" "three-tier-stack" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Three-Tier-Stack"

  }
}

resource "aws_subnet" "three-tier-pub-sub01" {
  vpc_id     = aws_vpc.three-tier-stack.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "Three-Tier-Stack"
  }
}

resource "aws_subnet" "three-tier-pub-sub02" {
  vpc_id     = aws_vpc.three-tier-stack.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "Three-Tier-Stack"
  }
}

resource "aws_internet_gateway" "three-tier-internet-gateway" {
  vpc_id = aws_vpc.three-tier-stack.id

  tags = {
    Name = "Three-Tier-Stack"
  }
}

#Route-Table
resource "aws_route_table" "three-tier-route-public-table" {
  vpc_id = aws_vpc.three-tier-stack.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-internet-gateway.id
  }
  tags = {
    Name = "Three-Tier-Stack"
  }
}

#Route-Table-Association with 2 Public Subnets In Two AZs
resource "aws_route_table_association" "three-tier-route-association01" {
  subnet_id      = aws_subnet.three-tier-pub-sub01.id
  route_table_id = aws_route_table.three-tier-route-public-table.id
}

resource "aws_route_table_association" "three-tier-route-association02" {
  subnet_id      = aws_subnet.three-tier-pub-sub02.id
  route_table_id = aws_route_table.three-tier-route-public-table.id
}


resource "aws_security_group" "three-tier-security-group-ec2" {
  name        = "EC2aConnections"
  description = "Allow inbound Traffic"
  vpc_id      = aws_vpc.three-tier-stack.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Three-Tier-Stack"
  }
}

resource "aws_instance" "EC2Webserver1" {
  ami                    = "ami-0b5eea76982371e91"
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.three-tier-security-group-ec2.id]
  subnet_id              = aws_subnet.three-tier-pub-sub01.id
  key_name               = "cvonetappkeys"
  availability_zone      = "us-east-1a"
  tenancy                = "default"
  monitoring             = true
  tags = {
    Name = "EC2Webserver1"
  }
}

resource "aws_instance" "EC2Webserver2" {
  ami                    = "ami-0b5eea76982371e91"
  instance_type          = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.three-tier-security-group-ec2.id]
  subnet_id              = aws_subnet.three-tier-pub-sub02.id
  key_name               = "cvonetappkeys"
  availability_zone      = "us-east-1b"
  tenancy                = "default"
  monitoring             = true
  tags = {
    Name = "EC2Webserver2"
  }
}

resource "aws_security_group" "three-tier-security-group-db" {
  name        = "DBConnections"
  description = "Allow inbound Traffic"
  vpc_id      = aws_vpc.three-tier-stack.id

  ingress {
    description      = "MYSQL/AURORA"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  ingress {
    description      = "MYSQL/AURORA"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["10.0.2.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Three-Tier-Stack"
  }
}


resource "aws_db_subnet_group" "three-tier-subnet-group" {
  name       = "three-tier-subnet-group"
  subnet_ids = [aws_subnet.three-tier-pub-sub01.id, aws_subnet.three-tier-pub-sub02.id]

  tags = {
    Name = "Three-Tier-Stack"
  }
}

resource "aws_db_instance" "three-tier-db-stack" {
  allocated_storage    = 20
  publicly_accessible  = false
  db_name              = "stock_db"
  network_type         = "IPV4"
  port                 = 3306
  engine               = "mysql"
  availability_zone    = "us-east-1a"
  engine_version       = "8.0.28"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin1234"
  skip_final_snapshot  = true
  storage_type         = "gp2"
  max_allocated_storage = 1000
  db_subnet_group_name  = aws_db_subnet_group.three-tier-subnet-group.name
  vpc_security_group_ids = [aws_security_group.three-tier-security-group-db.id]

}

resource "aws_security_group" "three-tier-security-group-alb" {
  name        = "LBConnections"
  description = "Allow inbound Traffic"
  vpc_id      = aws_vpc.three-tier-stack.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Three-Tier-Stack"
  }
}

resource "aws_lb_target_group" "three-tier-tg" {
  name        = "three-tier-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.three-tier-stack.id
}

resource "aws_lb" "Three-Tier-ALB" {
  name               = "Three-Tier-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.three-tier-security-group-alb.id]
  subnets            = [aws_subnet.three-tier-pub-sub01.id, aws_subnet.three-tier-pub-sub02.id]

  enable_deletion_protection = true

  tags = {
    Environment = "Three-Tier-Stack"
  }
}

resource "aws_lb_listener" "three-tier-stack-listener" {
  load_balancer_arn = aws_lb.Three-Tier-ALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.three-tier-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "EC2WebServer1Target" {
  target_group_arn = aws_lb_target_group.three-tier-tg.arn
  target_id        = aws_instance.EC2Webserver1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "EC2WebServer2Target" {
  target_group_arn = aws_lb_target_group.three-tier-tg.arn
  target_id        = aws_instance.EC2Webserver2.id
  port             = 8080
}