output "rke_vm_public_ip" {
  value = outscale_public_ip.rke_public_ip.public_ip
}

output "cluster_1_master_1_private_ip" {
  value = outscale_vm.cluster_1_master_1.private_ip
}

output "cluster_1_worker_1_private_ip" {
  value = outscale_vm.cluster_1_worker_1.private_ip
}

output "cluster_1_worker_2_private_ip" {
  value = outscale_vm.cluster_1_worker_2.private_ip
}

output "cluster_1_worker_3_private_ip" {
  value = outscale_vm.cluster_1_worker_3.private_ip
}
