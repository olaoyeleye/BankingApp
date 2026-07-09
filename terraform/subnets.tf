resource "aws_subnet" "public_kunle_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.vpc_name}-public-a"
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
}

resource "aws_subnet" "public_kunle_subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.vpc_name}-public-b"
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
}