#!/bin/bash
# ============================================================
# 3x-ui + nginx — entrypoint برای Railway
#
# معماری:
#   پنل وب ......... پورت داخلی 2053 (مسیر /managepanel/)
#   سابسکریپشن .... پورت داخلی 2096 (مسیر /sub/)  ← پیش‌فرض خود 3x-ui
#   اینباند VLESS .. پورت داخلی 8080 (مسیر /)
#   nginx .......... پورت ثابت 3000 ← همین را در Railway وارد کنید
# ============================================================
set -euo pipefail

echo "🚀 Starting 3x-ui + nginx (Railway)..."
cd /usr/local/x-ui

# پورت ثابت nginx — در «Generate Service Domain» همین عدد (3000) را وارد کنید
export NGINX_PORT=3000

# ── تنظیم پنل با CLI خود 3x-ui ──
# پنل باید روی پورت 2053 و مسیر /managepanel/ باشد چون nginx به همین‌ها وصل است.
# ⚠️ این دو مقدار را از داخل تنظیمات پنل عوض نکنید (nginx پنل را نمی‌بیند).
if [ ! -f /etc/x-ui/x-ui.db ]; then
    # اولین اجرا: دیتابیس ساخته می‌شود + ادمین اولیه از متغیرهای محیطی
    # (اگر XUI_USERNAME / XUI_PASSWORD ست نشده باشند: admin / admin)
    echo "🔑 First run — creating admin: ${XUI_USERNAME:-admin}"
    ./x-ui setting -port 2053 -webBasePath /managepanel/ \
        -username "${XUI_USERNAME:-admin}" -password "${XUI_PASSWORD:-admin}" || true
else
    # اجراهای بعدی: فقط پورت/مسیر پنل (یوزر/رمز را هرگز دست نمی‌زنیم —
    # چون ممکن است در پنل عوض شده باشد)
    ./x-ui setting -port 2053 -webBasePath /managepanel/ || true
fi

# ── ساخت nginx.conf از قالب (فقط متغیر NGINX_PORT جایگزین می‌شود) ──
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# ── اجرای پنل در پس‌زمینه ──
./x-ui &
X_UI_PID=$!

# ── منتظر بالا آمدن پنل (حداکثر 30 ثانیه) ──
echo "⏳ Waiting for panel on port 2053..."
for i in $(seq 1 30); do
    if curl -fsS -o /dev/null "http://127.0.0.1:2053/managepanel/" 2>/dev/null; then
        echo "✅ Panel is up (http://127.0.0.1:2053/managepanel/)"
        break
    fi
    sleep 1
done

# ── nginx در پیش‌زمینه (پروسه اصلی کانتینر — Railway آن را زنده نگه می‌دارد) ──
echo "▶️  nginx listening on port ${NGINX_PORT}..."
nginx -t
exec nginx -g "daemon off;"
