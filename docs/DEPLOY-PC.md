# Virent — Деплой на свой ПК ($0/мес)

## Быстрый старт (5 минут)

### 1. Установить Docker

```bash
# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Выйти и зайти снова (чтобы группа применилась)

# Проверить
docker --version
docker compose version
```

### 2. Клонировать репозиторий

```bash
git clone https://github.com/FreedoomForm/Virent.git
cd Virent
```

### 3. Настроить окружение

```bash
cp .env.pc .env
nano .env  # изменить пароли и секреты!
```

**Важно:** Сгенерируй случайные секреты:
```bash
openssl rand -hex 32  # для JWT_SECRET
openssl rand -hex 32  # для JWT_REFRESH_SECRET
openssl rand -hex 32  # для COOKIE_KEY
```

### 4. Запустить!

```bash
docker-compose -f docker-compose.pc.yml up -d --build
```

**Первый запуск: 5-10 минут** (сборка Docker образов).

### 5. Проверить

```bash
# Health check
curl http://localhost:8393/health
# → {"status":"ok","timestamp":"...","version":"1.0.0"}

# Открыть в браузере:
#   API docs:  http://localhost:8393/v1/
#   Webb:      http://localhost:3000/
#   Admin:     http://localhost:1337/
```

### 6. Засеять тестовыми данными

```bash
docker exec virent-api node -e "
const {MongoClient} = require('mongodb');
// ... seed script
" 
# Или использовать seed-db.js из backend/scripts/
```

### 7. Войти

```
Admin:  admin@sparkrentals.local / Admin123!  → http://localhost:1337/
User:   user@sparkrentals.local  / User123!   → http://localhost:3000/
```

---

## Доступ из интернета (Cloudflare Tunnel)

### Что нужно

1. **Cloudflare аккаунт** (FREE): https://dash.cloudflare.com/sign-up
2. **Домен** на Cloudflare (любой: .com, .uz, .net)
3. **Virent запущен** локально (шаг выше)

### Настройка

```bash
# Запусти скрипт (он всё сделает сам)
bash scripts/setup-cloudflare-tunnel.sh
```

После настройки:
- `https://api.твой-домен.com` → API на твоём ПК
- `https://admin.твой-домен.com` → Admin на твоём ПК
- `https://твой-домен.com` → Webb-Client на твоём ПК

**Всё бесплатно:** SSL, DDoS protection, CDN — включено в Cloudflare Free.

---

## Авто-запуск при включении ПК

```bash
bash scripts/setup-autostart.sh
```

Это:
- ✅ Включит Docker при загрузке
- ✅ Создаст systemd сервис для Virent
- ✅ Запретит sleep/suspend
- ✅ Настроит ежедневный backup в 2:00 AM

---

## Ежедневные бэкапы

```bash
# Вручную
bash scripts/backup-pc.sh

# Автоматически (уже настроено через setup-autostart.sh)
# Бэкапы сохраняются в: ./backups/mongodb/
# Хранятся 30 дней, потом удаляются
```

### Offsite backup (на GitHub)

```bash
# Создать приватный репо для бэкапов
mkdir -p backups/git
cd backups/git
git init
git remote add origin https://github.com/твой-юзер/virent-backups.git
git commit --allow-empty -m "init"
git push -u origin main
cd ../..

# Теперь backup-pc.sh будет пушить бэкапы на GitHub
```

---

## Управление

```bash
# Статус контейнеров
docker-compose -f docker-compose.pc.yml ps

# Логи (live)
docker-compose -f docker-compose.pc.yml logs -f

# Логи конкретного сервиса
docker-compose -f docker-compose.pc.yml logs -f rest-api

# Перезапустить
docker-compose -f docker-compose.pc.yml restart

# Остановить
docker-compose -f docker-compose.pc.yml down

# Остановить + удалить данные
docker-compose -f docker-compose.pc.yml down -v
```

---

## MongoDB веб-интерфейс (опционально)

```bash
# Запустить с Mongo Express
docker-compose -f docker-compose.pc.yml --profile debug up -d

# Открыть: http://localhost:8081
# Логин: admin / admin123 (изменить в .env)
```

---

## Обновление

```bash
# Получить новый код
git pull origin main

# Пересобрать
docker-compose -f docker-compose.pc.yml up -d --build

# Применить новые миграции (если есть)
docker exec virent-api node /app/scripts/run-all-tests.sh
```

---

## Мониторинг (бесплатно)

### Health check (встроенный)
```bash
curl http://localhost:8393/health
```

### Prometheus metrics (встроенный)
```bash
curl http://localhost:8393/metrics
```

### UptimeRobot (внешний, FREE)
1. Зарегистрироваться на https://uptimerobot.com
2. Добавить monitor: `https://api.твой-домен.com/health`
3. Получать SMS/email при падении

### Sentry (FREE, 5K errors/мес)
1. Зарегистрироваться на https://sentry.io
2. Добавить DSN в `.env`
3. Ошибки автоматически отправляются

---

## Решение проблем

### "Port already in use"
```bash
# Найти что занимает порт
sudo lsof -i :8393
# Убить процесс
sudo kill -9 <PID>
```

### "MongoDB connection refused"
```bash
# Проверить что MongoDB запущен
docker ps | grep mongodb
# Перезапустить
docker-compose -f docker-compose.pc.yml restart mongodb
```

### "Out of memory"
```bash
# Проверить RAM
free -h
# Уменьшить MongoDB cache
# В docker-compose.pc.yml: --wiredTigerCacheSizeGB 0.5
```

### "Docker build fails"
```bash
# Очистить кэш Docker
docker system prune -a
# Пересобрать
docker-compose -f docker-compose.pc.yml up -d --build
```

### "Cloudflare Tunnel not working"
```bash
# Проверить статус
sudo systemctl status cloudflared-virent
# Логи
journalctl -u cloudflared-virent -f
# Перезапустить
sudo systemctl restart cloudflared-virent
```

---

## Системные требования

```
Минимум:
  CPU: 2 cores (Intel i3 / AMD Ryzen 3)
  RAM: 8 GB (4 для системы, 4 для Docker)
  Disk: 50 GB свободного места
  Internet: 10+ Mbps стабильный

Рекомендуемо:
  CPU: 4 cores (Intel i5 / AMD Ryzen 5)
  RAM: 16 GB
  Disk: 100 GB SSD
  Internet: 50+ Mbps

Максимум (до 10K пользователей):
  CPU: 8 cores
  RAM: 32 GB
  Disk: 500 GB SSD
  Internet: 100+ Mbps
```

---

## Когда мигрировать на VPS?

```
Мигрируй когда:
  □ Больше 500 одновременных пользователей
  □ Нужен 99.9%+ аптайм
  □ Click/Payme требуют стабильный сервер
  □ Регистрация БД в Минцифры (нужен ДЦ)
  □ ПК не справляется (CPU > 80%, RAM > 80%)
  □ Нужен отдельный сервер для backup

Куда мигрировать:
  1. Uzcloud VPS (~$12/мес) — данные в РУз ✅
  2. Hetzner VPS (~$4.50/мес) — дёшево, но не в РУз ❌
  3. Свой выделенный сервер в РУз
```
