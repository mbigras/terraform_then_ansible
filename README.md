# Terraform then Ansible

>Spin up a Digital Ocean Droplet with Terraform, then provision it with Ansible

## Usage example

```
ssh-keygen -q -b 2048 -t rsa -N '' -f id_rsa		# Generate an SSH keypair
export TF_VAR_do_token="$(lpass show --notes do_token)"	# Recover Digital Ocean token
terraform apply
ansible-playbook some.yml
ip=$(terraform output | awk '/ip/ { print $NF }')
ssh -i id_rsa root@$ip ruby --version

terraform destroy -force
rm id_rsa*
```