# install

```bash
brew install ansible
```

# ホスト情報を更新

必要に応じて。`anchoko/render_ssh_config.pl` で生成する名前に準じる。

# run

## 初回構築

```bash
ansible-playbook -i hosts playbook.yaml --tags init
```

## nginx

```bash
ansible-playbook -i hosts playbook.yaml --tags nginx
```

## mysql

```bash
ansible-playbook -i hosts playbook.yaml --tags mysql
```
