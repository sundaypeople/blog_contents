---
title:# DockerFileの書き方
tags: ["docker","container"]
---
# DockerFileのメリット

実行コマンドを書いて管理することで、手順がそのままコード化された状態となり、**再現性も担保できる**ようになります。

# DockerFileコマンド

| コマンド | 概要 |
| --- | --- |
| FROM | DockerHubで公開中の元イメージを指定 |
| LABEL | 作成者情報・バージョンを指定 |
| COPY | イメージにファイルを追加 |
| ADD | イメージにファイルを追加。圧縮ファイル指定時は圧縮まで実行される。 |
| RUN | イメージをBuildする際に実行するコマンド |
| CMD | コンテナ起動の際に実行するコマンド |
| ENTRYPOINT | イメージ実行時に強要するコマンド |
| USER | RUN、CMD、ENTRYPOINTで指定のコマンドを実行するユーザー |
| WORKDIR | RUN、CMD、 ENTRYPOINT、ADD、COPYの際の作業ディレクトリ |
| ENV | 環境変数を設定 |
| ONBUILD | Build完了時に実行するコマンド |
| EXPOSE | イメージ利用者にポートを解放 |
| VOLUME | イメージ利用者に永続データが保存される場所を解放 |
| ARG | docker build時に指定する引数 |

## FROM

Dockerイメージを取得（docker pull）していなくても、**ローカルにない場合**は、Dockerイメージ作成の**コマンド実行時に自動で取得**してきます。

## CMDとRUN

RUN命令はイメージを作成するときに一度だけ実行されるもの。

主に、imageに**パッケージをインストール**するなどの処理が記述される。

**「-y」オプションを付けて、インストールするかどうか聞かれないようにしておきましょう。**

CMD命令はコンテナの起動するときに実行されるもの。

主に、**webサーバーの起動**などに使用されることが多い。

## CMDとENTRYPOINT

[ENTRYPOINTは「必ず実行」、CMDは「（デフォルトの）引数」 ‣ Pocketstudio.Net](https://pocketstudio.net/2020/01/31/cmd-and-entrypoint/)

**コンテナで必ず実行したいコマンドや引数を「ENTRYPOINT」命令に、デフォルトの引数や推奨パラメータを「CMD」命令に書いて使い分けられています。**

`docker build -t イメージ名前 DockerFileが保存してあるディレクトリ` をすることによってイメージを作ることができる。

# 注意点

## **Dockerfileを書く際のポイントや嵌りどころ、注意点について**

### **Dockerfileの各コマンドは、毎回コンテナを起動して実行している**

Dockerfileに書かれたコマンドは、毎回、中間的なDockerコンテナとして起動し、各コマンドを実行して各段階でDockerイメージを作成する、というのを繰り返します。この各段階のDockerイメージはレイヤーと呼ばれます。

そのため、一つ前のコマンド実行状態になっているわけではありません。例えば、以下のような記述があったとしましょう。

```
RUN cd /tmp           # ⑤
RUN touch test.txt    # ⑥

```

test.txtはどこに作成されるでしょうか。

それは、「/tmp」配下ではなく「/」配下に作成されます。明示的に指定しなければ、centos:7のDockerイメージの場合は、命令実行時の作業ディレクトリは「/」となっていて、Dockerfileの各種コマンドは「/」配下で実行されます。つまり、①の処理は中間的なDockerコンテナ上で「cd /tmp」は実行されますが、次の②の処理の際には新しく起動したコンテナで実行され、「/」配下で実行されます。もし、ディレクトリ移動してから実行したい場合などは、シェルの実行と同じように、「&&」などで連結して実行させればよいです。

また、実行ユーザや命令実行時の作業ディレクトリを変更したい場合には、Dockerfileで「[USER](http://docs.docker.jp/engine/reference/builder.html#user)」、「[WORKDIR](http://docs.docker.jp/engine/reference/builder.html#workdir)」を使用することで可能となります。

### **キャッシュを意識する**

Dockerビルドをする際、Dockerfileですでに実行済みのコマンドは、キャッシュが使用されます。そのため、あまり変わらない部分については、Dockerfileの最初のほうに書いておくことで、Dockerビルドの時間が短縮できます。ここで言う**「あまり変わらない部分」というのは、例えば基本必要となるパッケージのインストールなどです**。ADDやCOPYコマンドでビルド媒体などをコンテナ内にコピーする際、コピー元のファイルに変更があった場合は、キャッシュは使用されず、新しい媒体がコンテナ内にコピーされます。それ以降は、キャッシュは使用されずに、再度一つ一つDockerfileのコマンドが実行されます。

実際に試してみましょう。以下のように「Dockerfile_2」を作成してください。

```
FROM centos:7
RUN yum install -y java
RUN touch /tmp/test.txt     # 変更箇所
ADD files/apache-tomcat-9.0.6.tar.gz /opt/
CMD ["/opt/apache-tomcat-9.0.6/bin/catalina.sh", "run"]

```

「Dockerfile_2」を使用してDockerビルドを行ってみます。「-f」オプションで、使用するDockerfileを指定することができます。（「-f」オプションを使用しない場合は、デフォルトで「Dockerfile」が使用されます。）

```
# docker build -t tomcat:2 -f Dockerfile_2 .
Sending build context to Docker daemon 9.499MB
Step 1/5 : FROM centos:7
---> 2d194b392dd1
Step 2/5 : RUN yum install -y java
---> Using cache　　　・・・★
---> db67ba97aaff
Step 3/5 : RUN touch /tmp/test.txt
---> Running in dff4c625f388
Removing intermediate container dff4c625f388
---> e76913cfa2e2
Step 4/5 : ADD files/apache-tomcat-9.0.6.tar.gz /opt/
---> 63f1c3a602d2
Step 5/5 : CMD [ "/opt/apache-tomcat-9.0.6/bin/catalina.sh", "run" ]
---> Running in 2b9399b835a6
Removing intermediate container 2b9399b835a6
---> 566185029ac1
Successfully built 566185029ac1
Successfully tagged tomcat:2

```

「RUN yum install -y java」の部分までは、「Using cache（★の部分）」となり、キャッシュが使用されていることがわかります。最初に実行したときのJavaのインストール処理は表示されませんでしたね。

このように、変更がない部分は、以前作成されたレイヤー（中間的なDockerイメージ）が使用されるため、Dockerビルドの処理時間が短くなります。そのため、コマンドの実行順序を意識してDockerfileを書くとよいです。

**要するに、先に書いたものはキャッシュとして残って、変更を加えて下のものは全てもう一回実行されるから、できるだけ変更するものは後ろにあった方が効率がいいということ。**

### **なるべくまとめて実行する**

Dockerfileの各コマンドごとにレイヤーが作成されるので、その分Dockerイメージのサイズが大きくなってしまいます。そのため、なるべく1コマンドで実行できるものは、まとめて実行することをお薦めします。また、作成できるレイヤーには上限（128レイヤー）があるため、その意味でもなるべくまとめて実行したほうがよいですね。

例えば、yumインストールについても、一つ一つを個別のyumコマンドで実行するのではなく、一度のyumコマンドで複数インストールするとよいです。あとは、キャッシュとの兼ね合いから、どこまでまとめて実行するかを考えていくとよいと思います。

# 参照

[【Docker】Dockerfileとは｜書き方・コマンド一覧・イメージ作成手順を徹底解説](https://di-acc2.com/system/23152/)

[DockerfileのRUN命令とCMD命令の違い【Docker】](https://rara-world.com/dockerfile-run-cmd/#:~:text=RUN命令・CMD命令の,ときに実行されます。)