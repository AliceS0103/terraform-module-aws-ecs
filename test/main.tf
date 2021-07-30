
data "aws_availability_zones" "available" {}

resource "aws_subnet" "foo" {
  vpc_id  = "vpc-014f24814d9f0e5a3"
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "bar" {
  vpc_id  = "vpc-014f24814d9f0e5a3"
  cidr_block = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}
module "alb" {
  source = "github.com/lean-delivery/tf-module-aws-alb"

  project     = "debug-redcross"
  environment = "dev"

  vpc_id  = "vpc-014f24814d9f0e5a3"
  subnets  = [aws_subnet.foo.id, aws_subnet.bar.id]

  acm_cert_domain = "*.epm-ldi.projects.epam.com"
  root_domain     = "epm-ldi.projects.epam.com"

  alb_logs_lifecycle_rule_enabled = true
  alb_logs_expiration_days        = 5
}

module "ecs-fargate" {
  source = "../"

  project     = "Debug-RedCross"
  environment = "frontend"
  service     = "redcross"

  vpc_id  = "vpc-014f24814d9f0e5a3"
  subnets  = [aws_subnet.foo.id, aws_subnet.bar.id]

  alb_target_group_arn = module.alb.alb_target_group_arns[0]
  container_port       = "3000"

  container_cpu    = "512"
  container_memory = "1024"
  container_name   = "redcross-frontend"

  launch_type = "FARGATE"

  availability_zones = [data.aws_availability_zones.available.all_availability_zones]


}