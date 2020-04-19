# Faxocr docker image (preview release)

## Faxocr system について
Faxocr system は、Ruby on Rails の Web application と、Cron による定期的なFAXメール送受信、MySQL によるデータベースから構成されています。
## 簡単な動作確認のための構築方法
ここで紹介する方法は、開発や動作確認を行うための手順になります。実際の運用ではKubernetesなどで動かすことをお勧めします。
### Docker のインストール（初回のみ）
以下のサイトよりDockerのインストールを行ってください。

- Docker Desktop for Windows  
https://hub.docker.com/editions/community/docker-ce-desktop-windows/  
- Docker Desktop for Mac  
https://hub.docker.com/editions/community/docker-ce-desktop-mac/  
- Ubuntu  
https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-engine---community-1  

### ネットワークの作成（初回のみ）
```
docker network create some-network
```
### MySQL コンテナ起動
dockerhub から mysql:5.6 を使用します。必ず 5.6 を使用してください。
```
docker run --name some-mysql --network some-network -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:5.6 --character-set-server=utf8 --collation-server=utf8_unicode_ci
```
### Faxocr コンテナ起動
以下のコマンドは Faxocr がインストールされたコンテナの起動となります。Web Application や Cron は起動しません。
```
docker run -ti --network some-network -p 3000:3000 -e MYSQL_ROOT_PASSWORD=my-secret-pw -e MYSQL_HOST=some-mysql -e SERVER_TYPE=docker -e POP3HOST=outlook.office365.com -e POP3PORT=995 -e POP3USER=xxxxxxxx@outlook.com -e POP3PASSWORD=xxxxx -e POP3SSL=true -e FAXSENDTYPE=messageplus -e SMTPHOST=smtp.office365.com -e SMTPPORT=587 -e SMTPAUTH=true -e SMTPUSER=xxxxxxxx@outlook.com -e SMTPPASSWORD=xxxxx -e SMTPSSL=true -e SMTPFROM=xxxxxxxx@outlook.com -e FAXTODOMAIN=mailfax.everynet.jp -e FAXFROMADDR=xxxxxxxx@outlook.com -e FAXUSER= -e FAXPASS= kekekekenta/faxocr
```
Ruby on Railsの Web Application を起動する場合、以下のコマンドで実行してください。実行したら Docker をホストするデスクトップのブラウザで、 http://localhost:3000/faxocr/ にアクセスしてください。初期管理者は admin、初期パスワードは admin です。
```
cd /home/faxocr/rails
rake db:create
rake db:migration
rake db:seed
script/server
```
#### その他起動方法について
実際の運用では、共有ボリュームを用意して、Faxocrコンテナを、Web Application用とCron用に分けて起動することをお勧めします。なお、これらの設定は、環境変数などで行います。

Ruby on Rails Web Applicaiton が使用する MySQL の接続設定
- MYSQL_HOST  
使用するMySQLコンテナの名前を設定します。
- MYSQL_ROOT_PASSWORD  
MySQLにアクセスするためのパスワードを設定します。

以下のFaxocr設定を行う場合は、SERVER_TYPE環境変数をdockerとして下さい。
- SERVER_TYPE  
docker と設定する

Faxocr Fax受信時に使用されるメールサーバの POP3 インタフェース設定
- POP3HOST  
受信時にFaxサービスからTIFF画像が送られてくるメールサーバのPOP3サーバの指定
- POP3PORT  
POP3HOSTのPOP3インタフェースのポート番号
- POP3USER  
POP3HOSTのユーザ名
- POP3PASSWORD  
POP3HOSTのパスワード
- POP3SSL  
POP3HOSTにSSL接続する場合はtrueを入力。SSL不必要な場合はfalse。

Faxocr Fax送信時に使用されるメールサーバのSMTPインタフェース設定
- SMTPHOST  
FAX送信時に使用するメールサーバのSMTPサーバホストの指定
- SMTPPORT  
SMTPHOSTのSMTPインターフェースのポート番号
- SMTPAUTH  
SMTPHOSTにSMTP認証が必要な場合はtrueを入力。認証が不必要な場合はfalse。
- SMTPUSER  
SMTPHOSTのSMTPユーザ名
- SMTPPASSWORD  
SMTPHOSTのパスワード
- SMTPSSL  
SMTPHOSTにSSL接続する場合はtrueを入力。SSL不必要な場合はfalse
- SMTPFROM  
メール送信時のFromアドレス

Fax送信時に使用されるFaxサービス向けのメール設定
- FAXTODOMAIN  
FAX送信する宛先FAXサービスのメールのドメイン名
- FAXFROMADDR  
FAX送信する送信元アドレス
- FAXUSER  
認証用ユーザ名（FAXサービスが NTT Communications iFAX の場合に使用される）
- FAXPASS  
認証用パスワード（FAXサービスが NTT Communications iFAX の場合に使用される）

例：
Fax送受信に使うメールサーバとしてhotmailを利用。Faxサービスは、faximoを利用  
```
SERVER_TYPE=docker
POP3HOST=pop3.live.com
POP3PORT=995
POP3USER=xxxxxxxxxxx@hotmail.com
POP3PASSWORD=xxxxxxxxxxx
POP3SSL=true

SMTPHOST=smtp.live.com
SMTPPORT=25
SMTPAUTH=true
SMTPUSER=xxxxxxxxxxx@hotmail.com
SMTPPASSWORD=xxxxxxxxxxx
SMTPSSL=true
SMTPFROM=xxxxxxxxxxx@hotmail.com

FAXTODOMAIN=ml.faximo.jp
FAXFROMADDR=xxxxxxxxxxx@hotmail.com
FAXUSER=
FAXPASS=
```
