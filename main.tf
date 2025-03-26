provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "wp-s3-vpc"
  }
}

# Subnet --------------------------------------------------------------------------------------------
resource "aws_subnet" "my_public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "Public subnet App-Inet"
  }
}

resource "aws_subnet" "my_private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "Private subnet App-DB"
  }
}

resource "aws_subnet" "private_db_inet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "Private subnet DB-Inet"
  }
}

resource "aws_subnet" "public_nat" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "Public subnet NAT-GW"
  }
}

# Elastic IP ----------------------------------------------------------------------------------------
resource "aws_eip" "public_eip" {
  domain = "vpc"
  network_interface = aws_network_interface.eni1.id

  tags = {
    Name = "public-eip"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "nat-eip"
  }
}

# Gateway -----------------------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wp s3 igw"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_nat.id

  tags = {
    Name = "wp s3 NAT"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table --------------------------------------------------------------------------------------------
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "my public rtb"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.my_public.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "my private rtb"
  }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_db_inet.id
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_route_table" "nat_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "NAT rtb"
  }
}

resource "aws_route_table_association" "nat_rta" {
  subnet_id      = aws_subnet.public_nat.id
  route_table_id = aws_route_table.nat_rtb.id
}

# Security Group -----------------------------------------------------------------------------------------
resource "aws_security_group" "public_sg" {
  name        = "my-public-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "WP sg"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "my-private-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MRDB sg"
  }
}

# Network interface -------------------------------------------------------------------------------------
resource "aws_network_interface" "eni1" {
  subnet_id   = aws_subnet.my_public.id
  security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "public eni"
  }
}

resource "aws_network_interface" "eni2" {
  subnet_id   = aws_subnet.my_private.id
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "pb-pv eni"
  }
}

resource "aws_network_interface" "eni3" {
  subnet_id   = aws_subnet.my_private.id
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "pv-pb eni"
  }
}

resource "aws_network_interface" "eni4" {
  subnet_id   = aws_subnet.private_db_inet.id
  security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "pv-nat eni"
  }
}

# S3 ----------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "main_pab" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "wp_s3_oc" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_iam_user" "wp_s3_user" {
  name = "wp-s3-user"

  tags = {
    Name = "wp-s3-user"
    Environment = "Dev"
  }
}

resource "aws_iam_user_policy_attachment" "wp_s3_pa" {
  user       = aws_iam_user.wp_s3_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_access_key" "wp_s3_ak" {
  user = aws_iam_user.wp_s3_user.name
}

# EC2 ---------------------------------------------------------------------------------------------
data "template_file" "cloud_init" {
  template = file("cloud-init.tpl")

  vars = {
    app_instance_ip = aws_eip.public_eip.public_ip
    private_instance_ip = aws_instance.private_instace.private_ip
    bucket_name = aws_s3_bucket.main.bucket
    region = var.region
    access_key = aws_iam_access_key.wp_s3_ak.id
    secret = aws_iam_access_key.wp_s3_ak.secret
    database_name = var.database_name
    database_user = var.database_user
    database_pass = var.database_pass
    admin_user = var.admin_user
    admin_pass = var.admin_pass
  }
}

resource "aws_instance" "public_instace" {
  ami           = var.ami
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.eni1.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.eni2.id
    device_index         = 1
  }

  user_data = data.template_file.cloud_init.rendered

  depends_on = [aws_instance.private_instace]

  tags = {
    Name = "App Instance"
  }
}

data "template_file" "cloud_init_db" {
  template = file("cloud-init-db.tpl")

  vars = {
    database_name = var.database_name
    database_user = var.database_user
    database_pass = var.database_pass
  }
}

resource "aws_instance" "private_instace" {
  ami           = var.ami
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.eni3.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.eni4.id
    device_index         = 0
  }

  user_data = data.template_file.cloud_init_db.rendered

  depends_on = [aws_nat_gateway.main]

  tags = {
    Name = "DB Instance"
  }
}
