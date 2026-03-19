# Разработка Python-библиотек с использованием локального GitLab

Данное руководство описывает полный цикл разработки Python-библиотеки: от создания проекта до публикации в локальном GitLab Package Registry и настройки автоматической синхронизации с GitHub.

---

## 1. Подготовка окружения

Для работы рекомендуется использовать современный менеджер пакетов `uv`.

1. **Установите uv** (если ещё не установлен):
   ```powershell
   powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```
2. **Создайте проект библиотеки**:
   ```powershell
   .\.venv\Scripts\uv init --lib my-awesome-lib
   cd my-awesome-lib
   ```

---

## 2. Разработка и локальный репозиторий GitLab

1. **Создайте проект в GitLab**:
   - Зайдите в ваш локальный GitLab (например, `http://gitlab.local`).
   - Нажмите **New project** -> **Create blank project**.
   - Назовите его `my-awesome-lib`.
2. **Свяжите локальную папку с GitLab**:
   ```bash
   git init
   git remote add origin http://gitlab.local/root/my-awesome-lib.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

---

## 3. Синхронизация с GitHub (Mirroring)

Чтобы ваш локальный репозиторий автоматически отправлял код на GitHub:

### Шаг 1: Получение Personal Access Token (PAT) на GitHub

Для синхронизации GitLab с GitHub вам понадобится токен доступа. На GitHub сейчас есть два типа токенов:

#### Вариант А: Classic Token (Проще всего)
1. Перейдите в **Settings** -> **Developer settings** -> **Personal access tokens** -> **Tokens (classic)**.
2. Нажмите **Generate new token (classic)**.
3. В списке областей (scopes) выберите:
   - **`repo`** (дает полный доступ к репозиториям, необходим для Push-зеркалирования).
4. Скопируйте токен.

#### Вариант Б: Fine-grained Token (Более безопасно)
Если вы создаете современный "Fine-grained token", то области `repo` целиком нет. Вам нужно выбрать:
1. **Repository access**: "Only select repositories" (выберите нужный репозиторий).
2. **Permissions** -> **Repository permissions**:
   - Нажмите на стрелочку рядом с заголовком **Repository permissions**, чтобы развернуть список доступных прав.
   - Найдите пункт **Contents**: выберите **Read and Write** (нужно для пуша кода).
   - Найдите пункт **Metadata**: убедитесь, что выбрано **Read-only** (обычно устанавливается автоматически).
3. Скопируйте токен.

---

### Шаг 2: Настройка в GitLab

1. Зайдите в ваш проект в GitLab.
2. Перейдите в **Settings** -> **Repository**.
3. Разверните раздел **Mirroring repositories**.
4. Заполните поля:
   - **Git repository URL**: Адрес GitHub репозитория (например, `https://github.com/youruser/my-awesome-lib.git`).
   - **Mirror direction**: Push.
   - **Authentication method**: Password (или "Password/Token").
   - **Username**: Ваш логин на GitHub (обязательно, если поле отображается).
   - **Password/Token**: Вставьте ваш PAT от GitHub.
5. Нажмите **Mirror repository**.

Теперь каждый ваш `git push` в локальный GitLab будет автоматически дублироваться на GitHub.

---

## 4. Сборка и публикация в GitLab Package Registry

### Шаг A: Получение токена доступа
Для публикации нужен токен. Перейдите в GitLab: **Settings** -> **Access Tokens**. Создайте токен с ролью `Developer` и областью (scope) `api`. Сохраните его.

### Шаг B: Настройка `pyproject.toml`
Убедитесь, что ваше имя пакета уникально.

### Шаг C: Публикация через `uv`
`uv` может использовать переменные окружения для аутентификации в индексе.

1. **Соберите пакет**:
   ```bash
   .\.venv\Scripts\uv build
   ```
2. **Опубликуйте пакет** в GitLab (используя `twine` или напрямую через `uv publish` если версия позволяет):
   
   В GitLab URL для PyPI выглядит так: `http://gitlab.local/api/v4/projects/<PROJECT_ID>/packages/pypi`.
   ID проекта можно найти на главной странице проекта в GitLab.

   ```bash
   # Установка twine для загрузки (если uv publish не настроен)
   .\.venv\Scripts\uv tool install twine

   # Загрузка в реестр GitLab
   $env:TWINE_USERNAME = "root" # или имя вашего пользователя
   $env:TWINE_PASSWORD = "ВАШ_ACCESS_TOKEN"
   .\.venv\Scripts\uv run twine upload --repository-url http://gitlab.local/api/v4/projects/<PROJECT_ID>/packages/pypi dist/*
   ```

