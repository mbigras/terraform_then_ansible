variable "do_token" {}

variable "private_key" {
  default = "id_rsa"
}

variable "public_key" {
  default = "id_rsa.pub"
}

variable "hosts_file" {
  default = "hosts"
}

variable "image_id" {
  default = "centos-7-x64"
}

output "ip" {
  value = "${digitalocean_droplet.somehost.ipv4_address}"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "default" {
  name       = "Terraform"
  public_key = "${file(var.public_key)}"
}

resource "digitalocean_droplet" "somehost" {
  image = "${var.image_id}" # centos 7
  name = "somehost"
  region = "sfo2"
  size = "512mb"
  ssh_keys = [
    "${digitalocean_ssh_key.default.fingerprint}"
  ]
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file(var.private_key)}"
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "echo Waiting for cloud-init...",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo cloud-init is finished!",
      "yum update -y",
      "yum install -y python"
    ]
  }
}

resource "local_file" "hosts" {
    content = "[droplets]\n${digitalocean_droplet.somehost.ipv4_address}\n"
    filename = "${var.hosts_file}"
}

resource "null_resource" "ssh_tester" {
  provisioner "local-exec" {
    command = <<EOF
      echo Checking SSH connectivity...
      ip="${digitalocean_droplet.somehost.ipv4_address}"
      key="${var.private_key}"
      ssh-keyscan $ip >> ~/.ssh/known_hosts
      ssh -i "$key" root@$ip echo Hello remote world!
    EOF
  }
  provisioner "local-exec" {
    command = <<EOF
      echo Checking Ansible connectivity...
      ansible -m ping all
    EOF
  }
}