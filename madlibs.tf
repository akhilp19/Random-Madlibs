terraform {
  required_version = ">= 0.15"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# variable "nouns" {
# description = "A list of nouns"
# type = list(string)
# }
# variable "adjectives" {
# description = "A list of adjectives"
# type = list(string)
# }
# variable "verbs" {
# description = "A list of verbs"
# type = list(string)
# }
# variable "adverbs" {
# description = "A list of adverbs"
# type = list(string)
# }
# variable "numbers" {
# description = "A list of numbers"
# type = list(number)
# }


variable "words" {
  description = "A word pool to use for Mad Libs"
  type = object({
    nouns      = list(string),
    adjectives = list(string),
    verbs      = list(string),
    adverbs    = list(string),
    numbers    = list(number),
  })

  # validation {
  #   condition     = length(var.words["nouns"]) >= 20
  #   error_message = "At least 20 nouns must be supplied."
  # }

}

variable "num_files" {
  default = 100
  type    = number
}

locals {
  uppercase_words = { for k, v in var.words : k => [for s in v : upper(s)] }
  templates       = tolist(fileset(path.module, "templates/*.txt"))
}

resource "random_shuffle" "random_nouns" {
    count = var.num_files
  input = local.uppercase_words["nouns"]
}
resource "random_shuffle" "random_adjectives" {
  count = var.num_files
  input = local.uppercase_words["adjectives"]
}
resource "random_shuffle" "random_verbs" {
  count = var.num_files
  input = local.uppercase_words["verbs"]
}
resource "random_shuffle" "random_adverbs" {
  count = var.num_files
  input = local.uppercase_words["adverbs"]
}
resource "random_shuffle" "random_numbers" {
  count = var.num_files
  input = local.uppercase_words["numbers"]
}

# output "mad_libs" {
#   value = templatefile("${path.module}/templates/alice.txt",
#     {
#       nouns      = random_shuffle.random_nouns.result
#       adjectives = random_shuffle.random_adjectives.result
#       verbs      = random_shuffle.random_verbs.result
#       adverbs    = random_shuffle.random_adverbs.result
#       numbers    = random_shuffle.random_numbers.result
#   })
# }

resource "local_file" "mad_libs" {
  count    = var.num_files
  filename = "madlibs/madlibs-${count.index}.txt"
  content = templatefile(element(local.templates, count.index),
    {
      nouns      = random_shuffle.random_nouns[count.index].result
      adjectives = random_shuffle.random_adjectives[count.index].result
      verbs      = random_shuffle.random_verbs[count.index].result
      adverbs    = random_shuffle.random_adverbs[count.index].result
      numbers    = random_shuffle.random_numbers[count.index].result
  })
}

data "archive_file" "mad_libs" {
  depends_on  = [local_file.mad_libs]
  type        = "zip"
  source_dir  = "${path.module}/madlibs"
  output_path = "${path.cwd}/madlibs.zip"
}

