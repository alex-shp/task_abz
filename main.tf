# clarifying AWS provider and region
provider "aws" {
  region = "eu-west-1" # Регион, где будет создана инфраструктура
}

# creating VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16" # Диапазон IP адресов
  enable_dns_support   = true          # Поддержка DNS
  enable_dns_hostnames = true          # Хостнеймы для DNS
  tags = {
    Name = "MyVPC"
  }
}

# creating IG
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MyInternetGateway"
  }
}

# route table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "MainRouteTable"
  }
}

# tiyng кщute table to subnet
resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# creating public subnet-1
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
  tags = {
    Name = "PublicSubnet1"
  }
}

# creating public subnet-2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1b"
  tags = {
    Name = "PublicSubnet2"
  }
}

# creating private subnet-1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "PrivateSubnet1"
  }
}

# creating privat subnet-2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "PrivateSubnet2"
  }
}

# Creating Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "NAT EIP"
  }
}

# creating NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT Gateway"
  }
}

# Routing tables for private subnets 
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Tying routing tables to private subnets 
resource "aws_route_table_association" "private_route_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

#----------------------------------------------------------------------------------------------------------------------------

# creating RDS (MySQL)
resource "aws_db_instance" "mysql_rds" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "wordpressdb"
  username               = "admin"
  password               = "password123"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  tags = {
    Name = "MyRDS"
  }
}

# subnets for RDS
resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "MainDBSubnetGroup"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Только для приватных запросов
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDSSecurityGroup"
  }
}

#----------------------------------------------------------------------------------------------------------------------------

# creating Redis (ElastiCache)
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "my-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  tags = {
    Name = "MyRedis"
  }
}

# subnets for ElastiCache
resource "aws_elasticache_subnet_group" "main" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id]

  tags = {
    Name = "RedisSubnetGroup"
  }
}

# Security Group for Redis
resource "aws_security_group" "redis_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Только приватный доступ
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RedisSecurityGroup"
  }
}


#----------------------------------------------------------------------------------------------------------------------------

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALBSecurityGroup"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2SecurityGroup"
  }
}

# ALB
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "WebALB"
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

# Tying EC2s to Target Group
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}


resource "aws_lb_target_group_attachment" "web_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


# EC2 creating - 1
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.deb_latest.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = templatefile("wp_deploy.sh.tpl", {
    db_host        = aws_db_instance.mysql_rds.endpoint
    redis_host     = aws_elasticache_cluster.redis.cache_nodes[0].address
    url            = aws_lb.web_alb.dns_name
    cache_key_salt = "unique-key-for-server1"
    # redis_host = "TEST"
  })
  key_name                    = "my_key"
  user_data_replace_on_change = true
  tags = {
    Name = "MyWebServer"
  }
}

# EC2 creating - 1
resource "aws_instance" "web_server_2" {
  ami                    = data.aws_ami.deb_latest.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = templatefile("wp_deploy.sh.tpl", {
    db_host        = aws_db_instance.mysql_rds.endpoint
    redis_host     = aws_elasticache_cluster.redis.cache_nodes[0].address
    url            = aws_lb.web_alb.dns_name
    cache_key_salt = "unique-key-for-server2"
    # redis_host = "TEST"
  })
  user_data_replace_on_change = true
  key_name                    = "my_key"
  tags = {
    Name = "MyWebServer2"
  }
}

#----------------------------------------------------------------------------------------------------------------------------

# EC2 bastion
resource "aws_instance" "web_server_test" {
  ami                         = data.aws_ami.deb_latest.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = "my_key"
  user_data_replace_on_change = true
  tags = {
    Name = "MyWebServer_TEST"
  }
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Доступ к SSH с любого места
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BastionHostSecurityGroup"
  }
}


#----------------------------------------------------------------------------------------------------------------------------

data "aws_ami" "deb_latest" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "ec2_ip" {
  value = aws_instance.web_server_test.public_ip
}
output "ec2_private_ip" {
  value = aws_instance.web_server.private_ip
}

output "ec2_private_ip2" {
  value = aws_instance.web_server_2.private_ip
}

output "db_host" {
  value       = aws_db_instance.mysql_rds.endpoint
  description = "RDS Endpoint for the WordPress database"
}

output "redis_host" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address

}

#----------------------------------------------------------------------------------------------------------------------------









