#Variables#
variable "network_address_space" {
    default = "10.1.0.0/16"
}
variable "subnet1_address_space"
{ default = "10.1.0.0/24"
}
variable "subnet2_address_space"
{ default="10.1.1.0/24"}

provider "aws" 
{ 
region = "eu-central-1"
}
data "aws_availability_zones" "available" {}

#Resources#
resource "aws_vpc" "vpc"
{ 
    cidr_block = "${var.network_address_space}"
    enable_dns_hostnames = "true"
}
resource "aws_internet_gateway" "igw"
{
    vpc_id = "${aws_vpc.vpc.id}"
}
resource "aws_subnet" "subnet1"
{ 
    cidr_block = "${var.subnet1_address_space}"
    vpc_id = "${aws_vpc.vpc.id}"
    map_public_ip_on_launch = "true"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}
resource "aws_subnet" "subnet2"
{ 
    
    cidr_block = "${var.subnet2_address_space}"
    vpc_id = "${aws_vpc.vpc.id}"
    map_public_ip_on_launch = "true"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}
 #Routing#
 resource "aws_route_table" "rtb"
 { 
     vpc_id = "${aws_vpc.vpc.id}"
     route{
         cidr_block = "0.0.0.0/0"
         gateway_id = "${aws_internet_gateway.igw.id}"
     }
 }

resource "aws_route_table_association" "rta-subnet1"
{
    subnet_id = "${aws_subnet.subnet1.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}
resource "aws_route_table_association" "rta-subnet2"
{
    subnet_id = "${aws_subnet.subnet2.id}"
    route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_security_group" "nginx-sg"
{
    name ="nginx_sg"
    vpc_id = "${aws_vpc.vpc.id}"

    #SSH access
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #HTTP access
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks =["0.0.0.0/0"]
    }
    #outbound internet access
    ingress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks =["0.0.0.0/0"]
    }
}
#Instances
resource "aws_instance" "nginx1" 
{ 
    ami = "ami-c7ee5ca8"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.subnet1.id}"
    vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
    tags { 
        Name = "Terra-Instance"
        }


provisioner "remote-exec"
{
    inline = [
        "sudo install nginx -y",
        "sudo service nginx start",
        "echo '<html><head><title>Blue Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
    ]
}}
#Output
output "aws_instance_public_dns" {
    value = "${aws_instance.nginx1.public_dns}"
}


