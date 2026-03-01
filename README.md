# Мониторинг доступности IP-адресов (IPv4/IPv6)

## Что реализовано

- HTTP API для управления адресами и запроса статистики.
- Фоновый воркер, который выполняет проверки раз в N секунд (по умолчанию 60) и пишет результаты в БД.
- Таймаут проверки 1 секунда: если проверка не уложилась, она считается неуспешной.
- Статистика считается на стороне PostgreSQL одним запросом.
- Учет только тех замеров, которые попали в интервалы, когда IP был `enabled`

## API

- `POST /ips` — добавить IP с параметрами `ip` (строка IPv4/IPv6) и `enabled` (boolean). Возвращает `{ id: ... }`.
- `POST /ips/:id/enable` — включить сбор статистики для IP.
- `POST /ips/:id/disable` — выключить сбор статистики для IP.
- `GET /ips/:id/stats?time_from=...&time_to=...` — получить статистику за период.
- `DELETE /ips/:id` — выключить сбор и удалить IP (реализовано как soft-delete).

## Статистика и учет интервалов

В БД хранятся:

- `ips` — адреса (с `deleted_at` и `next_check_at` для планирования проверок)
- `ip_states` — история состояний `enabled/disabled` с интервалами времени
- `ip_checks` — результаты проверок (время, успех/неуспех, RTT)

При запросе `GET /ips/:id/stats`:

- Берутся замеры `ip_checks` внутри `[time_from, time_to)`.
- Из них считаются только те, которые попадают в интервалы, когда IP был `enabled` (по `ip_states`).
- Если за период не набралось ни одного замера, возвращается ошибка `no measurements in the specified period`.

Считаемые метрики (все на уровне PostgreSQL):

- `avg_rtt_ms`, `min_rtt_ms`, `max_rtt_ms`
- `median_rtt_ms` (через `PERCENTILE_CONT(0.5)`)
- `stddev_rtt_ms` (через `STDDEV_POP`)
- `packet_loss_percent` (процент неуспешных проверок)

## Используемые технологии

- Ruby (без Rails)
- HTTP: `roda`, `puma`
- База и миграции: PostgreSQL + `Sequel`
- DI/валидация: `dry-system`, `dry-auto_inject`, `dry-validation`, `dry-struct`
- Многопоточность воркера: `concurrent-ruby`
- Проверка доступности: `ping` (iputils)
- Тесты: `rspec`, `rack-test`, `database_cleaner-sequel`
- CI: GitHub Actions (`.github/workflows/ci.yml`), запуск тестов в Docker Compose

## Архитектура (в общих чертах)

Проект разделен на уровни, чтобы логика не смешивалась с доставкой (HTTP) и инфраструктурой (Postgres, ICMP/ping, Docker):

- `lib/core` — "ядро": операции над IP, правила включения/выключения мониторинга, расчет/выдача статистики.
- `lib/applications` — исполняемые приложения:
  - `api` — HTTP API для управления IP и получения статистики.
  - `worker` — фоновый воркер, который периодически запускает проверки и пишет измерения в БД.
- `lib/infrastructure` — интеграции: БД, миграции, ping.
- `lib/system` — сборка приложения: wiring зависимостей через контейнер.

## Контейнеры и окружения

```
docker/
├── compose/
│   ├── review.yml          # Docker Compose для review-окружения (API + Worker + Postgres)
│   └── test.yml            # Docker Compose для тестов (Postgres + RSpec)
├── containers/
│   ├── api/Dockerfile      # Образ HTTP API (Roda + Puma)
│   ├── worker/Dockerfile   # Образ фонового воркера (ICMP-проверки)
│   ├── migrations/Dockerfile  # Образ для накатки миграций Sequel
│   ├── postgres/Dockerfile    # Образ PostgreSQL
│   └── rspec/Dockerfile    # Образ для запуска тестов
└── env/
    ├── review.env          # Переменные окружения для review
    └── test.env            # Переменные окружения для тестов
```

## Запуск для проверки (review)

Требования: установленный Docker (и docker compose).

Запуск:
- `bin/review/run`

Остановка:
- `bin/review/stop`

Что поднимается:
- Postgres
- миграции (один раз, перед стартом приложений)
- API (порт наружу `3000:3000`)
- worker

Быстрая проверка, что API жив:
- `curl http://localhost:3000/health`

## Тесты

Запуск тестового окружения (поднимет контейнеры и откроет shell внутри rspec-контейнера):
- `bin/tests/run`

Дальше уже внутри контейнера можно выполнить:
- `rspec`
- или точечно: `rspec spec/applications/api/app_spec.rb`

Остановка тестового docker-compose проекта:
- `bin/tests/stop`

## Нюансы
- В проекте есть открытые вопросы/заметки по поведению и точности RTT в `./TODO.md`.

