#####################################################
#          Local Variable definitions               #
#####################################################
locals {

  /*
    Either use supplied AMI or lookup based on region
  */
  //ami = "${var.ami == "" ? local.region_ami : var.ami}"
  ami = "${var.ami == "" ? lookup(var.amazon_ami, data.aws_region.current.name) : var.ami}"

  /* use user supplied security group ? */
  security_group     = "${var.sg_id == "" ? aws_security_group.main.id : var.sg_id}"
  create_internal_sg = "${var.sg_id == "" ? 1 : 0}"

  /*
   Default tags (local so you can't over-ride)
  */
  tags = [
    {
      key                 = "product"
      value               = "${var.product}"
      propagate_at_launch = true
    },
    {
      key                 = "stack"
      value               = "${format("%s-%s%02d", var.product, var.environment, (var.stack_number + 0))}"
      propagate_at_launch = true
    },
    {
      key                 = "role"
      value               = "${var.role}"
      propagate_at_launch = true
    },
    {
      key                 = "environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "built-with"
      value               = "terraform"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${format("%s-%s%02d-%s", var.product, var.environment, (var.stack_number + 0), var.role)}"
      propagate_at_launch = true
    }
  ]

  volume_tags {
    built-with = "terraform"
  }

  stack_tag = "${format("%s-%s%02d-%s", var.product,
                                        var.environment,
                                        (var.stack_number + 0),
                                        var.role)}"

  alphabet = [ "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "p" ]
}

variable "amazon_ami" {
  type = "map"
  default {
    "us-east-1"    = "ami-8c1be5f6"
    "us-east-2"    = "ami-c5062ba0"
    "us-west-1"    = "ami-02eada62"
    "us-west-2"    = "ami-e689729e"
    "ca-central-1" = "ami-fd55ec99"
  }
}

/* meta data about this instance stack */
variable "product"      { description = "Product name" }
variable "role"         { description = "Instance role" }
variable "environment"  { description = "Environment" }
variable "stack_number" { default = 1 }


/* provisioning details about the instances */
variable "instance_count" {
  description = "Number of instances to create"
  default     = 2
}

variable "instance_type" {
  description      = "Instance Type, specifies vCPU and memory characteristics"
  default          = "t2.nano"
}

variable "ami" {
  description = "Amazon Machine Image (AMI) ID"
  default     = ""
}

variable "instance_profile" {
  description = "IAM instance profile to attach to instance"
  default     = ""
}

variable "key_name" {
  description = "SSH key to assign to this instance (blank = VPC default)"
  default     = ""
}


/*
  Customize the instance root block device
*/
variable "root_volume" {
  description = "Define the root volume settings"
  type        = "map"

  default = {
    type                  = "gp2"
    size                  = "8"
    iops                  = "400"
    delete_on_termination = true
  }

}

/*
  List of maps that defines the details of additional disks to attach

  ex:
  [
    {
      type        = "gp2"
      size        = "100"
      iops        = "0"
    }
  ]

  All fields are required.
*/
variable "ebs_volume" {
  description = "Define settings for additional disks to attach to instance"
  type        = "list"

  default = []
}

variable "tags" {
  description = "A map of tags to all to all resources"
  default     = []
}

variable "volume_tags" {
  description = "A map of tags to the volumes associated with this instance"
  default     = {}
}

variable "enable_dns" {
  description = "Enable or disable DNS support and DNS hostnames"
  default = false
}

variable "enable_public_ip" {
  description = "Enable or disable mapping of public IP in public subnets"
  default = false
}

variable "subnet_id" {
  type    = "list"
}

variable "sg_id" {
  description = "Security group ID to associate instance with"
  default     = ""
}

variable "sg_inbound_rules" {
  type    = "list"
  default =
    [
      {
        from_port   = "22"
        to_port     = "22"
        protocol    = "TCP"
        cidr_blocks = "0.0.0.0/0"
      }
    ]
}

variable "sg_outbound_rules" {
  type    = "list"
  default =
    [
      {
        from_port   = "-1"
        to_port     = "-1"
        protocol    = "all"
        cidr_blocks = "0.0.0.0/0"
      }
    ]
}
