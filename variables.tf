variable "aws-region" {
  default     = "eu-west-1"
  // default     = "us-east-1"
  description = "Default AWS region"
}

// variable "aws-region" {
//   default     = "us-east-1"
//   description = "Default AWS region"
// }

}

variable "deploment-control" {
  type = map
  default = {
    #"instance" = true or false
    "metasploitable3"         = true
    "dvca"                    = false
    "create_lambda_app"       = false
    "serveless-goat"          = false
    "windowsserver"           = true
  }
  description = "Control whether instances are deployed, false for none or true for one"
}

variable "kali-users" {
  type        = list
  default     = ["user1", "user2"]
  description = "Number of users to be deployed in the Kali Instance"
}

variable "metasploitable3-ami" {
  type = map
  default = {
    "eu-west-1" = "ami-096e7cf8a8f1b315a"  
    "us-east-1" = "ami-0891ed3ed17eacb66" 
  }
  description = "Metasploitable AMI (Note: my AMI's use to be public, if not available use packer script to build your own AMI)"
}

variable "lambda_log_level" {
  description = "Log level for the Lambda Python runtime."
  default = "DEBUG"
}

variable "instance_type" {
  type        = string
  description = "(Optional) The type of instance to start."
  default     = "t2.micro"
}

variable "volume_size" {
  type        = string
  description = "(Optional) The size of the volume in gibibytes (GiB)."
  default     = "15"
}

variable "environment-name" {
  default = "hacking-demo"
}


variable "duckdns_domain" {
  description = "DuckDNS Dyn Domain"
  type        = string
  // default     = "duckdns_usbdomain" m8lab.duckdns.org
}
variable "duckdns_token" {
  description = "Token for DuckDNS"
  type        = string
  // default     = "duckdns_token"
}