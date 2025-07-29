provider "aws" {
  region = var.region
}

resource "null_resource" "k8s_master" {
  connection {
    type        = "ssh"
    host        = var.instances["master"].dns
    user        = "ec2-user"
    private_key = file(var.instances["master"].kp)
  }

  provisioner "file" {
    source      = "scripts/k8s_master.sh"
    destination = "/home/eca-user/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x setup.sh",
      "sudo ./setup.sh"
    ]
  }

}

data "external" "kubeadm_join_command" {
  depends_on = [null_resource.k8s_master]

  program = ["bash", "-c", <<EOT
    ssh -o StrictHostKeyChecking=no -i ${var.instances["master"].kp} ec2-user@${var.instances["master"].dns} "cat /home/ec2-user/join-command.sh"
  EOT
  ]
}

resource "null_resource" "k8s_workers" {
  for_each = {
    for k, v in var.instances : k => v if k != "master"
  }
  connection {
    type        = "ssh"
    host        = each.value.dns
    user        = "ec2-user"
    private_key = file(each.value.kp)
  }

  provisioner "file" {
    source      = "scripts/k8s_worker.sh"
    destination = "/home/eca-user/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x setup.sh",
      "sudo ./setup.sh",
      "sudo ${data.external.kubeadm_join_command.result.command}"
    ]
  }

}


