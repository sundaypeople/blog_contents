---
title: dockerの仕組み
tags: ["docker","container"]
---
# dockerのコンテナ起動までの流れ

---

![](https://o2mamiblog.com/wp-content/uploads/2022/07/Docker-1_page-0001-768x432.jpg)

大まかな流れは**dockerエンジンに私たちがコマンドを送り**、DockerFIleでイメージを作成(わざわざ0からイメージ作るのはめんどくさいので、dockerhubからイメージを引っ張ってきていい感じに改良する、**あとDockerFileを使わなくてもイメージは作れる**)、そこから**コンテナを作って、コンテナを稼働。**

**大まかな流れは**こんな感じ

では細かく見ていこう。

## dockerエンジンって何？

---

![](https://docs.docker.jp/v1.12/_images/engine-components-flow.png)

> Docker Engine は３つの主なコンポーネント（構成要素）を持つ**クライアント・サーバ型アプリケーション**です。https://docs.docker.jp/v1.12/engine/understanding-docker.html
> 

- クライアント・サーバ型とは？
    
    普通のwebサーバーを思い出せば良い。クライアント(ブラウザ)がwebサーバにアクセスして、そこからwebページを取ってくる。これと同じ
    

### dockerデーモン(サーバ)

dockerデーモンは、**dockerオブジェクトの作成・管理**をする。dockerデーモンがサーバで長時間稼働するプログラムでそれはデーモンプロセスと呼ばれる。(dockerdコマンド)

dockerオブジェクトとは、イメージ、ネットワーク、データ、ボリュームなどの様々なdockerで使うもの。

dockerの根幹だと思えば良い

### docker engine API(REST API)

プログラムとデーモンとの間での通信方法を定義し、**何をなすべきなのかを指示する**。Docker CLIの中継役としても存在する。(この認識で合ってるかどうか微妙)

REST APIなので`curl` コマンドを叩くことができる。

- 本当なのか試してみる
    1. `sudo docker version`をコマンドで打ち、API　version:の部分を確認
    2. 適当なコンテナを立ち上げる。`docker compose up -d`
    3. `sudo curl --unix-socket /var/run/docker.sock http:/v"APIのヴバージョン"/containers/json`’と打つと、何かレスポンスがあれば成功。

> **デーモンとクライアントでの API バージョン相違**
> 
> 
> Docker デーモンとクライアントのバージョンは、常に同一でなければならないというわけでもありません。 ただし以下の点に留意しておく必要があります。
> 
> - クライアントよりもデーモンのバージョンの方が新しい場合、デーモンに新たな機能があってもクライアントにはわかりません。 また廃止決定となった API エンドポイントもわかりません。
> - デーモンよりもクライアントのバージョンの方が新しい場合、デーモンがわかっていない API リクエストエンドポイントをクライアントが送信することがありえます。

- REST APIとは
    
    [REST API（RESTful API）とは](https://www.infraexpert.com/study/sdn09.html)
    
    > API（Application Programming Interface）とは、ソフトウェア同士が互いに情報をやりとりするのに使用するインターフェースの仕様のことです。
    > 
    
    > REST APIは、REST(Representational State Transfer)の原則に基づいて設計されたAPIのことです。Webシステムを外部から利用するためのAPIであることから、REST APIはWeb APIの1つだと言えます。　REST APIでは、HTTPで定義するGET、POST、PUT、DELETEなどのリクエストでデータを操作します。
    > 
    
    > ◆　REST - 4つの設計原則　RESTの原則は、大きく以下の4つに集約できます。※ より詳細に分類する場合は6つの原則と言えます。　
    
    原則1：ステートレスなクライアント/サーバプロトコル
    HTTPメッセージの全てがリクエストを理解するための必要な情報を含んでいることから、HTTP通信を　行うクライアントもサーバもメッセージ間におけるセッションの状態を記憶している必要がありません。　※ ステートレスと表現していますが、実際には Cookie などを使用しセッション状態を管理しています。　
    
    原則2：リソースを一意なURIにより識別される　RESTfulなシステムでは全てのリソース（情報）はURI（Uniform Resource Identifier）で表現される　ユニークなアドレスを持ちます。　
    
    原則3：HTTPメソッドで操作方法を表現した統一されたインターフェース　リソースを操作するメソッドは、HTTPで定義されている "GET"、"POST"、"PUT"、"DELETE" などを　使用します。つまり、情報を操作する命令体系があらかじめ定義されています。　
    
    原則4：アプリケーション情報と状態遷移の両方を扱えるハイパーメディアの使用リソースを様々な形式（HTML、XML、JSON、バイナリ）で表現できるようにします。また、関連する　データはハイパーメディア（リンク）としてデータに含めることができます。
    
    上述のRESTの4つの原則を以降で詳細に解説していきます。
    > 
    

### Docker CLI

コマンドを発行して、docker engin APIとdockerデーモンの対話に使用する。(dockerコマンド)

docker cliは**docker engine apiにアクセスして、そこからdockerデーモンをコントロール**している。

私たちが、dockerコマンドを打って操作しているのは、これのことだ。Docker CLIが私たちのコマンドを解釈してdocker APIまたDockerデーモンに受け渡してくれる。(合ってるか微妙)

![](https://docs.docker.jp/v1.12/_images/architecture.png)

## docker イメージって何？

---

**「イメージはコンテナの元であり、イメージからコンテナを起動する」**

![](https://o2mamiblog.com/wp-content/uploads/2022/07/Docker-1_page-0001-768x432.jpg)

> Dockerイメージ（images）とは、Dockerコンテナの動作環境となるテンプレートファイルです。Dockerイメージには、OSやアプリケーションからアプリケーションの実行に使われるコマンド、メタデータまで含まれます。

Dockerコンテナを実行するためには、Dockerイメージが必要です。Dockerイメージは、クラウド上のレジストリ「Docker Hub」からダウンロードして使うことができる他、自分で作って使うこともできます。
> 

## docker イメージ とdocker コンテナの違い

> Dockerを使い始めたときに、よく混同されるのがDockerイメージとDockerコンテナです。前項で述べたように、Dockerイメージは**Dockerコンテナを動作させるのに使うテンプレートファイル**を指します。
それに対し、Dockerコンテナは**テンプレートファイルに基づいてアプリケーションを実行する環境・インスタンス**です。1つのDockerイメージを実行すると1つのDockerコンテナが作成されます。

そうして実行環境であるDockerコンテナが作成されると、アプリケーションの実行が開始されるわけです。より厳密にいうとDockerイメージを走らせる（run）ことによって実行環境であるDockerコンテナが生成され、アプリケーションが実行されます。
> 

![](https://www.kagoya.jp/howto/wp-content/uploads/differencedockerimg.png.webp)

## dockerイメージの仕組み・構造

![](https://www.kagoya.jp/howto/wp-content/uploads/f5824116f594d2f5745c675e2424485d.png.webp)

> Dockerイメージは、複数のイメージレイヤによって構成されています。1つのレイヤにつきOSやミドルウェアが1つインストールされており、これらレイヤは**読み取り専用で編集できません**。

Dockerイメージからコンテナが生成されたあとにミドルウェアをインストールした場合、新しいレイヤが追加されます。新しく追加されたレイヤについては、編集が可能です。またDockerイメージに対しコンテナレイヤが積み重なったものを基に、新たなイメージを作成することもできます。
> 

要は、dockerイメージはもうすでに編集不可。ただ、その上になんでも乗っけれるということ。

- 例
    
    ubuntuのイメージを使ってlamp環境のイメージを作る際、ubuntuのイメージはこの時点でもうすでに編集不可。ubuntuのイメージからコンテナを生成し、ubuntuの上にapache,mariadb,phpを入れる。そして、lamp環境の作ったコンテナをイメージ化する。こうすると、ubuntuの環境のイメージは編集不可になる。
    

dockerイメージの作り方は、DockerFileを編集するか、docker commitを使う方法がある。

DockerFileとは、dockerイメージを生成する手順書みたいなもの。書き方や詳しいことは違うページに記述する

dockerイメージを生成するには結構難しそう（https://knowledge.sakura.ad.jp/2226/）

## DockerFileとは

---

dockerイメージを作る際の**手順書**のようなもの。わざわざコンテナに入って、イメージを作るのがめんどくさいから。

**書き方や詳しいことは違うページに記述する。**

## docker hubとは

---

dockerイメージをインターネット上における場所。docker公式のイメージや、他人が作ったイメージを使える。また、自分も公開(パブリックリポジトリ)できる。**もちろん、非公開(プライベートリポジトリ)で使える。**

チームなどの複数人で使いたい場合、**有料プラン**を利用しなければならないが、学校で使う場合5人とかそのレベルなので、**DockerFIleを共有すれば問題ない。**

なので、とりあえず**無料プラン**でいい。

**git hubの仕組みなどを学ぶとより理解しやすいかもね。**

## docker コンテナって何？

---

dockerコンテナはdockerイメージをベースに作られた仮想環境のこと。

**注意:dockerコンテナは破棄するとデータは消えてしまいます。例えば、コンテナを起動してmariaDBに書き込んでも、コンテナを破棄すると最初の状態に戻ってします。それを回避するのがdockerボリュームです**

## dockerボリュームって何？

---

コンテナ内部にデータを置くと、コンテナを破棄するとデータは全て消えてしまう。それを防ぐために、外側に置く場所をボリュームという。

ボリュームには二種類ある。ホストのディレクトリと、dockerのリソースとしてのボリューム。

要は、ホストにあるものをそのままマウントしたものとと、docker create volumeで作ったボリューム

**data volume container**というものがあるが、これはdockerのオプションに—volume-fromを逆に利用したやり方だと推測する。—volume-fromで指定したコンテナと同じ位置に同じものをマウントできる。多数のコンテナを同じ位置にマウントしたい場合、data用のコンテナを一つ用意して、それと同じようにマウントさせていく方法。volumeを制作するだけだと、マウント位置を書かなければならないので、data volume container が使われる。（現在調査中）

`docker volume inspect` で保存場所を確認できる

Docker Desktop for Macを使っている場合、Docker環境はHyperKitというVM(バーチャルマシン)上で実行されているためMacからは参照できないようです。

nsenter1というコマンドでVMに入って確認することができます。

また、詳しくは違うページに書く。

実は 17.06 から `--mount` オプションが追加され、こちらが公式で推奨されている。

## docker compose って何？

---

> Compose とは、複数のコンテナを定義し実行する Docker アプリケーションのためのツールです。Compose においては YAML ファイルを使ってアプリケーションサービスの設定を行います。コマンドを１つ実行するだけで、設定内容に基づいたアプリケーションサービスの生成、起動を行います。Compose の機能一覧については、 [機能一覧](https://docs.docker.jp/compose/overview.html#compose-features) をご覧ください。https://docs.docker.jp/compose/overview.html
> 

**要は複数のコンテナを操作するためのもの**

# docker engineの仕組みについての参考

---

[【図解】Dockerの全体像を理解する -前編- - Qiita](https://qiita.com/etaroid/items/b1024c7d200a75b992fc)

[【初心者向け・図解】Dockerとは？現役エンジニアがわかりやすく解説](https://o2mamiblog.com/docker-beginner-1/)

[Docker 概要 — Docker-docs-ja 1.12.RC2 ドキュメント](https://docs.docker.jp/v1.12/engine/understanding-docker.html)

[REST API（RESTful API）とは](https://www.infraexpert.com/study/sdn09.html)

[Docker Engine API について - Qiita](https://qiita.com/doz13189/items/9ee8fda335605567b832)

[Docker Engine API を用いた開発](https://matsuand.github.io/docs.docker.jp.onthefly/engine/api/)

[Docker Engineとは何か](https://zenn.dev/ryoatsuta/articles/64dcc2e2b4e0cf)

# docker imageの仕組みについての参考

---

↓わかりやすくていい

[【入門】Dockerイメージ（images）の仕組みとコマンド一覧まとめ - カゴヤのサーバー研究室](https://www.kagoya.jp/howto/cloud/container/dockerimage/)

[【図解】Dockerの全体像を理解する -前編- - Qiita](https://qiita.com/etaroid/items/b1024c7d200a75b992fc)

[【初心者向け・図解】Dockerとは？現役エンジニアがわかりやすく解説](https://o2mamiblog.com/docker-beginner-1/#toc5)

# docker Hubについて参考

---

[【入門】Docker Hubとは？概要と仕組み、基本的な使い方を解説 - カゴヤのサーバー研究室](https://www.kagoya.jp/howto/cloud/container/dockerhub/)

# dockerボリュームについて参考

---

[Docker、ボリューム(Volume)について真面目に調べた - Qiita](https://qiita.com/gounx2/items/23b0dc8b8b95cc629f32)

[コンテナでデータを管理する — Docker-docs-ja 1.9.0b ドキュメント](https://docs.docker.jp/engine/userguide/dockervolumes.html)