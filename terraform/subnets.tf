resource "aws_subnet" "public-kunle-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

 # tags = {
 #   Name                                            = "${var.vpc_name}-public"
 #   #"kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
 #   "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
 #   "kubernetes.io/role/elb" = "1" # Required for public LBS
 # }


  tags = {
    Name                                             = "${var.vpc_name}-public-1a"
    "kubernetes.io/cluster/${var.vpc_name}-cluster"  = "shared"
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs

  }
}


resource "aws_subnet" "public-kunle-subnet-2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone       = "${var.region}b"   # e.g. eu-west-1b
  map_public_ip_on_launch = true

  #tags = {
  #  Name                                            = "${var.vpc_name}-public"
  #  #"kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
  #  "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
  #  "kubernetes.io/role/elb" = "1"
  #}

  tags = {
    Name                                            = "${var.vpc_name}-publicb"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
    "kubernetes.io/role/elb" = "1" # Required for public LBS
  }
}



resource "aws_subnet" "private-kunle-subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"


    tags = {
    Name                                            = "${var.vpc_name}-private"
    "kubernetes.io/role/internal-elb"               = "1" # Required for Private LBs
    "kubernetes.io/cluster/${var.vpc_name}-cluster" = "shared"
  }

}

