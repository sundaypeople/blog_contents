---
title: dockerの基本的なメリットとその概念
tags: ["docker","container"]
---
# docker image をpullして立ち上げよう。


まずはDocker Hubからimageをpullしてみよう

```bash
docker pull httpd
```

これでapacheのdockerイメージを取得できた。

**以下のコマンドは打たなくていい**

```bash
docker pull httpd:2.4.57
```

など:で区切りtagを付与すると、バージョンの指定などができる。

```bash
docker create -p 8080:80 --name apache　httpd
```

このコマンドは`docker create`でコンテナを生成、`-p`でホストの8080ポートをコンテナの80ポートに繋ぐ([ホストの方を省略すると自動で設定される)](https://knowledge.sakura.ad.jp/13795/)、`—-name`でコンテナにapaheという**名前をつけ**、最後のhttpdがdockerイメージの名前をつけれる。**`--name`** オプションで割り当てなければ、デーモンは**ランダムな文字列から名前を生成**します。

```bash
docker start apache
```

これでapacheというdockerコンテナを立ち上げます。

```bash
docker exec -it apache bash
```

docker execはpidが1ではないbashに繋がることによって**exitしてもdockerコンテナが終了しない**ようにす。dockerコンテナはid1が終了すると自動的にコンテナ自体も終了する。

`-i`は `--interctive`と同じ意味を持つ。`-i`の意味はデバイスの入力を受け付けることを示すコマンド。これがないとキーボードを叩いても受け付けてくれない。STDINをツアタッチしていなくても開き続けるということらしい。（まだ詳しく理解していない）

STDIN は、STanDard INput（標準入力）の略。

`-t`は`—tty`と同じ意味を持つ。`-t`の意味はttyコマンドから来ており、偽の端末情報を登録し、ホスト側のターミナルで入力したものをdockerコンテナに移すようにしている。

要は、ホスト側のキーボードをdockerコンテナに接続しているようなもの。

TTYは、*TeleTYpewriter* の略。

以下が略さずに書いた例

```bash
docker exec --interactive --tty apache bash
```

ps使うためにapt install する。

```bash
apt update && apt install -y procps
```

私の場合だと、PIDが92に接続している。

```bash
root@ee1f3f4f70dc:/usr/local/apache2# ps aufx
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root        92  0.2  0.0   3824  3128 pts/0    Ss   11:09   0:00 bash
root       100  0.0  0.0   6444  2520 pts/0    R+   11:09   0:00  \_ ps aufx
root         1  0.0  0.0   7300  4420 ?        Ss   11:09   0:00 httpd -DFOREGROUND
www-data     8  0.0  0.0 1998448 2852 ?        Sl   11:09   0:00 httpd -DFOREGROUND
www-data     9  0.0  0.0 1932912 2852 ?        Sl   11:09   0:00 httpd -DFOREGROUND
www-data    10  0.0  0.0 1998448 2900 ?        Sl   11:09   0:00 httpd -DFOREGROUND
```

- psコマンド
    
    [psコマンドについて詳しくまとめました 【Linuxコマンド集】](https://eng-entrance.com/linux-command-ps)
    
    `ps auxf`(オプションの順番に意味はない) 操作端末のプロセスを表示し(`a`)、端末操作意外のプロセスを表示すし(`x`)、プロセスを改装で表示し(`f`)、CPUやメモリの使用率なども表示する(`u`)ということ。
    

```bash
exit
```

で抜ける。

他にも、

```bash
docker attach apache
```

docker attach はPIDが1のところに標準入出力が接続される。それによって、**`exit`コマンドを発行した場合、PIDが1のプロセス(ルートプロセス)が終了するのでコンテナも終了する。**

httpdの場合、上のプロセス表のように**PID1がhttpdデーモン**(httpd 0DFOREGRAND)になっているため、コマンドを打っても**bashに繋がらず、操作できない。**

```bash
docker ps
```

で現在**稼働しているコンテナの一覧**を表示することができる。

```bash
docker ps -a
```

で**現在存在しているコンテナ一覧**を表示

```bash
docker images
```

でdockerのimageを確認できる。

上記のやり方だと3回コマンドを打たなけらばならない

- `docker pull httpd`でdockerイメージを引っ張ってくる
- `docker crate --name apache httpd`でdockerコンテナをapacheという名前で生成
- `docker start apache`でapacheというdockerコンテナを立ち上げなければならない

## **これはめんどくさい**

ということで、これらを一つのコマンドで行う。

- なぜか入れない()
    
    ```jsx
    docker run -d -it --name apache2 httpd /bin/bash
    ```
    

```bash
docker run -d  -p 8080:80 --name apache2 httpd
```

これにより3つのコマンドが１つになった。もし、httpdイメージがなければdocker hubから勝手にpullしてくれる。あれば、それを使う。`-d`はバックグラウンドで実行させる。`-d`をつけないとlogが常に出た状態になる。（logを確認したいなら`-d`をつけなくてもいい）

最後にdockerで何かトラブルが起きたら（立ち上がらないなど）、

```bash
docker logs apache
```

`docker logs コンテナ名`でlogを確認することをお勧めする。

これで基本的なコンテナの立ち上げができるようになった

## dockerイメージをコマンドで作る

---

```bash
docker commit apache apacheps
```

これで、psをインストールした状態のイメージが生成できる.

```bash
docker run -d --name apacheps apacheps 
```

でdockerコンテナを作成、起動

```bash
docker exec apacheps
```

で中にはいいて、

```bash
ps aufx
```

すると、インストールしていないのにpsが打てる。

## docker hubに上げてみる

```bash
docker login
```

でdocker hubにログイン

```bash
docker tag apacheps soyokaze0125/apacheps:test
```

docker tag [元のイメージの名前] [docker hubアカウント]/[イメージ名]:タグ

```bash
docker push soyokaze0125/apacheps:test
```

これでdocker hubにアップロードする。

## docker image を消す

```bash
docker stop apacheps
```

でapchepsコンテナを止める

```bash
docker rm apacheps
```

でコンテナを削除。

ただしイメージは残っているので、ストレージ圧迫の原因になる。

```bash
docker rmi apacheps
```

**apacheの方もやる。apacheの方のイメージ名はhttpd**

[【図解】Dockerの全体像を理解する -前編- - Qiita](https://qiita.com/etaroid/items/b1024c7d200a75b992fc)

[Dockerのiオプション、tオプションについてのメモ](https://www.findxfine.com/others/995562562.html)

[docker exec -it の -it の意味](https://zenn.dev/swata_dev/articles/2f85a3f4b3022c)