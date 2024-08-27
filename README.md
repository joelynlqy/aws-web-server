# Deploying a Webserver on AWS EC2 Instance
## Overview
1. Deploying an AWS EC2 Instance using Terraform
2. Set-up system configurations and NGINX webserver using Ansible


## Set-Up Instruction
### Deploying an AWS EC2 Instance using Terraform
Prerequisites:
1. Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
2. Access and Secret Key on AWS Account: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
3. Update terraform/provider.tf with your **AWS Access and Secret Key**.
4. Update **sg_ingress_cidr** in terraform/variables.tf to whitelist your IP Address, else, remove this variable from terraform/main.tf
5. Update other variables in terraform/variables.tf if needed.

![image](https://github.com/user-attachments/assets/7d5f8ae9-2d7c-493c-b428-f0a690119e54)
![image](https://github.com/user-attachments/assets/59409a94-96d1-4e5b-adea-56d8f8b27c2b)


```sh
cd terraform
terraform init
terraform plan
terraform apply
```
After everything has been successfully created, a key_1.pem file will be generated. You can use this key to login to your AWS EC2 Instance.

### Set-up system configurations and NGINX webserver using Ansible
Install Ansible on AWS EC2
```sh
sudo yum update -y
sudo yum install -y ansible
ansible --version
```

Run Ansible Playbook
```sh
sudo yum install -y git
git clone https://github.com/joelynlqy/aws-web-server.git
cd aws-web-server/ansible/
ansible-playbook main.yml -i inventories/staging/hosts/host_vars/host.ini
```

To verify whether webserver is accessible,
```sh
http://< public_ip_of_your_ec2 >
```
![image](https://github.com/user-attachments/assets/d59e1620-8a85-4ba0-8a6e-6c9884b512ef)


## Code Explanation
### Terraform
#### provider.tf
This file declares the provider, provider version and region you are using. During *terraform init*, Terraform will attempt to install the plugins for the provider you selected.
```sh
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.64.0"
    }
  }
}
```
![image](https://github.com/user-attachments/assets/17abe8fa-21d7-47ad-af4c-8fe444e07496)

#### main.tf
This file declares **all the resources** we want to create.
It mainly uses Terraform AWS Modules that can be found over here: https://registry.terraform.io/namespaces/terraform-aws-modules
1. VPC (Virtual Private Cloud): To isolate resources in different network and different subnets are created into different zones for high availability.
2. Security Group: To allow limited access to the resource. In this case, resources in the same network can connect to one another, and some external IPs, via SSH 22 or TCP 80. 
3. Key-Pair (resource is included to retrieve .pem key): To create SSH key-pair for the EC2 Instance. Only those with the private key can access the EC2. 
5. EC2 Instance: Public IP Address is allocated to access via public network. 

```sh
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true
}
```
![image](https://github.com/user-attachments/assets/c0755980-5bcf-4539-8d90-d011fdd85151)


#### variables.tf 
This file declares all the variables we use in our main.tf file, and it also includes the **description** of the variable.
By using variables, we can customise the modules to our needs, making our modules **reusable and composable**. This is suitable when you have **many different environments** but you are using the same set of infrastructure. With the same main.tf file, you can just modify the variables.tf accordingly. 
```sh
variable vpc_name {
  type        = string
  default     = "vpc_1"
  description = "VPC Name"
}
```

#### output.tf
The file declares all the variables we want to **output to CLI**. For what outputs are available for each module, refer to the module link above.

```sh
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}
```


### Ansible
#### Inventories
Since Ansible helps to manage hosts, we use an inventory file to define all the hosts that we have. This is useful when you have a large group of hosts and you have separate ansible playbooks for each of the group. For vars in group_vars inventories, it's to assign variables to all the hosts in that group, so you don't have to include it right beside the host IP.


#### Roles/Nginx
Since installing NGINX is a reusable component, I chose to create it as a role. Which means all VMs that will deploy NGINX can use this same role. 

#### Defaults
A list variables in key: "value" format and can be used to call in tasks / templates files below. This helps in improving modularity of tasks / templates. 
```sh
nginx_conf: "nginx.conf"
nginx_conf_location: "/etc/nginx"
```

#### Handlers
Ansible uses Handlers to manage start, stop, restart and reload, and it is only executed after all tasks in a play has completed. 
```sh
- name: Reload NGINX
  ansible.builtin.service:
    name: nginx
    state: reloaded
```

#### Tasks
**configure.yml**
1. Creates user and user group "nginx", so that we can start NGINX with this user, instead of using root.
2. Enable audit, firewalld and selinux.
   - auditd monitors and tracks security-related information of the Linux server.
   - firewalld controls the network flow of the Linux server.
   - selinux is a Linux kernel security module and helps in defining access control.
3. Disable PasswordAuthentication to force users to login to VM via its' private key, then restart the service to get the new configuration.
```sh
- name: Create 'nginx' group
  ansible.builtin.group:
    name: nginx
    state: present

- name: Create 'nginx' user
  ansible.builtin.user:
    name: nginx
    group: nginx
    groups: root
    state: present
```

**install_nginx.yml**
1. Install NGINX open source
2. Get **nginx.conf** from templates, update with default values, then upload the file to the destination. Once this is completed, NGINX configuration is validated via handler.
3. Get **index.html** from templates, update with default values, then upload the file to the destination.
4. Start NGINX server and reload it via handler.
```sh
- name: Install NGINX Open Source
  ansible.builtin.dnf: 
    name: nginx
    state: present
```

#### Templates
To dynamically generate text-based files, mainly to facilitate and automate management of configuration files for different targets. 
```sh
<!doctype html>
<html>
    <head>
        <title>Title of Website</title>
    </head>
    <body>
        <p>Body of Website: <strong> {{index_html_body}} </strong></p>
    </body>
</html>
```

#### main.yml
States the **hosts** and **connection** method, then choose which role to run on these hosts. Since we are running directly on the VM itself, it's set to localhost and local.
```sh
- hosts: localhost
  connection: local
  gather_facts: false
  become: true
  roles:
    - nginx
```

## Usage Instructions
To check the access logs of NGINX,
```sh
cat /var/log/nginx/access.log
```
To check the error logs of NGINX,
```sh
cat /var/log/nginx/error.log
```
To check the status of NGINX,
```sh
ps -ef | grep nginx
```
To check whether the process is listening to the correct port,
```sh
netstat -tnlp | grep 80
```

## Additional Notes
Challenges
1. Key-Pair on AWS cannot be viewed on console, and since private_key_pem is sensitive, it cannot be printed as an output.
Credits: https://stackoverflow.com/questions/67389324/create-a-key-pair-and-download-the-pem-file-with-terraform-aws
2. The private key as plain text in Terraform State Files, will need to store state files somewhere safe as well. 

Assumptions
1. VM created all uses the same AMI, same OS Amazon Linux 2023. AL2023 does not support epel-release, hence, we can directly install NGINX open source.
2. Purpose of the VM is just to host a webserver with a index.html on port 80 (HTTP) and not meant for many client connections.
3. There's only 1 VM to manage, no master-slave setup required.

Potential Improvements
1. Use logrotate to automate log rotate for NGINX log files.
2. Use an external secret management system, like HashiCorp Vault, to store AWS Access and Secret Key.
