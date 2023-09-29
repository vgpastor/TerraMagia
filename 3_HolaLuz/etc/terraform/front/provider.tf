provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Application    = var.application
      Solution       = var.solution
      Environment    = var.environment
      Owner          = var.owner
      DataOwner      = "undefined"     #mandatory in a future
      DataSteward    = "undefined"     #mandatory in a future
      DataOpsSteward = "undefined"     #mandatory in a future
      CIA            = "undefined"     #mandatory in a future
      CriticalLevel  = "undefined"     #mandatory in a future
      BudgetRef      = "undefined"     #mandatory in a future
      CreatedBy      = var.application #mandatory in a future
    }
  }
}
