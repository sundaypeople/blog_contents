---
title:# docker networkについて
tags: ["docker","container"]
---
# 

---

Docker のインストールは、自動的に３つのネットワークを作成します。ネットワーク一覧を表示するには **`docker network ls`** コマンドを使います。

```yaml
$ docker network ls
NETWORK ID          NAME                DRIVER
7fca4eb8c647        bridge              bridge
9f904ee27bf5        none                null
cf03ee007fb4        host                host
```

デフォルトでは、３つのネットワークタイプが用意されている。それらは`—net`で指定することができる。

## noneネットワーク

noneネットワークはネットワークに接続する必要のないコンテナを生成する場合に使われる、

```yaml
ubuntu@ip-172-31-36-118:~$ docker attach nonenetcontainer

/ *# cat /etc/hosts*127.0.0.1    localhost
::1  localhost ip6-localhost ip6-loopback
fe00::0      ip6-localnet
ff00::0      ip6-mcastprefix
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
/ *# ifconfig*
lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 **(**0.0 B**)**  TX bytes:0 **(**0.0 B**)**

/ 
```

loopbackしかインターフェースがないので、ネットワークには繋がらない。

## hostネットワーク

hostネットワークはホスト側（自分のpcやserver）のipアドレスをそのまま使う。故に、コンテナ自身のipアドレスの割り当てはなく、ホストのipアドレスとポート番号でアクセスできる。

ホスト・モードのネットワーク機能は性能の最適化に役立ちます。また、コンテナが広範囲のポートを扱う状況でも役立つのは、ネットワークアドレス変換（NAT）を必要とせず、また、各ポートに対するユーザランド・プロキシを作成する必要がないからです。

**ホスト・ネットワーク機能ドライバが動作するのは Linux ホスト上のみです。そして、 Docker Desktop for Mac や Docker Desktop for Windows や、 Docker EE for Windows Server ではサポートしていません。**

## デフォルト・bridgeネットワーク

Linux bridge機能を使ったlinux上に別のネットワークを使う方式。

Linux bridge で仮想インタフェースを作成し、そのインタフェースに対してveth でDocker コンテナと接続する方式で、Docker ホストが属するネットワークとは異なる、仮想bridge 上のネットワークにコンテナを作成し、NAT 形式で外部のノードと通信する形式です。

**networkを何も指定しない場合、bridgeになる。**

