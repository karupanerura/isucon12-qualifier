#!/bin/sh

set -ex
cd `dirname $0`

ISUCON_DB_PORT=${ISUCON_DB_PORT:-3306}
ISUCON_DB_USER=${ISUCON_DB_USER:-isucon}
ISUCON_DB_PASSWORD=${ISUCON_DB_PASSWORD:-isucon}
ISUCON_DB_NAME=${ISUCON_DB_NAME:-isuports}

# MySQLを初期化
env MYSQL_PWD="$ISUCON_DB_PASSWORD" mysql -u"$ISUCON_DB_USER" \
		--host "$ISUCON_ADMIN_DB_HOST" \
		--port "$ISUCON_DB_PORT" \
		"$ISUCON_DB_NAME" < init.sql &

gunzip -c tenants1.sql.gz | env MYSQL_PWD="$ISUCON_DB_PASSWORD" mysql -u"$ISUCON_DB_USER" \
		--host "$ISUCON_TENANT1_DB_HOST" \
		--port "$ISUCON_DB_PORT" &
gunzip -c tenants2.sql.gz | env MYSQL_PWD="$ISUCON_DB_PASSWORD" mysql -u"$ISUCON_DB_USER" \
		--host "$ISUCON_TENANT2_DB_HOST" \
		--port "$ISUCON_DB_PORT" &

wait