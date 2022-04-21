#Security Groups

// For Kali in public subnet: Allow ssh/http/https/51820 (Wireguard)
resource "aws_security_group" "SecurityGroup-Kali" {
  name        = "SecurityGroup-Kali"
  description = "allows ssh and http"
  vpc_id      = aws_vpc.VPC.id

  ingress {
    from_port   = 51820         // wireguard vpn
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22            // ssh
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8800            // For reverse shells
    to_port     = 8899
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80            // http
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 443           // https
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = -1
    to_port = -1
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0               // allow all
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  depends_on = [ aws_vpc.VPC ]


  tags = {
    Name = "SecurityGroup-Kali"
  }
}

// For Vulnerable machines in private subnet: allow all
resource "aws_security_group" "SecurityGroup-VulnerableMachines" {
  name        = "SecurityGroup-VulnerableMachines"
  description = "Allow only from Public Subnet"
  vpc_id      = aws_vpc.VPC.id


  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [aws_subnet.publicSubnet.cidr_block]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol  = "icmp"
    cidr_blocks = [aws_subnet.publicSubnet.cidr_block]
  }
  
   egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }  

  


  depends_on = [
    aws_vpc.VPC,
    aws_security_group.SecurityGroup-Kali,
  ]

  tags = {
    Name = "SecurityGroup-VulnerableMachines"
  }
}