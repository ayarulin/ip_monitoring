# IP monitoring app

## Загрузка кода и зависимости

- `lib/boot.rb` настраивает Zeitwerk и автозагружает весь код из `lib` (кроме `infrastructure/db/migrations`).
- `System::Container` (см. `lib/system/container.rb`) отвечает только за DI и регистрацию компонентов через boot-файлы в `lib/system/boot`.

### Компоненты контейнера

- Boot `:db` (`lib/system/boot/db.rb`) регистрирует компонент `db` через `Infrastructure::Db::Connection.build`.
- Boot `:core` (`lib/system/boot/core.rb`) регистрирует:
  - `core.ips` → `Core::Dao::Ips` c `db` из контейнера;
  - `core.ip_states` → `Core::Dao::IpStates` c `db` из контейнера;
  - `core.transaction` → `Core::Services::Transaction` c `db` из контейнера;
  - `core.add_ip_address_cmd` → `Core::Commands::AddIpAddressCmd` (через auto_inject).

### Использование в приложении

- `Applications::Api::App` (см. `lib/applications/api/app.rb`) использует `System::Container` для получения команд:
  - `Applications::Api::App.container['core.add_ip_address_cmd']`.
- Продакшн-энтрипоинт `lib/applications/api/config.ru`:
  - `require_relative 'app'` (поднимает Zeitwerk и контейнер);
  - `System::Container.start(:db, :core)` — старт boot-компонентов;
  - `System::Container.finalize! if ENV['RUBY_ENV'] == 'production'` — фиксация контейнера в проде;
  - `run Applications::Api::App`.

### Тесты

- `spec/spec_helper.rb` поднимает Zeitwerk и контейнер так же, как прод:
  - `System::Container.start(:db, :core)`;
  - `TEST_DB = System::Container['db']`.
- `database_cleaner-sequel` использует `TEST_DB` для очистки базы между примерами.

Таким образом, прод и тесты используют один и тот же путь инициализации зависимостей через `dry-system`, а core-логика остается независимой от инфраструктуры и контейнера.
