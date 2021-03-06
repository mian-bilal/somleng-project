module "twilreapi_eb_solution_stack" {
  source             = "../modules/eb_solution_stacks"
  major_ruby_version = "${local.twilreapi_major_ruby_version}"
}

module "somleng_adhearsion_eb_solution_stack" {
  source = "../modules/eb_solution_stacks"
}

module "somleng_freeswitch_eb_solution_stack" {
  source = "../modules/eb_solution_stacks"
}

module "somleng_freeswitch_load_balancer_eb_solution_stack" {
  source = "../modules/eb_solution_stacks"
}
