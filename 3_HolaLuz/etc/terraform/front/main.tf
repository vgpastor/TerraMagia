module "this" {
    #https://github.com/holaluz/kraken/blob/main/aws/static_site/README.md
  source      = "git::git@github.com:holaluz/kraken.git//aws/static_site"
  application = var.application
  environment = var.environment
  group       = var.group
  subdomain   = var.subdomain

}
