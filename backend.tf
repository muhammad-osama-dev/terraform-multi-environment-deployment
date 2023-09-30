terraform {
  backend "s3" {
    bucket = "terraform-lab2"
    key = "terraform.tfstate"
    region = "eu-central-1"  
    dynamodb_table = "state-lock3"
  }
}