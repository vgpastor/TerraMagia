module "this" {
  source      = "git::git@github.com:holaluz/kraken.git//aws/static_site"
  application = "st-step3-front-vgpastor"
  environment = "prod"
  group       = "st-group-vgpastor"
  subdomain   = "st-step3-front-vgpastor"

}
