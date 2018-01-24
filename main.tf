/* query info about subnets */
data "aws_subnet" "selected" {
  count = "${length(var.subnet_id)}"

  id = "${element(var.subnet_id, count.index)}"
}

data "aws_security_group" "default" {
  vpc_id = "${element(data.aws_subnet.selected.*.vpc_id, 0)}"

  name = "default"
}

data "aws_region" "current" {
  current = true
}

data "aws_ami" "selected" {
  filter {
    name   = "image-id"
    values = [ "${local.ami}" ]
  }
}

resource aws_launch_configuration "rabbitmq" {
  name_prefix = "${format("%s-%s%02d-", var.product, var.environment, (var.stack_number + 0))}"

  /* Amazon Machine Image (AMI) to use */
  image_id      = "${local.ami}"

  /* instance type (vCPU, memory, etc) */
  instance_type = "${var.instance_type}"

  /* define build details (user data, key, instance profile) */
  key_name             = "${var.key_name}"
  iam_instance_profile = "${var.instance_profile}"

  /* define network details (subnet, private and/or public IP, etc) */
  security_groups = [ "${list(local.security_group, data.aws_security_group.default.id)}" ]

  /* customize the root block device */
  root_block_device {
    volume_size = "${lookup(var.root_volume, "size", "gp2")}"
    volume_type = "${lookup(var.root_volume, "type", 8)}"
    iops        = "${lookup(var.root_volume, "iops", 0)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_group "rabbitmq" {
  name_prefix = "${format("%s-%s%02d-", var.product, var.environment, (var.stack_number + 0))}"

  /* tie to launch configuration created above */
  launch_configuration = "${aws_launch_configuration.rabbitmq.name}"

   health_check_grace_period = 60

   /* controls how health check is done */
   health_check_type = "EC2"

   force_delete = true

   /* scaling details */
   min_size         = "${var.instance_count}"
   max_size         = "${var.instance_count}"
   desired_capacity = "${var.instance_count}"

   /* subnet(s) to launch instances in */
   vpc_zone_identifier = [ "${var.subnet_id}" ]

   /* add our tags */
   tags = [ "${concat(var.tags, local.tags)}" ]
}

resource "aws_security_group" "main" {

  /* can't do this, as local conditional will fail with resource not found */
  count = "${local.create_internal_sg}"

  /* some metadata */
  name = "${local.stack_tag}"
  description = "Define inbound and outbound traffic for ${local.stack_tag}"

  /* link to the VPC that the instances was created in */
  vpc_id = "${element(data.aws_subnet.selected.*.vpc_id, 0)}"

 // tags = "${merge(local.tags, var.tags)}"

}

resource "aws_security_group_rule" "ingress" {

  count = "${length(var.sg_inbound_rules) * local.create_internal_sg}"

  /* this is an ingress security rule */
  type  = "ingress"

  /* specify port range and protocol that is allowed */
  from_port = "${lookup(var.sg_inbound_rules[count.index], "from_port")}"
  to_port   = "${lookup(var.sg_inbound_rules[count.index], "to_port")}"
  protocol  = "${lookup(var.sg_inbound_rules[count.index], "protocol")}"

  /* specify the allowed CIDR block */
  cidr_blocks =  [ "${lookup(var.sg_inbound_rules[count.index], "cidr_blocks")}" ]

  /* link to the above created security group */
  security_group_id = "${aws_security_group.main.id}"

}

resource "aws_security_group_rule" "egress" {

  count = "${length(var.sg_outbound_rules) * local.create_internal_sg}"

  /* this is an ingress security rule */
  type  = "egress"

  /* specify port range and protocol that is allowed */
  from_port = "${lookup(var.sg_outbound_rules[count.index], "from_port")}"
  to_port   = "${lookup(var.sg_outbound_rules[count.index], "to_port")}"
  protocol  = "${lookup(var.sg_outbound_rules[count.index], "protocol")}"

  /* specify the allowed CIDR block */
  cidr_blocks = [ "${lookup(var.sg_outbound_rules[count.index], "cidr_blocks")}" ]

  /* link to the above created security group */
  security_group_id = "${aws_security_group.main.id}"

}
