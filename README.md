# terraform

## tfenvのインストール

### tfenvのインストール
GitHubよりtfenvを$HOMEに取得
~~~
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
~~~

.bashrcに環境変数を設定
~~~
nano ~/.bashrc
~~~

.bashrc
~~~
export PATH="$HOME/.tfenv/bin:$PATH"
~~~

環境変数の反映
~~~
source ~/.bashrc
~~~

バージョンの確認
~~~
tfenv -v
~~~

インストール可能なバージョンを表示
~~~
tfenv list-remote
~~~

バージョンを指定してインストール
~~~
VERSION=1.0.0
tfenv install ${VERSION}
~~~

バージョンの切り替え
~~~
tfenv use ${VERSION}
~~~

auto completeの設定
~~~
terraform -install-autocomplete
~~~

tflintのインストール
~~~
curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
~~~


## aws認証情報をcommitしないためのgit secretsのインストールと設定
インストール
~~~
git clone https://github.com/awslabs/git-secrets ~/.git-secrets
cd ~/.git-secrets
sudo make install
git secrets -h
~~~

gitリポジトリに対して、git secrets --installを行うことで、git-secretsに対応させま
~~~
git secrets --install
~~~

AWSのIAMで利用されているクレデンシャルのパターンを弾く専用のオプションが用意されているので設定します。
~~~
git secrets --register-aws
~~~

## aws 認証情報の設定
認証情報を環境変数に設定するシェルスクリプトを作成
~~~
touch aws_credential.sh
~~~

ファイル内には認証情報を設定
~~~
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_DEFAULT_REGION="ap-northeast-1"
~~~

認証情報が設定されているかを確認。正常に設定されていればAWSのアカウントIDが表示される
~~~
aws sts get-caller-identity --query Account --output text
~~~

マージ済みブランチは削除する設定
~~~
git config --global fetch.prune true
~~~