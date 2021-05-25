# Init the provider outscale 

terraform {
  required_providers {
    outscale = {
      source = "outscale-dev/outscale"
      version = "0.2.0"
    }
  }
}

provider "outscale" {
  # use env var to provide credentials 
  # export OUTSCALE_ACCESSKEYID="XXXXXXX"
  # export OUTSCALE_SECRETKEYID="YYYYYYYYYYYYYYYYYYYYYYYYYYY"  
  region        = var.region
}



# Create the vm
# This VM is for RKE and act as a bastion the other VM won't have a public IP 

resource "outscale_vm" "rke_vm" {
  image_id                 = var.ubuntu_18_04_id
  vm_type                  = var.vm_type
  keypair_name             = var.keypair_name
  security_group_ids       = [
                                outscale_security_group.rke_node.security_group_id, 
                             ]
  placement_subregion_name = "${var.region}a"
  placement_tenancy        = "default"

  #is_source_dest_checked   = true
  subnet_id = outscale_subnet.public_subnet.subnet_id

  tags {
    key   = "name"
    value = "rke"
  }
}

resource "outscale_public_ip_link" "rke_public_ip_link" {
    vm_id     = outscale_vm.rke_vm.vm_id
    public_ip = outscale_public_ip.rke_public_ip.public_ip
}

# cluster-1 machines
# to access those machine you must pass through RKE machine rke_vm and have ssh-agent up and running 

# master 
resource "outscale_vm" "cluster_1_master_1" {
  image_id                 = var.ubuntu_18_04_id
  vm_type                  = var.vm_type
  keypair_name             = var.keypair_name
  security_group_ids       = [
                              outscale_security_group.rancher_nodes.security_group_id, 
                             ]
  placement_subregion_name = "${var.region}a"
  placement_tenancy        = "default"

  #is_source_dest_checked   = true
  subnet_id = outscale_subnet.private_subnet_1.subnet_id

  tags {
    key   = "name"
    value = "cluster-1-master-1"
  }
}

# worker  
resource "outscale_vm" "cluster_1_worker_1" {
  image_id                 = var.ubuntu_18_04_id
  vm_type                  = var.vm_type
  keypair_name             = var.keypair_name
  security_group_ids       = [
                             outscale_security_group.rancher_nodes.security_group_id, 
                             ]
  placement_subregion_name = "${var.region}a"
  placement_tenancy        = "default"

  #is_source_dest_checked   = true
  subnet_id = outscale_subnet.private_subnet_1.subnet_id

  tags {
    key   = "name"
    value = "cluster-1-worker-1"
  }
}

resource "outscale_vm" "cluster_1_worker_2" {
  image_id                 = var.ubuntu_18_04_id
  vm_type                  = var.vm_type
  keypair_name             = var.keypair_name
  security_group_ids       = [
                              outscale_security_group.rancher_nodes.security_group_id, 
                             ]
  placement_subregion_name = "${var.region}b"
  placement_tenancy        = "default"

  #is_source_dest_checked   = true
  subnet_id = outscale_subnet.private_subnet_2.subnet_id

  tags {
    key   = "name"
    value = "cluster-1-worker-2"
  }
}

resource "outscale_vm" "cluster_1_worker_3" {
  image_id                 = var.ubuntu_18_04_id
  vm_type                  = var.vm_type
  keypair_name             = var.keypair_name
  security_group_ids       = [
                              outscale_security_group.rancher_nodes.security_group_id, 
                             ]
  placement_subregion_name = "${var.region}a"
  placement_tenancy        = "default"

  #is_source_dest_checked   = true
  subnet_id = outscale_subnet.private_subnet_3.subnet_id

  tags {
    key   = "name"
    value = "cluster-1-worker-3"
  }
}


