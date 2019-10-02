resource "aws_ecr_repository" "minecraft_ecr" {
  name = "minecraft"
}
output "ecr_arn" {
 value = "${aws_ecr_repository.minecraft_ecr.arn}"
}

output "ecr_registry_id" {
 value = "${aws_ecr_repository.minecraft_ecr.registry_id}"
}

output "ecr_repository_url" {
 value = "${aws_ecr_repository.minecraft_ecr.repository_url}"
}

