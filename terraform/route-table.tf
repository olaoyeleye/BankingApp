resource "aws_route_table" "public-kunle-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kunle-igw.id
  }

  tags = {
    Name = "public-kunle-rt"
  }
}

resource "aws_route_table" "private-kunle-rt" {
  vpc_id = aws_vpc.vpc.id
  # route = []

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kunle-igw.id
  }

  tags = {
    Name = "private-kunle-rt"
  }
}