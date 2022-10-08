resource "aws_ecr_repository" "sample-app" {
  name = "sample-app"
  # 検証中はコメントアウト
  #   image_tag_mutability = "MUTABLE"
  #   image_scanning_configuration {
  #     scan_on_push = true
  #   }

}

# Null Resource
resource "null_resource" "sample-app" {
  triggers = {
    // MD5 チェックし、トリガーにする
    file_content_md5 = md5(file("../sample-app/dockerbuild.sh"))
  }

  provisioner "local-exec" {
    // ローカルのスクリプトを呼び出す
    command = "sh ../sample-app/dockerbuild.sh"

    // スクリプト専用の環境変数
    environment = {
      AWS_REGION     = "ap-northeast-1"
      AWS_ACCOUNT_ID = data.aws_caller_identity.self.account_id
      REPO_URL       = aws_ecr_repository.sample-app.repository_url
      CONTAINER_NAME = "sample-app"
    }
  }
}
