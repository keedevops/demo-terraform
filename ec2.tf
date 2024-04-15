#Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}




#Create a public subnet
resource "aws_subnet" "PublicSubnet" {
  vpc_id            = aws_vpc.myvpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.1.0/24"
}




#create a private subnet
resource "aws_subnet" "PrivSubnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

}


#create IGW
resource "aws_internet_gateway" "myIgw" {
  vpc_id = aws_vpc.myvpc.id
}




#route Tables for public subnet
resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIgw.id
  }
}

#route table association public subnet
resource "aws_route_table_association" "PublicRTAssociation" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRT.id
}


# Creating a security group
resource "aws_security_group" "allow_tls" {
  name        = "tf-security"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id # Replace with your VPC ID




  tags = {
    Name = "terra-securityrule"
  }




}


# Ingress rule for TLS traffic (IPv4)
resource "aws_security_group_rule" "allow_tls_ipv4" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_tls.id
}


# Ingress rule for TLS traffic (IPv6)
resource "aws_security_group_rule" "allow_tls_ipv6" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.allow_tls.id
}


# Ingress rule for port 8080 (IPv4)
resource "aws_security_group_rule" "allow_port_8080_ipv4" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_tls.id
}


# Ingress rule for SSH traffic (port 22)
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_tls.id
}


# Egress rule allowing all outbound traffic (IPv4)
resource "aws_security_group_rule" "allow_all_traffic_ipv4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_tls.id
}


# Egress rule allowing all outbound traffic (IPv6)
resource "aws_security_group_rule" "allow_all_traffic_ipv6" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.allow_tls.id
}

# Creating an EC2 instance
resource "aws_instance" "terra-ec2" {
  ami           = "ami-0a1b648e2cd533174"
  instance_type = "t3.micro"


  #define root volume
  root_block_device {
    volume_type = "gp2"
    volume_size = 8


  }

  tags = {
    Name = "Terraform-ec2"
  }


  depends_on = [
    aws_key_pair.devkey
  ]

  # Attaching the security group to the EC2 instance
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "aws-key"
  subnet_id              = aws_subnet.PublicSubnet.id
  user_data              = <<-EOF
              #!/bin/bash
              sudo apt update  # Update package lists
              sudo apt install -y apache2  # Install Apache HTTP Server (httpd)
              echo "<h1>Hello, World!</h1>" > /var/www/html/index.html  # Create index.html page
              systemctl start apache2  # Start Apache HTTP Server
              systemctl enable apache2  # Enable Apache HTTP Server to start on boot
              EOF
}


resource "aws_key_pair" "devkey" {
  key_name   = "aws-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVMnqBNq8nXjtcCO6QW2LVFdXShcTZySmHJNzR82wJblOzCzO8F3cFkpfehUMU+WiqfXsNTed2SGRtRS3T8ci7ljoGxU9idUgLEr+rIDjSCgSDxUGkeVQXkPw53wDTkHa2yqdz+zMekPM5vR/RaQZ8GKFrEia6+9KY9aZBQbkxsHJZOXT7NGKkosAUjSB5/50Hh18nCP3bAMCTDAAhpibsw+z6DNTwvEiz3PmctlblKcHUQON8U75YcJcTXk9FR94fEfKY7Uyj7BCpS5rXe2LcZL+9GOEftTM+xIqECDWahmDdlyo7E40Pq9U+0rDvETqDzRQfCf//aq9CA1tIksxr vcare@DESKTOP-ESARN6B"
}
