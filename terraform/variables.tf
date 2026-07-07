variable "aws_region" {
    type = string
    default = "eu-south-2"
    description = "The target AWS region for deployment"
}

variable "instance_type" {
    type = string
    default = "t3.micro"
    description = "The sizing profile of the compute instance"
}
