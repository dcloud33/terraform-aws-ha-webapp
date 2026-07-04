# Virtual Private Cloud
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "vpc_network" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
  Name        = "network_vpc"
  
  }
}



############# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_network.id

  tags = {
    Name = "Internet Gateway"
  }
}

########### Elastic IP
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "elastic_ip"
  }
}

############ Route Table: Public
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_network.id

  tags = {
    Name = "My_public_route_table"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "route_table_association" {
  count = length(aws_subnet.subnet_public)
  subnet_id      = aws_subnet.subnet_public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# resource "aws_route_table_association" "route_table_association_2" {
#   subnet_id      = aws_subnet.subnet_public_b.id
#   route_table_id = aws_route_table.public_route_table.id
# }

############## Route Table: Private
resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.vpc_network.id

  tags = {
    Name = "private-route_table"
  }
}

resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.my_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count = length(aws_subnet.subnet_private)
  subnet_id      = aws_subnet.subnet_private[count.index].id
  route_table_id = aws_route_table.my_private_route_table.id
}

# resource "aws_route_table_association" "private_route_table_association_2" {
#   subnet_id      = aws_subnet.subnet_private_b.id
#   route_table_id = aws_route_table.my_private_route_table.id
# }

# Public subnet:
# - Has route to Internet Gateway
# - NAT Gateway lives here
# 
# Private subnet:
# - Has route to NAT Gateway
# - Private EC2 instances live here
#
#
#

################## NAT
resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.subnet_public[0].id

  tags = {
    Name = "nat gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

########## Subnets: Public
resource "aws_subnet" "subnet_public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.vpc_network.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "public_subnets"
  }
}


########### Subnets: Private

resource "aws_subnet" "subnet_private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.vpc_network.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = "private_subnets"
  }
}


















































