# Ubuntu Server Noble (24.04.x) for Hadoop
# ---
# Packer Template to create an Ubuntu Server (Noble 24.04.x) for Hadoop on Proxmox
packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "proxmox_node" {
    type = string
}

variable "proxmox_vm_id" {
    type = string
}

variable "proxmox_vm_name" {
    type = string
}

variable "proxmox_ssh_username" {
    type = string
}
variable "proxmox_ssh_password" {
    type = string
    sensitive = true
}

variable "vm_disk_size" { type = string }
variable "vm_cpu_cores" { type = string }
variable "vm_mem_size"  { type = string }
variable "vm_iso_file"  { type = string }

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-noble-hadoop" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username    = "${var.proxmox_api_token_id}"
    token       = "${var.proxmox_api_token_secret}"

    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    # VM General Settings
    node                 = "${var.proxmox_node}"
    vm_id                = "${var.proxmox_vm_id}"
    vm_name              = "${var.proxmox_vm_name}"
    # template_description = "ubuntu noble hadoop base image"

    # VM OS Settings
    # Local ISO File
    boot_iso {
        type     = "scsi"
        iso_file = "${var.vm_iso_file}"
        #iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
        unmount  = true
    }

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size    = "${var.vm_disk_size}"
        #disk_size    = "64G"
        storage_pool = "local-lvm"
        type         = "virtio"
    }

    # VM CPU Settings
    cores = "${var.vm_cpu_cores}"
    #cores = "16"

    # VM Memory Settings
    memory = "${var.vm_mem_size}"
    #memory = "32768"

    # VM Network Settings
    network_adapters {
        model    = "virtio"
        bridge   = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init              = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
	"autoinstall<wait>",
	" cloud-config-url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/user-data<wait>",
	" ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
        "<wait5><f10><wait>"
    ]

    boot                    = "c"
    boot_wait               = "10s"
    communicator            = "ssh"

    # PACKER Autoinstall Settings
    http_directory          = "http"
    # (Optional) Bind IP Address and Port
    http_bind_address       = "192.168.0.222"
    http_port_min           = 8802
    http_port_max           = 8802

    ssh_username = "${var.proxmox_ssh_username}"
    ssh_password = "${var.proxmox_ssh_password}"

    # Raise the timeout, when installation takes longer
    ssh_timeout  = "30m"
    ssh_pty      = true
}

# Build Definition to create the VM Template
build {

    name    = "ubuntu-noble-hadoop"
    sources = ["source.proxmox-iso.ubuntu-noble-hadoop"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source      = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}
