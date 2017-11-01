provider "aws" 
{ 
region = "eu-central-1"
}
resource "aws_instance" "example" { 
    ami = "ami-c7ee5ca8"
    instance_type = "t2.micro"
    tags { 
        Name = "Terra-Instance"
        }
}
