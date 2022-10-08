variable "vpc_ciddr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}
variable "azs" {
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_ciddr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "iac_vpc"
  }
}

# public subnet
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "iac_public_subnet_${count.index + 1}"
  }
}

# private subnet
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]
  tags = {
    Name = "iac_private_subnet_${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "iac_internet_gateway"
  }
}

# Route Table (public)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "iac_public_route_table"
  }
}

# Route (public)
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# Route Table Association (public)
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table (private)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "iac_private_route_table"
  }
}

# Route Table Association (private)
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# S3のendpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}

# S3のendpointとprivateサブネットのroute tableと紐づけ
resource "aws_vpc_endpoint_route_table_association" "private_to_s3_endpoint" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private.id
}

# VPCにendpoint用のセキュリティグループを追加
resource "aws_security_group" "vpc_endpoint" {
  name   = "vpc_endpoint_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
}

# ecr用のendpointの作成
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

# CloudWatchのendpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

# # SecretManagerのendpoint
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.ap-northeast-1.ssm"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private.*.id
#   security_group_ids  = [aws_security_group.vpc_endpoint.id]
#   private_dns_enabled = true
# }

# endpoint経由でECR,S3,CloudWatchにアクセスするため、料金の高いNatGatewayは使用しない
# # Elasti IP
# resource "aws_eip" "main" {
#   count = length(var.public_subnet_cidrs)
#   vpc   = true

#   tags = {
#     Name = "iac_eip_${count.index + 1}"
#   }
# }

# # NAT Gateway
# resource "aws_nat_gateway" "nat_gateway" {
#   count = length(var.public_subnet_cidrs)

#   subnet_id     = aws_subnet.public[count.index].id # NAT Gatewayを配置するSubnetを指定
#   allocation_id = aws_eip.main[count.index].id      # 紐付けるElasti IP

#   tags = {
#     Name = "iac_natgateway_${count.index + 1}"
#   }
# }

