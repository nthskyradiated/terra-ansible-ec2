variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080

    validation {
        condition = var.server_port >= 8000 && var.server_port <= 8999
        error_message = "The server_port value must be between 8000 and 8999."
    }

    sensitive = false
}