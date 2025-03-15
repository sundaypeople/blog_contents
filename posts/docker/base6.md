---
title: docker composeについて
tags: ["docker","container"]
---
# docker composeとは

docker compose はコンテナを一斉に操作できるツール。

docker compose(docker-compose は非推奨) というコマンドを使えば、yamlファイルを使って、複数のコンテナを立ち上げたり操作したりできるようになる。

docker compsoe では作業ディレクトリがそのままプロジェクト名になる。なお、**このプロジェクト名に紐付いてネットワーク名やボリューム名も管理される**。

## docker-compose.yamlの読み方

```yaml
version: '3'
services:
  web:
    build: .
    ports:
      - "8080:80"

```

- 「version: ‘3’」 …Docker Composeファイル形式のバージョン指定です。バージョンによって細かな記法や挙動が異なります。現時点では「3」を指定しておくのが望ましいでしょう。ネットワークやボリュームも操作可能であり（バージョン2以降）、かつ、Swarmモードでのサービス実行にも対応しています。
- 「services:」 … コンテナとして実行するアプリケーション”サービス”の意味です。通常は、この中で、どのようにしてコンテナを実行するのか定義します。
- 「web」 … これは「web」という名称のサービスを定義しています。
- 「build: .」 … Dockerfileの位置を見つける。「.」（現在のディレクトリ）にあるDockerfileでDockerイメージをビルドします。
- 「ports:」 … このサービスが公開するポートの指定です。”ホスト側のポート番号:コンテナ内のポート番号”の順番です。

## Dockerfileをビルドする

イメージのビルドは、dockerだと、`docker image build`か`docker build`コマンドを使うが、docker compos は`docker compose build`を使う。ビルドするたび毎回タグを指定する必要がないため、複数のイメージを同時に扱うには大きいメリットがある。

## docker compose でプロジェクトを実行

`docker compose up -d`でプロジェクトを立ち上げる(-dはバックグラウンドで動く)

```
$ docker-compose up -d
Creating network "dockerhttpd_default" with the default driver
Creating dockerhttpd_web_1 ... done

```

このとき、出力結果の1行目を見ますと、自動的に専用のブリッジ・ネットワーク「dockerhttpd_default」が作成されています。これは、同一プロジェクト内のみで通信可能な、専用のブリッジ・ネットワークを自動的に作成しています。先ほどのYAMLファイルでポートのマッピングを「8080:80」と指定していたのを覚えていますでしょうか。

```
    ports:
      - "8080:80"

```

これは、「ホスト側のポート8080」を、このブリッジ・ネットワーク「dockerhttpd_defaultネットワーク内のポート80にマッピングする」という意味。なお、今回の例では実行するコンテナは1つですが、もしサービスとして複数のコンテナを実行する場合は、ブリッジネットワーク内で自動的にアクセスの負荷分散（ラウンドロビン方式）が処理されます。

それから、サービスが実行中かどうかはd`ocker-compose ps`コマンドを使います。

```
$ docker-compose ps
      Name              Command        State          Ports
-------------------------------------------------------------------
dockerhttpd_web_1   httpd-foreground   Up      0.0.0.0:8080->80/tcp
```

サービスの状態を示す「State」列が「Up」であれば実行中です。ブラウザから「http://<サーバのIPアドレス>」を表示すると、先ほどと同様にApacheの初期画面「It works!」が表示されましたでしょうか

## **起動したサービスを停止する**

一旦起動したサービスは停止したり、再起動したりできます。停止するには「docker-compose stop」です。

```
$ docker-compose stop
Stopping dockerhttpd_web_1 ... done

```

状態を調べるコマンドを実行すると、状態（State）が終了（Exit）となっているのが分かります。

## **サービスのデバッグ**

サービスが実行中の場合、コンテナ内で操作することができます。サービスとして実行中のコンテナに対し、プロセスを追加するには「docker-compose exec <サービス名> <コマンド>」を実行します。

今回は「web」というサービスを実行中です。このコンテナ内に「/bin/bash」プロセスを追加するには、次のように実行します。

```
# docker compose exec web /bin/bash
bash-5.0#

```

コンテナ内での操作は通常の「bash」ですので、「exit」で終了できます。

また、コンテナの中に入る必要がなければ`docker compose logs`で、サービスの標準出力を確認することもできます。

## **サービスの終了・削除**

使わなくなったサービスは終了・削除します。このとき、１つ１つ「docker kill」コマンドなどで止める必要がありません。「docker-compose down」コマンドを使うと、Dockerイメージの停止・削除と、このプロジェクトが使用するブリッジ・ネットワークも自動削除します。

```
$ docker-compose down -v
Stopping dockerhttpd_web_1 ... done
Removing dockerhttpd_web_1 ... done
Removing network dockerhttpd_default

```

# 参照

[Docker Compose入門 (1) ～アプリケーションをコンテナで簡単に扱うためのツール～  |  さくらのナレッジ](https://knowledge.sakura.ad.jp/21387/)

[docker-compose と docker サブコマンドの compose って結局どっち使えばいいのかという話 - おおくまねこ](https://www.maigo-name.tokyo/entry/2021/07/24/231528)