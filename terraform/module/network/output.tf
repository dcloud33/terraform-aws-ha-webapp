output "vpc_id" {
  value = aws_vpc.vpc_network.id
}

output "public_subnet_ids" {
  value = aws_subnet.subnet_public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.subnet_private[*].id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc_network.cidr_block
}