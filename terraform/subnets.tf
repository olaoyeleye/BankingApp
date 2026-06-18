resource "aws_subnet" "public-kunle-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.vpc_name}-public"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
  }
}


resource "aws_subnet" "public-kunle-subnet-2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.vpc_name}-public"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
  }
}



resource "aws_subnet" "private-kunle-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"


    tags = {
    Name                                            = "${var.vpc_name}-public"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
  }

}

