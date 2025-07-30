provider "aws" {
  region = var.region
}

resource "null_resource" "k8s_master" {
  triggers = {
    script_hash = filemd5("../scripts/setup_master.sh")
  }

  connection {
    type        = "ssh"
    host        = var.instances["master"].dns
    user        = "ubuntu"
    private_key = file(var.instances["master"].kp)
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "../scripts/setup_master.sh"
    destination = "/home/ubuntu/setup.sh"
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
    JOIN_CMD=$(ssh -o StrictHostKeyChecking=no -i "${var.instances["master"].kp}" ubuntu@${var.instances["master"].dns} "cat /home/ubuntu/join-command.sh")
    echo "{\"command\": \"$JOIN_CMD\"}"
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
    user        = "ubuntu"
    private_key = file(each.value.kp)
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "../scripts/setup_worker.sh"
    destination = "/home/ubuntu/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x setup.sh",
      "sudo ./setup.sh",
      "sudo systemctl start kubelet",
      "sleep 10",
      "sudo ${data.external.kubeadm_join_command.result.command} --ignore-preflight-errors=all"
    ]
  }
}

# Add outputs for cluster information
output "master_node" {
  value = var.instances["master"].dns
}

output "worker_nodes" {
  value = {
    for k, v in var.instances : k => v.dns if k != "master"
  }
}

output "join_command" {
  value     = data.external.kubeadm_join_command.result.command
  sensitive = true
}


