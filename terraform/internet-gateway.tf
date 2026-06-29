resource "aws_internet_gateway" "kunle-igw" {
  vpc_id = aws_vpc.vpc.id
  #depends_on = [    aws_eks_node_group.main  ]
  tags = {
    Name = "kunle-igw"
  }
}