ブリッジ・ネットワークの対象は、 **同じ** Docker デーモンホスト上で動作するコンテナです。異なる Docker デーモンホスト上で動作しているコンテナ間で通信をするには、OS レベルでルーティングを管理するか、 [オーバレイ・ネットワーク](https://docs.docker.jp/network/overlay.html) を利用できます。

**このデフォルト ``bridge`` ネットワークよりも、ユーザ定義ブリッジ・ネットワークの方がいい。**

## デフォルトブリッジの仕組みの確認

Docker ホスト上の全てのデフォルト・ネットワーク・ブリッジを表示するには、docker network inspect を使います。

```yaml
$ docker network inspect bridge
**[{**"Name": "bridge",
       "Id": "f7ab26d71dbd6f557852c7156ae0574bbf62c42f539b50c8ebde0f728a253b6f",
       "Scope": "local",
       "Driver": "bridge",
       "IPAM": **{**"Driver": "default",
           "Config": **[{**"Subnet": "172.17.0.1/16",
                   "Gateway": "172.17.0.1"
               **}]}**,
       "Containers": **{}**,
       "Options": **{**"com.docker.network.bridge.default_bridge": "true",
           "com.docker.network.bridge.enable_icc": "true",
           "com.docker.network.bridge.enable_ip_masquerade": "true",
           "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
           "com.docker.network.bridge.name": "docker0",
           "com.docker.network.driver.mtu": "9001"
       **}}]**
```

Docker Engine は自動的にネットワークの **`Subnet`** と **`Gateway`** を作成します。 **`docker run`** コマンドは新しいコンテナに対して、自動的にこのネットワークを割り当てます。

```yaml
$ docker run -itd --name**=**container1 busybox
3386a527aa08b37ea9232cbcace2d2458d49f44bb05a6b775fba7ddd40d8f92c

$ docker run -itd --name**=**container2 busybox
94447ca479852d29aeddca75c28f7104df3c3196d7b6d83061879e339946805c
```

２つのコンテナを実行してから、再びこのブリッジ・ネットワークを参照し、直近のコンテナのネットワークがどのようになっているか見てみましょう。 **`docker network inspect`** で **`Containers`** のセクションでコンテナ ID を表示します。

```yaml
$ docker network inspect bridge
**{[{**"Name": "bridge",
        "Id": "f7ab26d71dbd6f557852c7156ae0574bbf62c42f539b50c8ebde0f728a253b6f",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": **{**"Driver": "default",
            "Config": **[{**"Subnet": "172.17.0.1/16",
                    "Gateway": "172.17.0.1"
                **}]}**,
        "Containers": **{**"3386a527aa08b37ea9232cbcace2d2458d49f44bb05a6b775fba7ddd40d8f92c": **{**"EndpointID": "647c12443e91faf0fd508b6edfe59c30b642abb60dfab890b4bdccee38750bc1",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            **}**,
            "94447ca479852d29aeddca75c28f7104df3c3196d7b6d83061879e339946805c": **{**"EndpointID": "b047d090f446ac49747d3c37d63e4307be745876db7f0ceef7b311cbba615f48",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            **}}**,
        "Options": **{**"com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "9001"
        **}}] @**
```

上の **`docker network inspect`** コマンドは、接続しているコンテナと特定のネットワーク上にある各々のネットワークを全て表示します。デフォルト・ネットワークのコンテナは、IP アドレスを使って相互に通信できます。デフォルトのネットワーク・ブリッジ上では、Docker は自動的なサービス・ディスカバリをサポートしていません。このデフォルト・ブリッジ・ネットワーク上でコンテナ名を使って通信をしたい場合、コンテナ間の接続にはレガシー（訳者注：古い）の **`docker run --link`** オプションを使う必要があります。

実行しているコンテナに接続（ **`attach`** ）すると、設定を調査できます。

```yaml
$ docker attach container1

/ *# ifconfig*
ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:02
          inet addr:172.17.0.2  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe11:2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:9001  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1296 **(**1.2 KiB**)**  TX bytes:648 **(**648.0 B**)**

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 **(**0.0 B**)**  TX bytes:0 **(**0.0 B**)**
```

この **`bridge`** ネットワークにおけるコンテナの接続性をテストするため、３秒間 **`ping`** を実行します。

```yaml
/ *# ping -w3 172.17.0.3*
PING 172.17.0.3 **(**172.17.0.3**)**: 56 data bytes
64 bytes from 172.17.0.3: seq**=**0 ttl**=**64 time**=**0.096 ms
64 bytes from 172.17.0.3: seq**=**1 ttl**=**64 time**=**0.080 ms
64 bytes from 172.17.0.3: seq**=**2 ttl**=**64 time**=**0.074 ms

--- 172.17.0.3 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max **=** 0.074/0.083/0.096 ms
```

最後に **`cat`** コマンドを使い、 **`container1`** のネットワーク設定を確認します。

```yaml
/ *# cat /etc/hosts*172.17.0.2   3386a527aa08
127.0.0.1    localhost
::1  localhost ip6-localhost ip6-loopback
fe00::0      ip6-localnet
ff00::0      ip6-mcastprefix
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
```

**`container1`** からデタッチするには、 **`CTRL-p CTRL-q`** を使って離れます。それから **`container2`** にアタッチし、３つのコマンドを繰り返します。

```yaml
$ docker attach container2

/ *# ifconfig*
eth0      Link encap:Ethernet  HWaddr 02:42:AC:11:00:03
          inet addr:172.17.0.3  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::42:acff:fe11:3/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:9001  Metric:1
          RX packets:15 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1166 **(**1.1 KiB**)**  TX bytes:1026 **(**1.0 KiB**)**

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 **(**0.0 B**)**  TX bytes:0 **(**0.0 B**)**

/ *# ping -w3 172.17.0.2*
PING 172.17.0.2 **(**172.17.0.2**)**: 56 data bytes
64 bytes from 172.17.0.2: seq**=**0 ttl**=**64 time**=**0.067 ms
64 bytes from 172.17.0.2: seq**=**1 ttl**=**64 time**=**0.075 ms
64 bytes from 172.17.0.2: seq**=**2 ttl**=**64 time**=**0.072 ms

--- 172.17.0.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max **=** 0.067/0.071/0.075 ms
/ *# cat /etc/hosts*172.17.0.3   94447ca47985
127.0.0.1    localhost
::1  localhost ip6-localhost ip6-loopback
fe00::0      ip6-localnet
ff00::0      ip6-mcastprefix
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
```

デフォルトの **`docker0`** ブリッジ・ネットワークは、ポート・マッピング（割り当て）機能の使用と、 **`docker run --link`** によって **`docker0`** ネットワーク上にあるコンテナ間の通信を可能とします。これらの技術はセットアップが面倒であり、間違いしがちです。この技術はまだ利用可能ですが、これらを使わず、その代わりに自分自身でブリッジ・ネットワークを定義するのが望ましいです。

## ユーザー定義ネットワーク

コンテナのより優れた分離のために、自分でユーザ定義ネットワーク(user-defined network)を作成できます。Docker はこれらネットワークを作成するための、複数の **ネットワーク・ドライバ** を標準提供しています。新しい **ブリッジ・ネットワーク** や **オーバレイ・ネットワーク** を作成できます。また、自分で **ネットワーク・プラグイン** を書き、 **リモート・ネットワーク** を定義できます。

コンテナのより優れた分離のために、自分でユーザ定義ネットワーク(user-defined network)を作成できます。Docker はこれらネットワークを作成するための、複数の **ネットワーク・ドライバ** を標準提供しています。新しい **ブリッジ・ネットワーク** や **オーバレイ・ネットワーク** を作成できます。また、自分で **ネットワーク・プラグイン** を書き、 **リモート・ネットワーク** を定義できます。

以降のセクションでは、各 Docker 内蔵ネットワーク・ドライバに関するより詳細を扱います。

## ユーザ定義・ブリッジネットワーク

最も簡単なユーザ定義ネットワークは、 **`bridge`** ネットワークの作成です。このネットワークは過去の **`docker0`** ネットワークと似ています。いくつかの新機能が追加されていますが、古い機能のいくつかは利用できません。

```yaml
$ docker network create --driver bridge isolated_nw
1196a4c5af43a21ae38ef34515b6af19236a3fc48122cf585e3f3054d509679b

$ docker network inspect isolated_nw
**[{**"Name": "isolated_nw",
        "Id": "1196a4c5af43a21ae38ef34515b6af19236a3fc48122cf585e3f3054d509679b",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": **{**"Driver": "default",
            "Config": **[{**"Subnet": "172.21.0.0/16",
                    "Gateway": "172.21.0.1/16"
                **}]}**,
        "Containers": **{}**,
        "Options": **{}}]**

$ docker network ls
NETWORK ID          NAME                DRIVER
9f904ee27bf5        none                null
cf03ee007fb4        host                host
7fca4eb8c647        bridge              bridge
c5ee82f76de3        isolated_nw         bridge
```

ネットワークを作成したら、コンテナ起動時に **`docker run --net=<ネットワーク名>`** オプションを指定して接続できます。

```yaml
$ docker run --net**=**isolated_nw -itd --name**=**container3 busybox
885b7b4f792bae534416c95caa35ba272f201fa181e18e59beba0c80d7d77c1d

$ docker network inspect isolated_nw
**[{**"Name": "isolated_nw",
        "Id": "1196a4c5af43a21ae38ef34515b6af19236a3fc48122cf585e3f3054d509679b",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": **{**"Driver": "default",
            "Config": **[{}]}**,
        "Containers": **{**"885b7b4f792bae534416c95caa35ba272f201fa181e18e59beba0c80d7d77c1d": **{**"EndpointID": "514e1b419074397ea92bcfaa6698d17feb62db49d1320a27393b853ec65319c3",
                "MacAddress": "02:42:ac:15:00:02",
                "IPv4Address": "172.21.0.2/16",
                "IPv6Address": ""
            **}}**,
        "Options": **{}}]**
```

このネットワーク内で起動したコンテナは、Docker ホスト上の他のコンテナとは独立しています。ネットワーク内の各コンテナは速やかに通信が可能です。しかし、コンテナ自身が含まれるネットワークは外部のネットワークから独立しています。

![](https://docs.docker.jp/_images/bridge_network.png)

ユーザ定義ブリッジ・ネットワークの内部では、リンク機能はサポートされません。ですが、このネットワーク上にあるコンテナのポートは公開可能です。 **`bridge`** ネットワークの一部を外のネットワークから使う時に便利でしょう。

![](https://docs.docker.jp/_images/network_access.png)

ブリッジ・ネットワークは、単一ホスト上で比較的小さなネットワークの実行時に便利です。それだけではありません。 **`overlay`** ネットワークを使うと更に大きなネットワークを作成できます

## ユーザ定義ブリッジとデフォルト・ブリッジの違い

- **ユーザ定義ブリッジ・ネットワークは、コンテナ間の DNS 名前解決を自動で提供**
    
    > 過去の機能（レガシー）と考えられている --link オプション を使わなければ、 デフォルト・ブリッジ・ネットワーク上のコンテナは IP アドレスを使わないとお互いに通信できません。ユーザ定義ブリッジ・ネットワーク上であれば、コンテナはお互いに名前もしくはエイリアス（別名）で名前解決できます。
    > 
    > 
    > ウェブ・フロントエンドとデータベース・バックエンドのアプリケーションを想定しましょう。コンテナの名前が **`web`** と **`db`** であれば、 **`web`** コンテナは db コンテナに対して **`db`** という名前で接続でき、Docker ホスト上でどのようなアプリケーションが稼働していても気にかける必要がありません。
    > 
    > デフォルト・ブリッジ・ネットワーク上で同じアプリケーション・スタックを動かす場合は、コンテナ間のリンクを手動で作成する（過去の機能 **`--link`** フラグを使う）必要があります。このリンクは双方向に作成する必要があるため、2つ以上のコンテナ間で通信が必要になれば、より複雑です。あるいは、コンテナ内の **`/etc/hosts`** ファイルを手で書き換えられますが、デバッグが大変になる問題を生み出します。
    > 
- **隔離のためには、ユーザ定義ブリッジがより望ましい**
    
    > コンテナに --network を指定しなければ、コンテナはデフォルト・ブリッジ・ネットワークに接続（attach）します。**これは関係のないスタックや、サービス、コンテナと通信可能になるため、リスクを引き起こします**。
    > 
    > 
    > ユーザ定義ネットワークを利用するのであれば、コンテナが通信できるネットワークは、そのコンテナが接続しているユーザ定義ネットワーク範囲内にとどまります。
    > 
- **ユーザ定義ネットワークであれば、コンテナの接続・切断を直ちに行えます**
    
    > コンテナが稼働中であれば、ユーザ定義ネットワークへの接続や切断を直ちに行えます。ただし、**デフォルト・ブリッジ・ネットワークからコンテナを削除するには、コンテナの停止が必要**であり、さらに異なるネットワーク・オプションでコンテナを再作成する必要があります。
    > 
- **それぞれのユーザ定義ネットワークは、設定可能なブリッジを作成**
    
    > コンテナがデフォルト・ブリッジ・ネットワークを使う場合、設定は可能ですが、 MTU や iptables ルールなど、全てのコンテナで同じ設定を使います。付け加えておくと、デフォルト・ブリッジ・ネットワークの設定は Docker 外での処理のため、Docker の再起動が必要です。
    > 
    > 
    > ユーザ定義ブリッジ・ネットワークは **`docker network create`** を使って作成と設定ができます。アプリケーションのグループごとに異なるネットワーク要件があれば、それぞれ別々にユーザ定義ネットワークを作成し、設定ができます。
    > 
- **デフォルト・ブリッジ・ネットワーク上でリンクしたコンテナ間では、環境変数を共有します**
    
    > 当初、2つのコンテナ間で環境変数を共有するには --link フラグ を使い、コンテナ間をリンクする方法しかありませんでした。ユーザ定義ネットワークであれば、このような変数共有は不可能です。しかしながら、環境変数を共有するよりも優れた方法がいくつかあります。
    > 
    > - Docker ボリュームを使い、複数のコンテナで共有情報を含むファイルやディレクトリを共有。
    > - **`docker-compose`** を使い複数のコンテナを同時に起動し、 compose ファイルで共有変数を定義する。
    > - スタンドアロン・コンテナではなく、 swarm サービスを使えば、 [シークレット](https://docs.docker.jp/engine/swarm/secrets.html) や コンフィグ を利用できる。

同じユーザ定義ブリッジ・ネットワーク上に接続するコンテナは、事実上すべてのポートをお互いに公開しています。異なるネットワーク上のコンテナや Docker 外のホストからポートにアクセスできるようにするには、 **`-p`** か **`--publish`** フラグを使ってポートの公開（ published ）が必須です。

## ユーザー定義ブリッジの作り方

ユーザ定義ブリッジ・ネットワークの作成には、 **`docker network create`** コマンドを使います。

```yaml
$ docker network create my-net
```

サブネット、IP アドレスの範囲、ゲートウェイ、その他のオプションを指定できます。詳細は docker network create リファレンスか、 **`docker network create --help`** の出力をご覧ください。

ユーザ定義ブリッジ・ネットワークを削除するには、 **`docker network rm`** コマンドを使います。コンテナがその時点でネットワークに接続中であれば、まず [ネットワークからの切断](https://docs.docker.jp/network/bridge.html#disconnect-a-container-from-a-user-defined-bridge) をします。

```yaml
$ docker network rm my-net
```

- **ヒント**
    
    実際には何が起こっているのですか？
    
    ユーザ定義ブリッジの作成や削除時、あるいは、ユーザ定義ブリッジへのコンテナの接続や切断時、Docker はオペレーティングシステムに特化したツールを使い、土台とするネットワーク基盤（Linux 上であればブリッジ・デバイスの追加や削除、 **`iptables`** のルール設定など）を管理します。これらの詳細は、実装上の詳細にあたります。自分用のユーザ定義ネットワークは、Docker を使って管理しましょう。
    

## **ユーザ定義ネットワークにコンテナを接続**

新しいコンテナの作成時、1つまたは複数の **`--network`** フラグを指定できます。例として Nginx コンテナが **`my-net`** ネットワークに接続するものとします。また、外部のクライアントがポートに接続できるようにするため、コンテナ内のポート 80 を、Docker ホスト上のポート 8080 に公開します。 **`my-net`** ネットワークに接続するあらゆるコンテナは、 **`my-nginx`** コンテナ上の全てのポートに対してアクセス可能ですし、その逆もまた同様です。

```yaml
$ docker create --name my-nginx **\**
  --network my-net **\**
  --publish 8080:80 **\**
  nginx:latest
```

**実行中** のコンテナを既存のユーザ定義ブリッジに接続するには、 **`docker network connect`** コマンドを使います。以下のコマンドは、既に実行している **`my-nginx`** コンテナが稼働している既存の **`my-net`** ネットワークに接続します。

```yaml
$ docker network connect my-net my-nginx
```

## **ユーザ定義ネットワークからコンテナを切断**

ユーザ定義ブリッジ・ネットワークで実行中のコンテナを切断するには、 **`docker network disconnect`** コマンドを使います。以下のコマンドは **`my-net`** ネットワークから **`my-nginx`** コンテナを切断します。

```yaml
$ docker network disconnect my-net my-nginx
```

## **IPv6 を使う**

Docker コンテナで IPv6 のサポートが必要であれば、IPv6 ネットワークの作成やコンテナに IPv6 アドレスを割り当てる前に、 Docker デーモンで [有効化するオプション](https://docs.docker.jp/config/daemon/ipv6.html) と、その設定の再読込が必要です。

ネットワークの作成時、 IPv6 を有効化するには **`--ipv6`** フラグを使います。デフォルトの **`bridge`** ネットワークでは IPv6 サポートの無効化を選択できません。

## **Docker コンテナから外の世界への転送を有効化**

デフォルトでは、デフォルト・ブリッジ・ネットワークに接続したコンテナからのトラフィックは、外の世界のネットワークに対して転送 **されません** 。転送を有効にするには、2つの設定を変更する必要があります。これらは Docker コマンドではなく、Docker ホスト上のカーネルに対して影響を与えます。

1. Linux カーネルが IP フォワーディングを有効化する設定にします。
    
    ```yaml
    $ sysctl net.ipv4.conf.all.forwarding**=**1
    ```
    
2. **`iptables`** に対するポリシーを変更します。 **`FORWARD``ポリシーを ``DROP`** から **`ACCEPT`** にします。
    
    ```yaml
    $ sudo iptables -P FORWARD ACCEPT
    ```
    

この設定は再起動後は有効ではありませんので、スタートアップスクリプトに追加する必要があるでしょう。

## **デフォルト・ブリッジ・ネットワークを使う**

デフォルトの **`bridge`** ネットワークは Docker にとって過去の機能（レガシー）と考えられており、プロダクションでの利用は推奨されていません。なぜなら、設定は手動で行う必要がありますし、 [技術的な欠点](https://docs.docker.jp/network/bridge.html#differences-between-user-defined-bridges-and-the-default-bridge) があります。

### **デフォルト・ブリッジ・ネットワークへコンテナを接続**

もしも **`--network`** フラグを使ってネットワークを指定せず、ネットワークドライバの指定がなければ、コンテナはデフォルトの **`bridge`** ネットワークに接続するのがデフォルトの挙動です。デフォルト **`bridge`** ネットワークに接続したコンテナは通信可能ですが、 [古い機能の --link フラグ](https://docs.docker.jp/network/links.html) でリンクしていない限り、 IP アドレスのみです。

### **デフォルト・ブリッジ・ネットワークの設定**

デフォルト **`bridge`** ネットワークの設定を変更するには、 **`daemon.json`** のオプション指定が必要です。以下はいくつかのオプションを指定した **`daemon.json`** の例です。設定に必要なオプションのみ指定ください。

```yaml
**{**"bip": "192.168.1.1/24",
  "fixed-cidr": "192.168.1.1/25",
  "fixed-cidr-v6": "2001:db8::/64",
  "mtu": 1500,
  "default-gateway": "192.168.1.254",
  "default-gateway-v6": "2001:db8:abcd::89",
  "dns": **[**"10.20.1.2","10.20.1.3"**]}**
```

Docker の再起動後、設定が有効になります。

### **デフォルト・ブリッジ・ネットワークで IPv6 を使う**

Docker で IPv6 サポートを使う設定をしたら（ [IPv6 を使う](https://docs.docker.jp/network/bridge.html#bridge-use-ipv6) をご覧ください）、デフォルト・ブリッジ・ネットワークもまた IPv6 を自動的に設定します。ユーザ定義ブリッジとは異なり、デフォルト・ブリッジ上では IPv6 の無効化を選択できません。

## overlay ネットワーク

# 意味わからん（現在調査中）

# 参照

[Docker コンテナ・ネットワークの理解 — Docker-docs-ja 19.03 ドキュメント](https://docs.docker.jp/engine/userguide/networking/dockernetworks.html)

[ホスト・ネットワークの使用 — Docker-docs-ja 20.10 ドキュメント](https://docs.docker.jp/network/host.html)

[Docker network 概論 - Qiita](https://qiita.com/TsutomuNakamura/items/ed046ee21caca4a2ffd9)

[ブリッジ・ネットワークの使用 — Docker-docs-ja 20.10 ドキュメント](https://docs.docker.jp/network/bridge.html#id12)

[Dockerのブリッジネットワークについて調べました | QUARTETCOM TECH BLOG](https://tech.quartetcom.co.jp/2022/06/29/docker-bridge-network/)