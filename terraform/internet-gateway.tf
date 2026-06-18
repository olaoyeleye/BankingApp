resource "aws_internet_gateway" "kunle-igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "kunle-igw"
  }
}