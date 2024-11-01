# Number of instances to create
variable "instance_count" {
  description = "The number of EC2 instances to create"
  type        = number
  default     = 3  # Set a default value here if desired
}

# Public SSH key for the instances
variable "public_key" {
  description = "The public SSH key to use for the instances"
  type        = string
  default     = "ssh-ed25519 AAAA... your_public_key_here"
}
