provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
} 

resource "aws_vpc" "example-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

resource "aws_internet_gateway" "example-gw" {
  vpc_id = aws_vpc.example-vpc.id

  tags = {
    Name = "example-gateway"
  }
}


resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example-vpc.id

}

resource "aws_route_table" "example--route-table" {
  vpc_id = aws_vpc.example-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  }

}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.example-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_route_table_association" "ass" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.example-route-table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.example-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]


}


resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.example-gw]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
}


resource "aws_instance" "test-ubuntu" {
    ami                 = "ami-0ff39345bd62c82a5"
    instance_type       = "t2.micro"
    availability_zone   = "us-east-2a"
    key_name            = "main-pair"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
    }

    # user_data = <<-EOF
    #             #!/bin/bash
    #             sudo apt update -y
    #             sudo apt install apache2 -y
    #             sudo systemctl start apache2
    #             sudo bash -c 'echo a web server > /var/www/html/index.html'
    #             EOF

    # tags = {
    #     Name = "webserver"
    # }
}


# resource "aws_route_table" "example-route-table" {
#   vpc_id = aws_vpc.example-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.example-gw.id
    
#   }

#   route {
#     ipv6_cidr_block        = "::/0"
#     gateway_id = aws_internet_gateway.example-gw.id
#   }

#   tags = {
#     Name = "example-route-table"
#   }
# }