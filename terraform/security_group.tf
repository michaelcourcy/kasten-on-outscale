# https://www.rancher.co.jp/docs/rancher/v2.x/en/installation/references/#
# security group

resource "outscale_security_group" "rke_node" {  
  security_group_name = "rke_node"
  net_id              = outscale_net.rancher_net.net_id
  tags {
    key   = "Name"
    value = "rke_node"
  }
}

resource "outscale_security_group" "rancher_nodes" {  
  security_group_name = "rancher_nodes"
  net_id              = outscale_net.rancher_net.net_id
  tags {
    key   = "Name"
    value = "rancher_nodes"
  }
}


# security group rule 

# SSH 
# RKE node accept 22 request from outside world 
resource "outscale_security_group_rule" "rke_ssh" {
  flow              = "Inbound"
  security_group_id = outscale_security_group.rke_node.security_group_id
  from_port_range   = "22"
  to_port_range     = "22"
  ip_protocol       = "tcp"
  ip_range          = "0.0.0.0/0"
}
# HTTP/HTTPS 
# RKE node accept http/https request from outside world 
resource "outscale_security_group_rule" "rke_http" {
  flow              = "Inbound"
  security_group_id = outscale_security_group.rke_node.security_group_id
  from_port_range   = "80"
  to_port_range     = "80"
  ip_protocol       = "tcp"
  ip_range          = "0.0.0.0/0"
}
resource "outscale_security_group_rule" "rke_https" {
  flow              = "Inbound"
  security_group_id = outscale_security_group.rke_node.security_group_id
  from_port_range   = "443"
  to_port_range     = "443"
  ip_protocol       = "tcp"
  ip_range          = "0.0.0.0/0"
}

## Allow internal trafic for rancher nodes on any protocol any port 
resource "outscale_security_group_rule" "rancher_allow_internal" {
  flow              = "Inbound"
  security_group_id = outscale_security_group.rancher_nodes.security_group_id
  from_port_range   = "0"
  to_port_range     = "65535"
  ip_protocol       = "-1"
  ip_range          = outscale_net.rancher_net.ip_range
}
