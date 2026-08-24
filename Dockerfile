# syntax=docker/dockerfile:1
# ============================================================
# پنل 3x-ui (سنایی) v3.6.0 — دیپلوی آماده برای Railway
# باینری رسمی MHSanaei (شامل xray داخلی) + nginx تک‌پورت
# ============================================================

FROM alpine:3.19

# ابزارهای لازم: nginx (پروکسی تک‌پورت)، gettext (envsubst)، sqlite و...
RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    socat \
    tzdata \
    sqlite \
    nginx \
    gettext \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

# دانلود و نصب باینری رسمی 3x-ui v3.6.0
# (این فایل شامل xray و geoip/geosite هم هست — همه‌چیز داخل خودشه)
ARG XUI_VERSION=v3.6.0
RUN curl -L "https://github.com/MHSanaei/3x-ui/releases/download/${XUI_VERSION}/x-ui-linux-amd64.tar.gz" -o /tmp/x-ui.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /usr/local/ \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui \
    && chmod +x /usr/local/x-ui/bin/xray-linux-amd64

# دیتابیس و لاگ (دیتابیس روی Volume در Railway — مسیر /etc/x-ui)
RUN mkdir -p /etc/x-ui /var/log/x-ui

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# nginx همیشه روی پورت ثابت 3000 گوش می‌دهد —
# ⚠️ در Railway هنگام «Generate Service Domain» باید عدد 3000 وارد شود
EXPOSE 3000

CMD ["/start.sh"]
