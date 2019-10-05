resource "aws_ecr_repository" "minecraft_ecr" {
  name = "minecraft"
}

resource "aws_ecr_repository" "minecraft_tool_ecr" {
  name = "minecraft_tool"
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

output "ecr_tool_arn" {
 value = "${aws_ecr_repository.minecraft_tool_ecr.arn}"
}

output "ecr_tool_registry_id" {
 value = "${aws_ecr_repository.minecraft_tool_ecr.registry_id}"
}

output "ecr_tool_repository_url" {
 value = "${aws_ecr_repository.minecraft_tool_ecr.repository_url}"
}

