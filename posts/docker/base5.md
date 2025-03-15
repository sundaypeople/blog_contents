---
title:# DockerFileの書き方
tags: ["docker","container"]
---
<details>
<summary> 要約</summary> 
コンテナ内部にデータを置くと、コンテナを破棄するとデータは全て消えてしまう。それを防ぐために、外側に置く場所をボリュームという。

ボリュームには二種類ある。ホストのディレクトリと、dockerのリソースとしてのボリューム。

要は、ホストにあるものをそのままマウントしたものとと、docker create volumeで作ったボリューム

**data volume container**というものがあるが、これはdockerのオプションに—volume-formを逆に利用したやり方だと推測する。—volume-fromで指定したコンテナと同じ位置に同じものをマウントできる。多数のコンテナを同じ位置にマウントしたい場合、data用のコンテナを一つ用意して、それと同じようにマウントさせていく方法。volumeを制作するだけだと、マウント位置を書かなければならないので、data volume container が使われる。（現在調査中）

`docker volume inspect` で保存場所を確認できる

Docker Desktop for Macを使っている場合、Docker環境はHyperKitというVM(バーチャルマシン)上で実行されているためMacからは参照できないようです。

nsenter1というコマンドでVMに入って確認することができます。

また、詳しくは違うページに書く。

ocker Desktop for Macを使っている場合、Docker環境はHyperKitというVM(バーチャルマシン)上で実行されているためMacからは参照できないようです。

</details>
## ボリューム とは

ボリュームとは、Docker コンテナーにおいて生成され利用されるデータを、永続的に保持する目的で利用される仕組みです。他にバインドマウントという機能も存在する。割とバインドマウントを使う機会が多い（個人的体感）。

ボリュームはホストマシン上に新たなディレクトリが生成され、そこが Docker の保存ディレクトリとなります。ホストマシンとは切り離されていて、**完全に Docker によって管理**されます。

つまり、編集するときにdockerを使わなかえればならない。コンテナを経由して編集する前提となる。

## バインドマウントとは

バインドマウントとは、ボリュームに比べると機能は制限されるが、ホストマシン上のファイルやディレクトリがコンテナ内にマウントされる。

そのファイルやディレクトリは、Docker ホストに存在している必要がなくなります。 存在してなかったとしても、必要とされるときには生成されます。

バインドマウントは、絶対パス(full path)によって参照される。そして、ホストマシンで直接触れる。バインドマウントを管理するために Docker CLI コマンドを直接利用することはできなくなります。

ただしホストマシンのファイルシステムに依存するものとなり、利用可能な特定のディレクトリ構造に従ったものになります。

要するに、ホストマシンのディレクトリを、そのままdockerコンテナ内の指定したディレクトリの下にマウントできるということ。

## tmpfs　マウントとは

コンテナに一時的に保存したい場合、かつ、コンテナレイヤーにも書き込みたくないデータをマウントするさいに使用される。コンテナが作成され削除されるまでの間に、非永続的な状態または機密情報を保存することができます。**ホストマシンのメモリ上にのみ存在します。**

• この機能は Docker on Linux を稼動させている場合にのみ利用可能です。

使用例

- `tmpfs`マウントはデータをホストマシンかコンテナ内でも保持したくない場合。
    - これはセキュリティ上の理由か、大量の非永続化データを書き込む必要がある場合にコンテナのパフォーマンスを保護するためです。

## バインドマウントよりボリュームが優れている点

- ボリュームはバインドマウントよりも、バックアップや移行が容易です。
- ボリュームは Docker CLI コマンドや Docker API を利用して管理することができます。
- ボリュームは Linux と Windows 上のコンテナーにおいて動作します。
- ボリュームは複数コンテナー間にて安全に共有できます。
- ボリュームドライバーを用いると、リモートホスト上、あるいはクラウドプロバイダー上のボリュームに保存できるようになります。保存の際にはボリューム内データを暗号化することができ、その他にも種々の機能を利用することができます。
- ボリュームを新たに生成すると、その内容はコンテナーがあらかじめ用意していた内容になります。
- Docker Desktop 上のボリュームは、Mac や Windows ホストからのバインドマウントに比べて、より高い性能を実現します。

