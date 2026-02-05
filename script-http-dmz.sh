#!/bin/bash
# CONFIGURACIÓ SERVIDOR DMZ

# 1. Instal·lació
apt update && apt install apache2 -y

# 2. Definició d'aplicacions
APPS=("www.primernomdedomini.com" "www.segonnomdedomini.org")
EXTENSIO=("com" "org")

for i in ${!APPS[@]}; do
    DOMAIN=${APPS[$i]}
    NOM=$(echo $DOMAIN | cut -d'.' -f2)
    ROOT_DIR="/var/www/$NOM"
    IMG_DIR="/var/www/$NOM-imatges"
    LOG_DIR="$ROOT_DIR/logs"

    # Crear directoris
    mkdir -p $ROOT_DIR $IMG_DIR $LOG_DIR

    # Arxius HTML bàsics
    echo "<h1>Aplicacio: $DOMAIN - Directori Arrel</h1>" > $ROOT_DIR/index.html
    echo "<h1>Aplicacio: $DOMAIN - Directori Imatges</h1>" > $IMG_DIR/index.html
    echo "Error en l'aplicació web $DOMAIN – fitxer no trobat" > $ROOT_DIR/404.html

    # VirtualHost
    cat <<EOF > /etc/apache2/sites-available/$NOM.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias $NOM.${EXTENSIO[$i]}
    ServerAdmin admin@$DOMAIN
    DocumentRoot $ROOT_DIR

    Alias /imatges $IMG_DIR

    ErrorDocument 404 /404.html
    ErrorLog $LOG_DIR/error.log
    CustomLog $LOG_DIR/access.log combined

    <Directory $ROOT_DIR>
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF
    a2ensite $NOM.conf
done

systemctl restart apache2
echo "✅ Servidor DMZ configurat."