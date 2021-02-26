//Internet Gateway for VPC
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.VPC.id
  depends_on = [aws_vpc.VPC]

  tags = {
    Name = "InternetGateway"
  }
}