resource "aws_route_table" "public_kunle_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kunle_igw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}