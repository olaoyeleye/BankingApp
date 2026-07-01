resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_kunle_subnet_a.id
  route_table_id = aws_route_table.public_kunle_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_kunle_subnet_b.id
  route_table_id = aws_route_table.public_kunle_rt.id
}