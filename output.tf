#output "instance_id"      { value = [ "${aws_instance.main.*.id}" ] }
#output "instance_prvt_ip" { value = [ "${aws_instance.main.*.private_ip}" ] }
