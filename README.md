# Multiple EC2 Ubuntu Instances Deployment and Provisioning with Terraform & Ansible
* ### Automatically populate Ansible's inventory post-deployment
* ### Uses locally generated elliptic curve key-pairs
* ### Currently only installs Nginx (adjust if needed) 
 
## Requirements
### make sure all three are installed on your system:

 * AWS cli
 * Terraform
 * Ansible
 * JQ to parse JSON
  
## Procedure

1. Create your key-pair locally.
```bash
    # create your key-pair
    ssh-keygen -t ed25519 -C ubuntu
```     

2.  Give the private key proper permissions
```bash
    #  Make sure the key is not too open
    chmod 600 ~/.ssh/ansible-key
```

3. Export Ansible's config file to prevent ssh from checking our key.

```bash
    # export Ansible's config file
    export ANSIBLE_CONFIG=./ansible.cfg
```
4. Initialize Terraform.

```bash
    # run terraform init
    terraform init
```

5. Deploy.
```bash
    # run terraform plan or terraform apply
    # don't forget to adjust the variables before doing so
    terraform apply --auto-approve
```