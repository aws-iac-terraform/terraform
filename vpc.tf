variable "azs" {
  description = "サブネットを配置するAZ。regionと対応させる必要あり"
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "subnet_cidrs" {
  description = "作成するサブネットCIDR一覧"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  # length関数でsubnet_cidrsの数を取得し、その数ぶん繰り返し実行する
  count = length(var.subnet_cidrs)

  vpc_id = aws_vpc.main.id

  # 現在の実行回数をcount.indexで取得でき、それをインデックスとして配列から値を取得する
  availability_zone = var.azs[count.index]
  cidr_block        = var.subnet_cidrs[count.index]
}