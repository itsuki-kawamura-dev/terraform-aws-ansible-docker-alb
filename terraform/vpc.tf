
# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terraform-handson-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "terraform-handson-igw"
  }
}

# Create NATGateway
# NAT Gateway is not required for SSM Session Manager because
# SSM traffic uses VPC Interface Endpoints.
# It is included here only for general outbound internet access,
# such as package updates (dnf/yum update) from the private EC2 instance.
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_a.id
}

# Create Public subnet a
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform-handson-public-subnet-a"
  }
}

# Create Public subnet c
resource "aws_subnet" "public_subnet_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "terraform-handson-public-subnet-c"
  }
}

# Create Private subnet a
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "terraform-handson-private-subnet-a"
  }
}

# Create Private subnet c
resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "terraform-handson-private-subnet-c"
  }
}

# Create public route table
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-handson-public-rt"
  }
}

# Create private route table
# Optional outbound internet access for package updates and testing.
# SSM connectivity itself does not depend on this route.
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "terraform-handson-private-rt"
  }
}

# Associate with Public Route Table a
resource "aws_route_table_association" "route_table_association_public_a" {
  route_table_id = aws_route_table.route_table_public.id
  subnet_id      = aws_subnet.public_subnet_a.id
}

# Associate with Public Route Table c
resource "aws_route_table_association" "route_table_association_public_c" {
  route_table_id = aws_route_table.route_table_public.id
  subnet_id      = aws_subnet.public_subnet_c.id
}

# Associate with Private Route Table a
resource "aws_route_table_association" "route_table_association_private_a" {
  route_table_id = aws_route_table.route_table_private.id
  subnet_id      = aws_subnet.private_subnet_a.id
}

# Associate with Private Route Table c
resource "aws_route_table_association" "route_table_association_private_c" {
  route_table_id = aws_route_table.route_table_private.id
  subnet_id      = aws_subnet.private_subnet_c.id
}