#!/bin/bash
# CONFIGURACIÓ SERVIDOR DMZ - EXAMEN

# 1. Instal·lació i neteja
apt update && apt install apache2 apache2-utils -y
a2dissite 000-default.conf

# 2. Definició de dades del examen
# APP_NAME | DOMAIN | ALIAS | IP_RESTRICTED (opcional)
APPS=(
    "empresa|www.empresa.net|web.empresa.net"
    "servicios|www.servicios.com|servicios.com"
)

for APP in "${APPS[@]}"; do
    # Extraure dades
    IFS="|" read -r NOM DOMAIN ALIAS <<< "$APP"
    
    ROOT_DIR="/var/www/$NOM"
    LOG_DIR="/var/log/apache2/$NOM" # Millor guardar logs en la ruta estàndard

    # Crear directoris
    mkdir -p $ROOT_DIR $LOG_DIR
    
    # Contingut de prova
    echo "<h1>Benvingut a $DOMAIN</h1>" > $ROOT_DIR/index.html
    echo "Pàgina no trobada en $NOM" > $ROOT_DIR/404.html

    # VirtualHost
    cat <<EOF > /etc/apache2/sites-available/$NOM.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias $ALIAS
    DocumentRoot $ROOT_DIR

    ErrorDocument 404 /404.html
    ErrorLog \${APACHE_LOG_DIR}/$NOM-error.log
    CustomLog \${APACHE_LOG_DIR}/$NOM-access.log combined

    <Directory $ROOT_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Exemple de restricció per IP (Típic de DMZ)
    <Location /admin>
        # Suposem que la IP del admin de la LAN és 192.168.1.50
        Require ip 192.168.1.50
    </Location>
</VirtualHost>
EOF
    a2ensite $NOM.conf
done

# 3. Permisos correctes (Importantíssim per nota)
chown -R www-data:www-data /var/www/
systemctl restart apache2

echo "✅ Servidor DMZ configurat i protegit."