![](https://matsuand.github.io/docs.docker.jp.onthefly/storage/images/types-of-mounts-volume.png)

# ボリュームの使い方

> 全般に`--mount`の方がわかりやすいものですが、記述は増えます。 両者の最大の違いは、`-v`の文法がオプション指定のすべてを 1 項目にとりまとめるものであるのに対して、`--mount`の文法はそれを 1 つずつ個別に分けている点です。
> 

要するに`—mount`はわかりやすいけど、打つ量が多い。`-v`や`—volume`は打つのが短い。

> はじめて利用する方は`--mount`を利用してください。 上級ユーザーは`-v`や`--volume`を用いることに慣れているかもしれませんが、`--mount`を利用するように心がけてください。 `--mount`の方が簡単に利用することができるとの調査もあります。
> 

- `-v`または`—volume`の場合
    - **`v`または`-volume`**: 3 つの項目から構成され、それぞれをコロン（`:`）で区切ります。 各項目は正しい順に記述する必要があります。 各項目の意味は、そのときどきによって変わります。
        - 名前つきボリュームの場合、1 つめの項目は、そのボリューム名です。 指定されるホストマシン上において固有の名称であるものです。 匿名ボリュームの場合、1 つめの項目は省略されます。
        - 2 つめは、コンテナー内にマウントされるファイルまたディレクトリのパスです。
        - 3 つめは任意の指定項目であり、オプション指定をカンマ区切りで指定します。 指定内容には`ro`などがあります。 このオプションに関しては後に説明しています。
- `—mount`の場合
    - **`-mount`**: 複数のキーバリューペアを指定し、各ペアはカンマにより区切ります。 そしてそれぞれのペアは`<key>=<value>`という記述を行います。 `-mount`における記述は`v`や`-volume`におけるものよりも長くなります。 しかしキーの並び順に意味はなく、このフラグに与えられたキーバリューの内容は容易に理解することができます。
        - `type`はマウントのタイプであり、[`bind`](https://matsuand.github.io/docs.docker.jp.onthefly/storage/bind-mounts/), `volume`, [`tmpfs`](https://matsuand.github.io/docs.docker.jp.onthefly/storage/tmpfs/) といった値を指定します。 ここで説明しているのはボリュームであるため、常に`volume`であるものとします。
        - `source`はマウント元です。 名前つきボリュームの場合は、そのボリューム名です。 匿名ボリュームの場合、この項目は省略します。 `source`あるいは`src`といった指定がよく用いられます。
        - `destination`には、コンテナー上にてマウントするファイルまたはディレクトリのパスを指定します。 `destination`、`dst`、`target`といった指定がよく用いられます。
        - オプション`readonly`が指定されると、そのボリュームが [コンテナーにおける読み込み専用マウント](https://matsuand.github.io/docs.docker.jp.onthefly/storage/volumes/#use-a-read-only-volume) としてマウントされます。 これは`readonly`または`ro`として指定が可能です。
        - `volume-opt`オプションは複数の指定が可能です。 オプション名とその値からなるキーバリューペアを指定します。

### **`v`と`-mount`の動作の違い**

バインドマウントの場合とは違い、ボリュームのオプションは、`--mount`と`-v`フラグの両方においてすべて利用できます。

サービスにおいてボリュームを利用する場合は`--mount`のみがサポートされます。

## ボリュームの生成と管理

バインドマウントとは異なり、ボリュームの生成と管理はコンテナーの外部から行います。

### ボリュームの生成

```bash
docker volume create my-vol
```

### ボリュームの一覧表示

```bash
docker volume ls
```

### ボリュームの確認

```bash
docker volume inspect test
[
    {
        "CreatedAt": "2023-05-04T01:20:43Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/test/_data",
        "Name": "test",
        "Options": {},
        "Scope": "local"
    }
]
```

### ボリュームの削除

```bash
docker volume rm test
```

## ボリュームを使ったコンテナの起動

ボリュームがまだ存在していない状態で、そのボリュームを使ったコンテナーを起動すると、Docker はその際にボリュームを生成します。

`--mount`と`-v`によるそれぞれの例は、同一の結果になります。 ただし 2 つの例を同時に実行することはできません。

```bash
docker run -d --name devtest --mount source=myvol2,target=/var/www httpd
```

## docker composeでのボリューム利用

ボリュームを利用する単一の Compose サービスは、たとえば以下のようなものです。

`version: "3.9"
services:
  frontend:
    image: node:lts
    volumes:
      - myapp:/home/node/app
volumes:
  myapp:`

`ocker-compose up`の初回実行時に、そのボリュームが生成されます。 このボリュームが、それ以降の実行時においても再利用されます。

## service外に記述(volumeを事前に作成している場合)

volumeを事前に作成した上でvolumeをバインドさせることもできます。

まずはexternal-test-volumeという名前のvolumeを事前に作成します。

```bash
% docker volume create external-test-volume
external-test-volume
```

docker-compose.ymlのvolumesにexternalオプションを追記します。

```bash
version: "3.8"

services:
  app:
    build:
      context: ./dockerfile_dir
      dockerfile: Dockerfile
    volumes:
      - "external-test-volume:/volume_dir"

volumes:
  external-test-volume:
    external: **true**
```

externalオプションによってdocker-composeの外で既に作成済みのvolumeを使うことができるようになります。

services > app > volumesで指定するvolume名をexternal-test-volumeに修正しdocker-composeを実行すると、事前に作成したvolumeが有効であることが確認できます。

# **volumesを複数行で書く**

こちらの記事でvolumesを複数行に分けて書ける(long syntax)ことを知りました。

```bash
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - type: bind
        source: ./volumes_test_dir
        target: /volume_dir
```

typeには、Docker上のvolumeを使う場合はvolumeを、ホストのディレクトリをコンテナにバインドさせる場合はbindを指定します。(他にもtmpfs, npipeアリ)

bindのsourceにはホストのディレクトリを、targetにはコンテナのディレクトリを記述します。

volumeのsourceにはvolume名を、targetにはコンテナのディレクトリを記述します。

単行(short syntax)だと自動でディレクトリを作成され予期せぬエラーが発生してしまうことがあるので、基本的にはlong syntaxで記述しておけば良いようです。

## まだまだ機能はあるがとりあえず一旦ここまで()

# バインドの使い方

> 全般に`--mount`の方がわかりやすいものですが、記述は増えます。 両者の最大の違いは、`-v`の文法がオプション指定のすべてを 1 項目にとりまとめるものであるのに対して、`--mount`の文法はそれを 1 つずつ個別に分けている点です。 以下に両フラグにおける文法を比較します。
> 

要するに、`—mount`がわかりやすくて書く行が多い、`-v`や`—volume`は書く行が少ない

> はじめて利用する方は`--mount`を利用してください。 上級ユーザーは`-v`や`--volume`を用いることに慣れているかもしれませんが、`--mount`を利用するように心がけてください。 `--mount`の方が簡単に利用することができるとの調査もあります。
> 

- `-v`または`—volume`と`—mount`の違い
    - **`v`または`-volume`**: 3 つの項目から構成され、それぞれをコロン（`:`）で区切ります。 各項目は正しい順に記述する必要があります。 各項目の意味は、そのときどきによって変わります。
        - バインドマウントの場合、1 つめの項目は **ホストマシン** 上のファイルまたはディレクトリへのパスです。
        - 2 つめは、コンテナー内にマウントされるファイルまたディレクトリのパスです。
        - 3 つめは任意の指定項目であり、オプション指定をカンマ区切りで指定します。 指定内容には`ro`, `z`, `Z`などがあります。 このオプションに関しては後に説明しています。
    - **`-mount`**: 複数のキーバリューペアを指定し、各ペアはカンマにより区切ります。 そしてそれぞれのペアは`<key>=<value>`という記述を行います。 `-mount`における記述は`v`や`-volume`におけるものよりも長くなります。 しかしキーの並び順に意味はなく、このフラグに与えられたキーバリューの内容は容易に理解することができます。
        - `type`はマウントのタイプであり、`bind`, `volume`, `tmpfs`といった値を指定します。 ここで説明しているのはバインドマウントであるため、常に`bind`であるものとします。
        - `source`はマウント元です。 バインドマウントにおいては、Docker デーモンホスト上のファイルまたはディレクトリへのパスになります。 `source`あるいは`src`といった指定がよく用いられます。
        - `destination`には、コンテナー上にてマウントするファイルまたはディレクトリのパスを指定します。 `destination`, `dst`, `target`といった指定がよく用いられます。
        - オプション`readonly`が指定されると、そのバインドマウンドが [コンテナーにおける読み込み専用マウント](https://matsuand.github.io/docs.docker.jp.onthefly/storage/bind-mounts/#use-a-read-only-bind-mount) としてマウントされます。
        - オプション`bind-propagation`が指定されると、[バインドプロパゲーション](https://matsuand.github.io/docs.docker.jp.onthefly/storage/bind-mounts/#configure-bind-propagation)（bind propagation）の設定変更を行います。 `rprivate`, `private`, `rshared`, `shared`, `rslave`, `slave`のいずれかを指定します。
        - `-mount`フラグは、selinux ラベルを修正するための`z`または`Z`オプションには対応していません。
    
    ### **`v`と`-mount`の動作の違い**
    
    - `v`および`-volume`フラグは、長らく Docker の一部分として実現してきているため、その動作を今さら変更することはできません。 このことがつまり、**`v`と`-mount`の動作の違いの 1 つ** になります。
    - `v`または`-volume`を使ってファイルやディレクトリをバインドマウントした際に、そのファイルやディレクトリが Docker ホスト上にまだ存在していなかった場合、`v`はそのマウントエンドポイントを生成します。 **その場合には常にディレクトリとして生成されます。**
    - `-mount`を使ってファイルやディレクトリをバインドマウントした際に、そのファイルやディレクトリが Docker ホスト上に存在していなかった場合、Docker はそのファイルやディレクトリを自動的に生成することは**しません**。 かわりにエラーが出力されます。
    
    **これはdocker composeのshort syntaxとlong syntaxにも言えることである。**
    
    **—mount,-vは相対パスで指定できない**
    
    docker compose だと相対パスで指定できる。
    
    ### **コンテナー上の空ではないディレクトリへのマウント**
    
    バインドマウントする先のコンテナー内ディレクトリが空でなかったとします。 このときそのディレクトリ内にはじめからあった内容は、バインドマウントによって見えなくなってしまいます。 そうであっても、このことを便利に利用できる場合もあります。 たとえばアプリケーションの新バージョンをテストする際に、新たなイメージをビルドせずに実現するような場合です。 ただしそういった状況には驚くかもしれません。 またこの動きは [Docker ボリューム](https://matsuand.github.io/docs.docker.jp.onthefly/storage/volumes/) とは異なるものです。
    
    以下は極端な例です。 コンテナーの`/usr/`ディレクトリをホストマシン上の`/tmp/`ディレクトリに置き換えてしまうものです。 おそらくこのコンテナーは使いものにならなくなります。
    
    - `-mount`と`v`によるそれぞれの例は、同一の結果になります。
    - `-mount`
    - `v`
    
    ```bash
    $ docker run -d \
      -it \
      --name broken-container \
      --mount type=bind,source=/tmp,target=/usr \
      nginx:latest
    
    docker: Error response from daemon: oci runtime error: container_linux.go:262:
    starting container process caused "exec: \"nginx\": executable file not found in $PATH".
    ```
    
    コンテナーは生成されましたが、起動はされませんでした。 コンテナーはここで削除します。
    
    ```bash
    $ docker container rm broken-container
    ```
    

# 参照

[【図解】Dockerの全体像を理解する -中編- - Qiita](https://qiita.com/etaroid/items/88ec3a0e2d80d7cdf87a)

[https://numb86-tech.hatenablog.com/entry/2022/04/24/221235#:~:text=Docker の volume は、コンテナ,ができるようになる。](https://numb86-tech.hatenablog.com/entry/2022/04/24/221235#:~:text=Docker%20%E3%81%AE%20volume%20%E3%81%AF%E3%80%81%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A,%E3%81%8C%E3%81%A7%E3%81%8D%E3%82%8B%E3%82%88%E3%81%86%E3%81%AB%E3%81%AA%E3%82%8B%E3%80%82)

[Dockerでvolumesを設定する](https://zenn.dev/ajapa/articles/fc1205d4bcbfe7)

[ボリュームの利用](https://matsuand.github.io/docs.docker.jp.onthefly/storage/volumes/)

[バインドマウントの利用](https://matsuand.github.io/docs.docker.jp.onthefly/storage/bind-mounts/)

[Dockerのマウント3種類についてわかったことをまとめる - Qiita](https://qiita.com/y518gaku/items/456f34c317a65a9dae86)

[【Docker】ボリューム・バインド・一時メモリ（tmpfs）マウントの概要・違いを徹底解説](https://di-acc2.com/system/23150/)

[docker-composeでvolumesを設定する](https://zenn.dev/ajapa/articles/1369a3c0e8085d)

[docker-compose の bind mount を1行で書くな](https://zenn.dev/sarisia/articles/0c1db052d09921)