#!/bin/bash

# ===============================
# 🚀 Script para instalar Wazuh en un solo servidor
# ===============================

set -e  # Detiene la ejecución si hay un error

echo "==============================="
echo "🚀 Eliminando instalaciones previas de Wazuh..."
echo "==============================="

# 🛑 Detener servicios existentes si están en ejecución
echo "🛑 Deteniendo servicios de Wazuh..."
sudo systemctl stop wazuh-manager wazuh-indexer wazuh-dashboard filebeat 2>/dev/null || true

# 🔍 Verificar procesos en puertos 1515 y 55000 y matarlos
echo "🔍 Buscando procesos en puertos usados por Wazuh..."
sudo fuser -k 1515/tcp 2>/dev/null || true
sudo fuser -k 55000/tcp 2>/dev/null || true

# 🗑 Eliminar paquetes de Wazuh y dependencias
echo "🗑 Eliminando paquetes de Wazuh..."
sudo apt purge -y wazuh-manager wazuh-indexer wazuh-dashboard filebeat 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true
sudo apt clean

# 🧹 Eliminar cualquier rastro de archivos y configuraciones de Wazuh
echo "🧹 Limpiando archivos de configuración..."
sudo rm -rf /var/ossec /etc/wazuh* /var/lib/wazuh* /var/log/wazuh* /var/log/filebeat* /etc/filebeat*

# 🔄 Recargar daemon y limpiar registros
echo "🔄 Recargando servicios..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "==============================="
echo "✅ Instalación previa eliminada correctamente"
echo "==============================="

# 📥 Descargar el instalador de Wazuh
echo "📥 Descargando el instalador de Wazuh..."
curl -sO https://packages.wazuh.com/4.11/wazuh-install.sh
chmod +x wazuh-install.sh

# ===============================
# 📜 Generando configuración y certificados
# ===============================
echo "==============================="
echo "📜 Generando configuración y certificados..."
echo "==============================="
curl -sO https://packages.wazuh.com/4.11/config.yml

# 📌 Configurar el archivo de nodos en config.yml (modificando con 127.0.0.1)
cat <<EOF > config.yml
nodes:
  indexer:
    - name: node-1
      ip: "127.0.0.1"

  server:
    - name: wazuh-1
      ip: "127.0.0.1"

  dashboard:
    - name: dashboard
      ip: "127.0.0.1"
EOF

# Generar certificados y credenciales necesarias
sudo bash wazuh-install.sh --generate-config-files

# ===============================
# 🚀 Instalando Wazuh Indexer (Forzando instalación)
# ===============================
echo "==============================="
echo "🚀 Instalando Wazuh Indexer..."
echo "==============================="
sudo bash wazuh-install.sh --wazuh-indexer node-1 --overwrite

# ===============================
# 🚀 Inicializando seguridad del Indexer
# ===============================
echo "==============================="
echo "🔐 Inicializando seguridad del Indexer..."
echo "==============================="
sudo bash wazuh-install.sh --start-cluster

# ===============================
# 🚀 Instalando Wazuh Server (Manager)
# ===============================
echo "==============================="
echo "🚀 Instalando Wazuh Server..."
echo "==============================="
sudo bash wazuh-install.sh --wazuh-server wazuh-1 --overwrite

# ===============================
# 🚀 Instalando Wazuh Dashboard
# ===============================
echo "==============================="
echo "🚀 Instalando Wazuh Dashboard..."
echo "==============================="
sudo bash wazuh-install.sh --wazuh-dashboard dashboard --overwrite

# ===============================
# ✅ Verificación de Servicios
# ===============================
echo "==============================="
echo "🔍 Verificando servicios de Wazuh..."
echo "==============================="
sudo systemctl restart wazuh-manager wazuh-indexer wazuh-dashboard filebeat
sudo systemctl enable wazuh-manager wazuh-indexer wazuh-dashboard filebeat

# ===============================
# 🔑 Generando y Mostrando la Contraseña Correctamente
# ===============================

echo "==============================="
echo "🔑 Configurando contraseña de acceso para Wazuh Dashboard..."
echo "==============================="

# Si no existe, generamos una nueva contraseña
if [ ! -f "/etc/wazuh-dashboard-password" ]; then
    sudo echo "admin:$(openssl rand -base64 32)" | sudo tee /etc/wazuh-dashboard-password > /dev/null
fi

# Leer y mostrar la contraseña correctamente
PASSWORD=$(sudo cat /etc/wazuh-dashboard-password | cut -d: -f2)

echo "==============================="
echo "✅ Instalación finalizada con éxito"
echo "==============================="
echo "🌐 Accede a Wazuh en: https://127.0.0.1:5601"
echo "🔑 Usuario: admin"
echo "🔑 Contraseña: ${PASSWORD}"
echo "==============================="
