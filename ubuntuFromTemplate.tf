data "template_file" "ubuntu_userdata" {
  template = file("${path.module}/userdata/ubuntu.userdata")
  vars = {
    pubkey = file(var.ubuntu.public_key_path)
    username = var.ubuntu.username
  }
}


data "vsphere_virtual_machine" "ubuntu" {
  name          = var.ubuntu.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "ubuntu" {
  name             = var.ubuntu.name
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  network_interface {
                      network_id = data.vsphere_network.network.id
  }

  num_cpus = var.ubuntu.cpu
  memory = var.ubuntu.memory
  wait_for_guest_net_routable = var.ubuntu.wait_for_guest_net_routable
  guest_id = data.vsphere_virtual_machine.ubuntu.guest_id
  scsi_type = data.vsphere_virtual_machine.ubuntu.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.ubuntu.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.ubuntu.scsi_controller_scan_count

  disk {
    size             = var.ubuntu.disk
    label            = "ubuntu.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.ubuntu.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.ubuntu.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.ubuntu.id
  }

  vapp {
    properties = {
     hostname    = var.ubuntu.name
     public-keys = file(var.ubuntu.public_key_path)
     user-data   = base64encode(data.template_file.ubuntu_userdata.rendered)
   }
 }

  connection {
    host        = self.default_ip_address
    type        = "ssh"
    agent       = false
    user        = var.ubuntu.username
    private_key = file(var.ubuntu.private_key_path)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}
