terraform {
  required_providers {
    ns1 = {
      source = "ns1-terraform/ns1"
    }
    fastly = {
      source  = "fastly/fastly"
      version = ">= 5.11.0"
    }
  }
  required_version = ">= 0.13"
}

provider "ns1" {
  rate_limit_parallelism = 60
}

provider "fastly" {
}