---

## 5. Использование библиотеки в других проектах через `uv`

Чтобы другой ваш проект (подпроект) мог скачивать эту библиотеку из вашего локального GitLab через `uv add`, нужно настроить источники.

1. **Перейдите в проект-потребитель**:
   ```bash
   cd ../my-app
   ```
2. **Настройте альтернативный индекс в `pyproject.toml`**:
   Добавьте следующие секции:

   ```toml
   [[tool.uv.index]]
   name = "gitlab"
   url = "http://gitlab.local/api/v4/projects/<PROJECT_ID>/packages/pypi/simple"
   publish-url = "http://gitlab.local/api/v4/projects/<PROJECT_ID>/packages/pypi"
   ```

   **Важно:** Используйте именно `http://gitlab.local`, а не прямой IP-адрес. Если GitLab возвращает ссылки с IP-адресом (как в ошибке выше), это означает, что в настройках GitLab (`external_url`) указан IP вместо домена. 
   
   Чтобы исправить это:
   1. Зайдите в консоль ВМ: `vagrant ssh`.
   2. Выполните команду: `sudo gitlab-ctl reconfigure` (наши скрипты теперь автоматически ставят `gitlab.local`).
   3. Или вручную проверьте `/etc/gitlab/gitlab.rb`, чтобы там было `external_url 'http://gitlab.local'`.

3. **Авторизация для uv**:
   Для доступа к приватному реестру GitLab, `uv` требует токен. `uv` сопоставляет переменные окружения с индексами по их имени в `pyproject.toml` (в нашем примере это `gitlab`).

   **Важно:** Имя переменной строится по шаблону `UV_INDEX_<ИМЯ_ИНДЕКСА>_PASSWORD`.

   *   **Вариант 1: Personal Access Token (PAT)**
       - Создается в GitLab (**User Settings** -> **Access Tokens**) с областью `api`.
       - Рекомендуется также задать `UV_INDEX_GITLAB_USERNAME` (обычно это `root` или ваше имя пользователя).
       ```powershell
       $env:UV_INDEX_GITLAB_USERNAME = "root"
       $env:UV_INDEX_GITLAB_PASSWORD = "ВАШ_ACCESS_TOKEN"
       ```

   *   **Вариант 2: Deploy Token (Рекомендуется для CI)**
       - Создается в конкретном проекте (**Settings** -> **Repository** -> **Deploy Tokens**) с областью `read_package_registry`.
       - При создании вы получите `Username` и `Password`.
       - Задайте пароль в переменную:
       ```powershell
       $env:UV_INDEX_GITLAB_PASSWORD = "ПАРОЛЬ_ДЕПЛОЙ_ТОКЕНА"
       ```
       *Примечание: Если `uv` не может авторизоваться, можно также явно указать имя пользователя:*
       ```powershell
       $env:UV_INDEX_GITLAB_USERNAME = "ИМЯ_ДЕПЛОЙ_ТОКЕНА"
       ```

   *Важно:* Если вы используете домен `gitlab.local`, убедитесь, что предварительно запустили `update-gitlab-host.ps1` для обновления IP в файле `hosts`.*

4. **Добавление библиотеки**:
   ```bash
   .\.venv\Scripts\uv add my-awesome-lib
   ```
   Если вы получаете `tcp connect error`, проверьте:
   1. Запущена ли ВМ (`vagrant status`).
   2. Обновлен ли IP в `hosts` (запустите `update-gitlab-host.ps1`).
   3. Не блокирует ли брандмауэр/антивирус соединение по HTTP.

Теперь `uv` при поиске пакета `my-awesome-lib` пойдёт не в глобальный PyPI, а в ваш локальный GitLab.

---

## Резюме Workflow
1. Пишем код в `my-awesome-lib`.
2. `git push` -> код улетает в локальный GitLab и зеркалируется на GitHub.
3. `.\.venv\Scripts\uv build` -> собираем `.whl` и `.tar.gz`.
4. `twine upload` -> отправляем сборку в GitLab Package Registry.
5. В приложении `my-app` делаем `.\.venv\Scripts\uv add my-awesome-lib` -> библиотека подтягивается из локального реестра.

