resource "aws_route_table_association" "public-association" {
  subnet_id      = aws_subnet.public-kunle-subnet.id
  route_table_id = aws_route_table.public-kunle-rt.id
}


resource "aws_route_table_association" "private-association" {
  subnet_id      = aws_subnet.private-kunle-subnet.id
  route_table_id = aws_route_table.private-kunle-rt.id
}