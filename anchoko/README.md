# あんちょこ

## ベンチ前のローテーション

```bash
sudo logrotate.pl nginx /var/log/nginx/access.log
sudo logrotate.pl mysql /tmp/mysql-slow.log
```

## 設定バックアップ

```bash
sudo cp /etc/nginx/nginx.conf{,.bak}
sudo cp /etc/mysql/my.cnf{,.bak}
```

## MySQLバックアップ

```bash
# databaseが1つだけの場合
sudo mysqldump -uroot --single-transaction --skip-lock-tables --order-by-primary $DATABASE | gzip -c > /tmp/isucon12q.sql.gz

# databaseが複数ある場合
sudo mysqldump -uroot --single-transaction --skip-lock-tables --order-by-primary --databases $DATABASE1 $DATABASE2 | gzip -c > /tmp/isucon12q.sql.gz

# リストア
gunzip -c /tmp/isucon12q.sql.gz | sudo mysql -uroot
```

## MySQLのユーザーを作る

```sql
-- ユーザーを作る
CREATE USER 'isucon'@'%' IDENTIFIED BY 'isucon';

-- DBを作る
CREATE DATABASE isuumo;

-- ユーザーにDBへの全権を付与する
GRANT ALL ON `isuumo`.* TO isucon;
```

## MySQLのデータディレクトリを作り直す

```bash
# rootになる
sudo -i

# 止める
systemctl stop mysql
ps axu | grep '[m]ysqld' # 確認

# バックアップ
mv /var/lib/mysql{,.$(data +%s).bak}

# 作り直す
mkdir /var/lib/mysql
chown mysql:mysql /var/lib/mysql
mysqld --user=mysql --initialize-insecure
```

## code push

`ssh -A isucon12q-1` でSSH Agentを持ち込むこと。

```bash
# gitの設定
 git config --global user.name karupanerura
 git config --global user.email karupa@cpan.org
 git config --global alias.st status
 git config --global alias.df diff
 
 # リポジトリのpush (DIR=たぶんwebapp)
 cd $DIR
 git init
 git remote add origin git@github.com:karupanerura/isucon12-qualifier.git
 git fetch
 git checkout main
 git add .
 git status # 余計なバイナリとか謎の巨大ファイルとかをうっかり含んでないか確認 && あったら内容を確認しつつ不要なものを.gitignoreで排除
 git commit -am 'added codes'
 git push -u origin main
 ```

## MySQLのSlaveを構築する

### 1. いったんSlaveとなるサーバーで[MySQL]を普通に構築する

データがある場合は[MySQLのデータディレクトリを作り直す]

### 2. MasterでBinlogを有効化する

設定から `skip_log_bin` を外しつつ `log_bin` と `binlog_format = 2` を設定して再起動

```sql
-- Masterで実行
SHOW MASTER STATUS\G
-- binlogが出ていることを確認
```

### 3. Masterからmysqldumpで `--dump-replica` 付きのバックアップを取る

```bash
# masterで実行
# databaseが1つだけの場合
mysqldump -uroot --single-transaction --skip-lock-tables --order-by-primary --dump-replica $DATABASE | gzip -c > ~/serve/isucon12q.sql.gz

# databaseが複数ある場合
mysqldump -uroot --single-transaction --skip-lock-tables --order-by-primary --dump-replica --databases $DATABASE1 $DATABASE2 | gzip -c > ~/serve/isucon12q.sql.gz
```

### 4. Slaveでバックアップを流し込む

```bash
# slaveで実行
gunzip -c ~/serve/isucon11q.sql.gz | mysql -uroot
```

### 5. 確認

```sql
-- Slaveで実行
SHOW SLAVE STATUS\G
-- Slave_IO_Running: YesかつSlave_SQL_Running: YesならOK

-- 開始されていない場合
START SLAVE;

-- MasterのIPが違っていた場合
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST='$CORRECT_MASTER_IP';
START SLAVE;
```