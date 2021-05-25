########### Net #################

resource "outscale_net" "rancher_net" {
  ip_range = "10.0.0.0/16"
  tags {
    key = "name"
    value = "rancher"
    }
}

############  Public Subnet #######################

resource "outscale_internet_service" "internet_gateway" {    
}

resource "outscale_internet_service_link" "internet_gateway_link" {
    internet_service_id = outscale_internet_service.internet_gateway.internet_service_id
    net_id              = outscale_net.rancher_net.net_id
}


resource "outscale_route_table" "public_route_table" {
  net_id = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "public_route_table"
  }
}

resource "outscale_route" "to_internet" {
  gateway_id           = outscale_internet_service.internet_gateway.internet_service_id
  destination_ip_range = "0.0.0.0/0"
  route_table_id       = outscale_route_table.public_route_table.route_table_id  
}

resource "outscale_subnet" "public_subnet" {
  subregion_name = "${var.region}a"
  ip_range       = "10.0.0.0/24"
  net_id         = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "public_subnet"
  }
}

resource "outscale_route_table_link" "public_subnet_public_route_table_link" {
    subnet_id      = outscale_subnet.public_subnet.subnet_id
    route_table_id = outscale_route_table.public_route_table.route_table_id
}

# Give a public ip to the rke machine 

resource "outscale_public_ip" "rke_public_ip" { }

# create a natgateway in the public subnet 

resource "outscale_public_ip" "public_nat_gateway_ip" { }

resource "outscale_nat_service" "public_nat_gateway" {
  subnet_id    = outscale_subnet.public_subnet.subnet_id
  public_ip_id = outscale_public_ip.public_nat_gateway_ip.public_ip_id
  tags {
    key   = "name"
    value = "public_nat_gateway"
  }
}

############  Private Subnet #######################

# Create a private route table for the private subnets 

resource "outscale_route_table" "private_route_table" {
  net_id = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "private_route_table"
  }
}

resource "outscale_route" "to_nat_gateway" {
  nat_service_id           = outscale_nat_service.public_nat_gateway.nat_service_id
  destination_ip_range = "0.0.0.0/0"
  route_table_id       = outscale_route_table.private_route_table.route_table_id  
}

##### private subnet 1 ######

resource "outscale_subnet" "private_subnet_1" {
  subregion_name = "${var.region}a"
  ip_range       = "10.0.1.0/24"
  net_id         = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "private_subnet_1"
  }
}

resource "outscale_route_table_link" "private_subnet_1_private_route_table_link" {
    subnet_id      = outscale_subnet.private_subnet_1.subnet_id
    route_table_id = outscale_route_table.private_route_table.route_table_id
}

##### private subnet 2 ######

resource "outscale_subnet" "private_subnet_2" {
  subregion_name = "${var.region}b"
  ip_range       = "10.0.2.0/24"
  net_id         = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "private_subnet_2"
  }
}

resource "outscale_route_table_link" "private_subnet_2_private_route_table_link" {
    subnet_id      = outscale_subnet.private_subnet_2.subnet_id
    route_table_id = outscale_route_table.private_route_table.route_table_id
}

##### private subnet 3 ######

resource "outscale_subnet" "private_subnet_3" {
  # there is no c sub region in eu-west-2
  subregion_name = "${var.region}a"
  ip_range       = "10.0.3.0/24"
  net_id         = outscale_net.rancher_net.net_id
  tags {
    key   = "name"
    value = "private_subnet_3"
  }
}

resource "outscale_route_table_link" "private_subnet_3_private_route_table_link" {
    subnet_id      = outscale_subnet.private_subnet_3.subnet_id
    route_table_id = outscale_route_table.private_route_table.route_table_id
}



