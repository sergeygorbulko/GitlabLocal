#!/bin/bash

echo "Configuring GitLab settings (Artifactory, Wiki)..."

# GitLab Wiki включен по умолчанию в новых версиях GitLab.
# Под "Artifactory" в контексте GitLab обычно понимают Package Registry (Generic, Maven, NuGet и др.).
# Включаем Package Registry в gitlab.rb если он не включен.

GITLAB_CONFIG="/etc/gitlab/gitlab.rb"

# Включение Package Registry (замена Artifactory внутри GitLab)
sudo sed -i "s/# gitlab_rails\['packages_enabled'\] = true/gitlab_rails['packages_enabled'] = true/" $GITLAB_CONFIG

# Можно также включить конкретные пакетные реестры, например Generic Packages
# (они обычно включены если включен packages_enabled)

# Применяем конфигурацию
sudo gitlab-ctl reconfigure

echo "GitLab configuration updated."
