#!/bin/bash

# Generar configuraciones automáticas
secret=$(openssl rand -base64 32)  # Genera un nuevo secret de 32 caracteres
ramdiskPath="/tmp/ramdisk"  # Directorio para el ramdisk
allowedIps="127.0.0.1"  # IPs permitidas
defaultIp="127.0.0.1"  # IP por defecto
port="8989"  # Puerto de escucha
listen="0.0.0.0"  # Dirección de escucha
dbName="channels_new.db"  # Base de datos que usa el programa

# Mensaje de bienvenida
echo "Bienvenido a la instalación de Lancar MOD 3.1."

# Actualización de los paquetes y dependencias necesarias
sudo apt-get update
sudo apt-get install -y software-properties-common

# Instalar Java
sudo add-apt-repository ppa:linuxuprising/java
sudo apt-get update
sudo apt-get install -y oracle-java17-installer

# Instalar FFmpeg
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xf ffmpeg-release-amd64-static.tar.xz
cd $(ls -d ffmpeg-* | head -n 1)  # Accede automáticamente al directorio correcto según la versión
sudo mv ffmpeg /usr/bin/
sudo mv ffprobe /usr/bin/
cd ..

# Instalar las dependencias necesarias para el proyecto
sudo apt-get install -y apache2 mysql-server flussonic

# Crear la base de datos MySQL
echo "Creando la base de datos 'mpdplayer' en MySQL..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS mpdplayer;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'mpduser'@'localhost' IDENTIFIED BY 'SecureP@ssw0rd!';"
sudo mysql -e "GRANT ALL PRIVILEGES ON mpdplayer.* TO 'mpduser'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Descargar y mover los archivos del proyecto Lancar MOD
cd /home
wget https://github.com/matrixjaen18/Lancar-MOD-3.1/raw/refs/heads/main/data.tar
tar -xf data.tar

# Mover los archivos a sus ubicaciones correctas
sudo cp -r /home/MPD-Player/cli /etc/php/7.4/cli

# Configuración de _db.php
echo "Configurando la conexión a la base de datos..."
sudo sed -i "s/\$db_host = 'localhost';/\$db_host = 'localhost';/g" /var/www/html/_db.php
sudo sed -i "s/\$db_name = 'mpdplayer';/\$db_name = 'mpdplayer';/g" /var/www/html/_db.php
sudo sed -i "s/\$db_user = 'mpduser';/\$db_user = 'mpduser';/g" /var/www/html/_db.php
sudo sed -i "s/\$db_pass = 'SecureP@ssw0rd!';/\$db_pass = 'SecureP@ssw0rd!';/g" /var/www/html/_db.php

# Configurar mpd.conf
echo "Configurando MPD..."
sudo sed -i "s/secret = GA0LXQs9C40YHRgtGA0LDRhtC40Lgg/secret = $secret/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/ramdiskPath = \/tmp\/ramdisk/ramdiskPath = $ramdiskPath/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/allowedIps = localhost/allowedIps = $allowedIps/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/defaultIp = 127.0.0.1/defaultIp = $defaultIp/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/port = 8989/port = $port/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/listen = 0.0.0.0/listen = $listen/g" /etc/mpdplayer/mpd.conf
sudo sed -i "s/dbName = channels_new.db/dbName = $dbName/g" /etc/mpdplayer/mpd.conf

# Crear la tarea cron para reiniciar el servicio todos los días a las 5 AM
echo "0 5 * * * /opt/mpdplayer/bin/restartService.sh" | sudo crontab -

# Reiniciar los servicios necesarios para asegurar que todo funcione
echo "Reiniciando servicios..."
sudo systemctl restart apache2
sudo systemctl restart mysql
sudo systemctl restart mpdplayer

echo "Instalación completada exitosamente."
