#!/bin/bash

# ======================================================
# CONFIGURACIÓ SERVIDOR DMZ - IP SERVIDOR: 192.168.3.84
# ======================================================

# 1. Instalació i activació de mòduls necessaris
sudo apt update && sudo apt install apache2 apache2-utils -y
sudo a2enmod authz_host  # Mòdul per restriccions d'IP

# 2. Definició de variables (Fàcil de canviar a l'examen)
IP_SERVIDOR="192.168.3.84"
RED_LOCAL="192.168.3.0/24"  # Permet accés a tota la teva subxarxa

# Aplicacions a crear
# FORMAT: "nom_carpeta|domini_principal|alias"
APPS=(
    "empresa|www.primernomdedomini.com|aplicacion.primernom.com"
    "sistema|www.segonnomdedomini.org|web.segonnom.org"
)

# 3. Neteja de llocs anteriors per evitar conflictes
sudo a2dissite 000-default.conf

# 4. Bucle de creació de VirtualHosts
for APP in "${APPS[@]}"; do
    IFS="|" read -r NOM DOMAIN ALIAS <<< "$APP"
    
    ROOT_DIR="/var/www/$NOM"
    LOG_DIR="/var/log/apache2/$NOM"

    # Crear estructura de carpetes
    sudo mkdir -p $ROOT_DIR $LOG_DIR

    # Arxius HTML bàsics i Error 404
    echo "<h1>Benvingut a la DMZ: $DOMAIN</h1><p>Servidor: $IP_SERVIDOR</p>" | sudo tee $ROOT_DIR/index.html
    echo "Error 404: El fitxer no existeix en el domini $DOMAIN" | sudo tee $ROOT_DIR/404.html

    # Crear el fitxer de configuració del VirtualHost
    sudo bash -c "cat <<EOF > /etc/apache2/sites-available/$NOM.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias $ALIAS
    ServerAdmin admin@$DOMAIN
    DocumentRoot $ROOT_DIR

    # Configuració de Logs
    ErrorLog \${APACHE_LOG_DIR}/$NOM-error.log
    CustomLog \${APACHE_LOG_DIR}/$NOM-access.log combined
    ErrorDocument 404 /404.html

    # Directori Arrel: Accés general
    <Directory $ROOT_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # RESTRICCIÓ DMZ: Exemple de directori d'administració protegit
    # Creem un directori virtual /admin per fer la prova d'IP
    <Location /admin>
        # Només permetem l'accés des de la teva IP de màquina i la xarxa local
        Require ip 127.0.0.1 $IP_SERVIDOR $RED_LOCAL
    </Location>
</VirtualHost>
EOF"

    # Activar el lloc
    sudo a2ensite $NOM.conf
done

# 5. Permisos i Reinici
sudo chown -R www-data:www-data /var/www/
sudo systemctl restart apache2

echo "=========================================================="
echo "Servidor DMZ configurat a la IP $IP_SERVIDOR"
echo "Dominis actius:"
echo " - http://www.primernomdedomini.com"
echo " - http://www.segonnomdedomini.org"
echo "Prova la restricció d'IP a: http://www.primernomdedomini.com/admin"
echo "=========================================================="
