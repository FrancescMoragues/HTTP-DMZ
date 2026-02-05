#!/bin/bash
# CONFIGURACIÓ SERVIDOR INTRANET

apt update && apt install apache2 apache2-utils -y
a2enmod cgi rewrite authz_host

# --- APLICACIÓ 1: intranet.primernomdedomini.com ---
mkdir -p /var/www/intranet/logs /var/www/intranet-privat
echo "<h1>Aplicacio Intranet - Arrel</h1>" > /var/www/intranet/index.html
echo "<h1>Directori Privat</h1>" > /var/www/intranet-privat/index.html
echo "Error en l'aplicació web Intranet – fitxer no trobat" > /var/www/intranet/404.html

# Crear usuaris per al directori privat (Contrasenya: 1234)
htpasswd -bc /etc/apache2/.htpasswd_intranet user1 1234
htpasswd -b /etc/apache2/.htpasswd_intranet user2 1234
htpasswd -b /etc/apache2/.htpasswd_intranet user3 1234

cat <<EOF > /etc/apache2/sites-available/intranet.conf
<VirtualHost *:80>
    ServerName intranet.primernomdedomini.com
    DocumentRoot /var/www/intranet
    ErrorDocument 404 /404.html
    ErrorLog /var/www/intranet/logs/error.log
    
    Alias /privat /var/www/intranet-privat
    <Directory /var/www/intranet-privat>
        AuthType Basic
        AuthName "Acces Restringit"
        AuthUserFile /etc/apache2/.htpasswd_intranet
        Require valid-user
        # Restricció per xarxa de l'empresa (ajusta la IP)
        Require ip 127.0.0.1 192.168.1.0/24 
    </Directory>
</VirtualHost>
EOF

# --- APLICACIÓ 2: sistema.segonnomdedomini.org (CGI) ---
mkdir -p /var/www/sistema/logs
echo "Error en l'aplicació web Sistema – fitxer no trobat" > /var/www/sistema/404.html

# Crear scripts CGI
for cmd in uptime free vmstat top atop; do
    echo -e "#!/bin/bash\necho \"Content-type: text/plain\"\necho\n$cmd -n 1 2>/dev/null || $cmd" > /var/www/sistema/$cmd.sh
    chmod +x /var/www/sistema/$cmd.sh
done

# Usuaris d'administració (Contrasenya: admin123)
htpasswd -bc /etc/apache2/.htpasswd_admin admin1 admin123
htpasswd -b /etc/apache2/.htpasswd_admin admin2 admin123
htpasswd -b /etc/apache2/.htpasswd_admin admin3 admin123

cat <<EOF > /etc/apache2/sites-available/sistema.conf
<VirtualHost *:80>
    ServerName sistema.segonnomdedomini.org
    DocumentRoot /var/www/sistema
    ErrorDocument 404 /404.html

    <Directory /var/www/sistema>
        Options +ExecCGI
        AddHandler cgi-script .sh
        AuthType Basic
        AuthName "Admin Only"
        AuthUserFile /etc/apache2/.htpasswd_admin
        Require valid-user
        # Només des de xarxa d'administració (exemple)
        Require ip 127.0.0.1 10.0.0.0/24
    </Directory>
</VirtualHost>
EOF

a2ensite intranet.conf sistema.conf
systemctl restart apache2
echo "✅ Servidor Intranet configurat amb CGI i seguretat."