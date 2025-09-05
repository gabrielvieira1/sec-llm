variable "project_name" {
  description = "Name of the project - used as prefix for naming resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
