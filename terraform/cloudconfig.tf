locals {
   minecraft_image = "${var.minecraft_docker_image_id}"
   minecraft_data  = "data-${var.minecraft_type}"
   device =          "/dev/nvme1n1"
}
data "aws_caller_identity" "current_" {}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.users.rendered}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.docker.rendered}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.minecraft.rendered}"
    merge_type = "list(append)+dict(recurse_array)+str()"
  }
}

#              image: ${var.minecraft_docker_image_id}

#      - docker run --name restore_backup -e AWS_DEFAULT_REGION=${var.aws_region} -e S3_BUCKET=${var.bucket_name} -v /srv/minecraft-spot/data:/data ${var.tools_docker_image_id} restore_backup.py
#      - docker run --name set_route -e AWS_DEFAULT_REGION=${var.aws_region} -e FQDN=${var.minecraft_subdomain}.${replace(data.aws_route53_zone.zone.name, "/[.]$/", "")} -e ZONE_ID=${var.hosted_zone_id} ${var.tools_docker_image_id} set_route.py
data "template_file" "minecraft" {
  template = <<-EOF
    #cloud-config
    output: {all: ">> /var/log/cloud-init-output.log"}
    packages:
      - python3-pip
    runcmd:
      - mkdir -p /srv/minecraft-spot
      - ln -s /var/mqm/${local.minecraft_data} /srv/minecraft-spot/data
      - chmod -R a+rwX /srv/minecraft-spot/data
      - $(aws ecr get-login --no-include-email --registry-ids ${data.aws_caller_identity.current_.account_id} --region eu-west-1)
      - docker-compose -f /srv/minecraft-spot/docker-compose.yaml up -d
    write_files:
      - path: /srv/minecraft-spot/docker-compose.yaml
        permissions: "0644"
        owner: root
        content: |
          version: "3"
          services:
            minecraft:
              container_name: minecraft
              image: ${local.minecraft_image}
              restart: on-failure
              ports:
                - 25565:25565
              volumes:
                - /srv/minecraft-spot/data:/data
              environment:
                EULA: "TRUE"
                MAX_RAM: "3G"
                VERSION: "1.14.4"
                TYPE: "${var.minecraft_type}"
                WHITELIST: "${var.minecraft_whitelist}"
                OPS: "${var.minecraft_ops}"
                ENABLE_RCON: "true"
            check_termination:
              container_name: check_termination
              image: ${var.tools_docker_image_id}
              command: check_termination.py
              restart: on-failure
              volumes:
                - /srv/minecraft-spot/data:/data
                - /var/run/docker.sock:/var/run/docker.sock
              environment:
                AWS_DEFAULT_REGION: ${var.aws_region}
                S3_BUCKET: ${var.bucket_name}
                LIFECYCLE_HOOK_NAME: "${var.name_prefix}minecraft-terminate"
                BACKUP_COMMAND: "${var.ftb_backup_command}"
                BACKUP_INDEX_PATH: ${var.ftb_backup_index_path}
                BACKUPS_PATH: ${var.ftb_backups_path}
            check_players:
              container_name: check_players
              image: ${var.tools_docker_image_id}
              command: check_players.py
              restart: on-failure
              volumes:
                - /var/run/docker.sock:/var/run/docker.sock
              environment:
                AWS_DEFAULT_REGION: ${var.aws_region}
                GRACE_PERIOD: "${var.no_user_grace_period}"
    EOF
}

data "template_file" "users" {
  template = <<-EOF
    #cloud-config
    output: {all: ">> /var/log/cloud-init-output.log"}
    users:
      - default
      - name: ${var.username}
        groups: docker,wheel
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: true
        ssh-import-id: None
        ssh-authorized_keys:
          - ${var.pub_ssh_key}
    EOF
}

data "template_file" "docker" {
  template = <<-EOF
    #cloud-config
    output: {all: ">> /var/log/cloud-init-output.log"}
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - python3-pip
    runcmd:
      - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
      - apt-get update -y
      - apt-get install -y docker-ce
      - pip3 install awscli
      - aws configure set region ${var.aws_region}
      - aws ec2 attach-volume --device /dev/xvdf --instance-id $(curl http://169.254.169.254/latest/meta-data/instance-id) --volume-id  "${var.volume_id}"
      - mkdir -p /var/mqm/
      - while [ ! -b $(readlink -f ${local.device} ) ]; do echo "waiting for device ${local.device}"; sleep 5 ; done
      - blkid $(readlink -f ${local.device}) || mkfs -t ext4 $(readlink -f ${local.device})
      - grep -q "^$(readlink -f ${local.device}) /var/mqm " /proc/mounts || mount ${local.device} /var/mqm
      - mkdir -p /var/mqm/${local.minecraft_data}
      - curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-linux-x86_64 > /usr/bin/docker-compose
      - echo "attach esb volmune"
      - chmod +x /usr/bin/docker-compose
    EOF
}
