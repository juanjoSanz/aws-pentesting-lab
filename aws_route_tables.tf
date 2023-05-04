
# Public Route Table
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }
   depends_on = [aws_vpc.VPC, aws_internet_gateway.InternetGateway]

  tags = {
    Name = "PublicRouteTable"
  }
}


//Association with Public subnet
resource "aws_route_table_association" "PublicAssociation" {
  subnet_id      = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id


  depends_on = [
    aws_subnet.publicSubnet, 
    aws_route_table.PublicRouteTable
  ]
}


# Private Route Table
# none