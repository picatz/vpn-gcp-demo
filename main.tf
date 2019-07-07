provider "google" {
  project     = "cloud-sdn-demo"
  credentials = "${file("account.json")}"
}

resource "google_compute_network" "first" {
  name  = "first"

  auto_create_subnetworks = false
}

resource "google_compute_network" "second" {
  name  = "second"

  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "first_subnetwork" {
  network = google_compute_network.first.name
  name    = "first"
  region  = "us-east1"

  ip_cidr_range = "10.10.15.0/24"

  depends_on = ["google_compute_network.first"]
}

resource "google_compute_subnetwork" "second_subnetwork" {
  network = google_compute_network.second.name
  name    = "second"
  region  = "us-east1"

  ip_cidr_range = "10.10.16.0/24"

  depends_on = ["google_compute_network.second"]
}

resource "google_compute_vpn_gateway" "first_gateway" {
  network = google_compute_network.first.name
  region  = google_compute_subnetwork.first_subnetwork.region
  name    = "first-gateway"
}

resource "google_compute_vpn_gateway" "second_gateway" {
  network = google_compute_network.second.name
  region  = google_compute_subnetwork.second_subnetwork.region
  name    = "second-gateway"
}

resource "google_compute_address" "first_vpn_static_ip" {
  name   = google_compute_network.first.name
  region = google_compute_subnetwork.first_subnetwork.region
}

resource "google_compute_address" "second_vpn_static_ip" {
  name   = google_compute_network.second.name
  region = google_compute_subnetwork.second_subnetwork.region
}

resource "google_compute_forwarding_rule" "first_fr_esp" {
  name        = "first-fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.first_vpn_static_ip.address
  target      = google_compute_vpn_gateway.first_gateway.self_link
  region      = google_compute_subnetwork.first_subnetwork.region
}

resource "google_compute_forwarding_rule" "second_fr_esp" {
  name        = "second-fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.second_vpn_static_ip.address
  target      = google_compute_vpn_gateway.second_gateway.self_link
  region      = google_compute_subnetwork.second_subnetwork.region
}

resource "google_compute_forwarding_rule" "first_fr_udp500" {
  name        = "first-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.first_vpn_static_ip.address
  target      = google_compute_vpn_gateway.first_gateway.self_link
  region      = google_compute_subnetwork.first_subnetwork.region
}

resource "google_compute_forwarding_rule" "second_fr_udp500" {
  name        = "second-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.second_vpn_static_ip.address
  target      = google_compute_vpn_gateway.second_gateway.self_link
  region      = google_compute_subnetwork.second_subnetwork.region
}

resource "google_compute_forwarding_rule" "first_fr_udp4500" {
  name        = "first-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.first_vpn_static_ip.address
  target      = google_compute_vpn_gateway.first_gateway.self_link
  region      = google_compute_subnetwork.first_subnetwork.region
}

resource "google_compute_forwarding_rule" "second_fr_udp4500" {
  name        = "second-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.second_vpn_static_ip.address
  target      = google_compute_vpn_gateway.second_gateway.self_link
  region      = google_compute_subnetwork.second_subnetwork.region
}

resource "google_compute_vpn_tunnel" "first_to_second" {
  name          = "first-to-second"
  region        = google_compute_subnetwork.first_subnetwork.region
  peer_ip       = google_compute_address.second_vpn_static_ip.address
  shared_secret = "supersecretpassword123"

  target_vpn_gateway = google_compute_vpn_gateway.first_gateway.self_link

  local_traffic_selector  = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    "google_compute_forwarding_rule.first_fr_esp",
    "google_compute_forwarding_rule.first_fr_udp500",
    "google_compute_forwarding_rule.first_fr_udp4500",
    "google_compute_forwarding_rule.second_fr_esp",
    "google_compute_forwarding_rule.second_fr_udp500",
    "google_compute_forwarding_rule.second_fr_udp4500",
  ]
}

resource "google_compute_vpn_tunnel" "second_to_first" {
  name          = "second-to-first"
  region        = google_compute_subnetwork.second_subnetwork.region
  peer_ip       = google_compute_address.first_vpn_static_ip.address
  shared_secret = "supersecretpassword123"

  target_vpn_gateway = google_compute_vpn_gateway.second_gateway.self_link

  local_traffic_selector  = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    "google_compute_forwarding_rule.first_fr_esp",
    "google_compute_forwarding_rule.first_fr_udp500",
    "google_compute_forwarding_rule.first_fr_udp4500",
    "google_compute_forwarding_rule.second_fr_esp",
    "google_compute_forwarding_rule.second_fr_udp500",
    "google_compute_forwarding_rule.second_fr_udp4500",
  ]
}

resource "google_compute_route" "first_to_second" {
  name       = "first-to-second"
  network    = google_compute_subnetwork.first_subnetwork.name
  dest_range = google_compute_subnetwork.second_subnetwork.ip_cidr_range

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.first_to_second.self_link
}

resource "google_compute_route" "second_to_first" {
  name       = "second-to-first"
  network    = google_compute_subnetwork.second_subnetwork.name
  dest_range = google_compute_subnetwork.first_subnetwork.ip_cidr_range

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.second_to_first.self_link
}


resource "google_compute_firewall" "allow_icmp_and_ssh_to_first" {
  name    = "allow-icmp-and-ssh-to-first"
  network = google_compute_subnetwork.first_subnetwork.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  depends_on = ["google_compute_network.first"]
}


resource "google_compute_firewall" "allow_icmp_and_ssh_to_second" {
  name    = "allow-icmp-and-ssh-to-second"
  network = google_compute_subnetwork.second_subnetwork.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  depends_on = ["google_compute_network.second"]
}

resource "google_compute_instance" "first_vm" {
  name         = "first-vm"
  machine_type = "f1-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image =  "ubuntu-os-cloud/ubuntu-1804-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.first_subnetwork.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  depends_on = ["google_compute_subnetwork.first_subnetwork"]
}

resource "google_compute_instance" "second_vm" {
  name         = "second-vm"
  machine_type = "f1-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image =  "ubuntu-os-cloud/ubuntu-1804-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.second_subnetwork.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  depends_on = ["google_compute_subnetwork.second_subnetwork"]
}