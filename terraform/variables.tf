variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "instances" {
  type = map(object({
    dns = string
    ip  = string
    kp  = string
  }))
}
