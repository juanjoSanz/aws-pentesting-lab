# Subnet Creation

data "aws_availability_zones" "available" {
  state = "available"
}

//Public subnet
resource "aws_subnet" "publicSubnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  depends_on = [aws_vpc.VPC]
  tags = {
    Name = "publicSubnet"
  }
}

//Private subnet
resource "aws_subnet" "privateSubnet" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  depends_on = [aws_vpc.VPC]
  tags = {
    Name = "privateSubnet"
  }
}