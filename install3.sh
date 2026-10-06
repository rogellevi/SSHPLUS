#!/bin/bash
# ============================================================
#   SSHPLUS MANAGER - Instalador Completo
#   GitHub: https://github.com/rogellevi/SSHPLUS
#   Instala: SSHPLUS + Apache + PHP + Panel Web + SSL
# ============================================================

# ─── CONFIGURACIÓN GLOBAL ───────────────────────────────────
# URL del panel (Corregida al repositorio principal)
PANEL_URL="https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/sshplus.php"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'

# Verificar root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}✗ Este script debe ejecutarse como root${NC}"
  exit 1
fi

# ─── BANNER ─────────────────────────────────────────────────
show_banner() {
  clear
  echo -e "${CYAN}"
  echo "  ███████╗███████╗██╗  ██╗██████╗ ██╗     ██╗   ██╗███████╗"
  echo "  ██╔════╝██╔════╝██║  ██║██╔══██╗██║     ██║   ██║██╔════╝"
  echo "  ███████╗███████╗███████║██████╔╝██║     ██║   ██║███████╗"
  echo "  ╚════██║╚════██║██╔══██║██╔═══╝ ██║     ██║   ██║╚════██║"
  echo "  ███████║███████║██║  ██║██║     ███████╗╚██████╔╝███████║"
  echo "  ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚══════╝"
  echo -e "${NC}"
  echo -e "${WHITE}            PANEL WEB MANAGER - Instalador v2.2${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
}

# ─── MENÚ PRINCIPAL ─────────────────────────────────────────
show_menu() {
  show_banner
  echo ""
  echo -e "${WHITE}  Selecciona una opción:${NC}"
  echo ""
  echo -e "  ${CYAN}[1]${NC} Instalar SSHPLUS"
  echo -e "  ${CYAN}[2]${NC} Instalar Panel Web (HTTP)"
  echo -e "  ${CYAN}[3]${NC} Instalar SSL con Let's Encrypt (HTTPS)"
  echo -e "  ${CYAN}[4]${NC} Instalación Completa (SSHPLUS + Panel + SSL)"
  echo -e "  ${CYAN}[5]${NC} Actualizar Panel (Verificar nueva versión)"
  echo -e "  ${CYAN}[6]${NC} Renovar Certificado SSL"
  echo -e "  ${CYAN}[7]${NC} Usar certificado existente de acme.sh"
  echo -e "  ${RED}[0]${NC} Salir"
  echo ""
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo -ne "${WHITE}  ¿QUÉ DESEAS HACER? : ${NC}"
  
  # CORRECCIÓN CRÍTICA: read -r evita problemas con barras invertidas
  read -r OPTION
  # Elimina caracteres de retorno de carro (\r) ocultos que causan el bucle infinito
  OPTION="${OPTION//$'\r'/}"
}

# ─── FUNCIONES COMUNES ───────────────────────────────────────
check_apache() {
  echo -e "${YELLOW}  Verificando Apache2...${NC}"
  if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}  ✓ Apache2 activo${NC}"
  else
    echo -e "${YELLOW}  ⚠ Instalando Apache2...${NC}"
    apt-get update -qq
    apt-get install -y apache2 -qq
    systemctl start apache2
    systemctl enable apache2
    echo -e "${GREEN}  ✓ Apache2 instalado${NC}"
  fi
  APACHE_USER=$(ps aux | grep apache2 | grep -v root | grep -v grep | head -1 | awk '{print $1}')
  APACHE_USER=${APACHE_USER:-www-data}
  sed -i 's/^\s*Listen 443/#Listen 443/' /etc/apache2/ports.conf
  echo -e "${GREEN}  ✓ Puerto 443 desactivado en Apache (evita conflicto con V2Ray)${NC}"
}

check_php() {
  echo -e "${YELLOW}  Verificando PHP...${NC}"
  if ! command -v php &>/dev/null; then
    echo -e "${YELLOW}  ⚠ Instalando PHP...${NC}"
    apt-get install -y php libapache2-mod-php -qq
    systemctl restart apache2
  fi
  if ! apache2ctl -M 2>/dev/null | grep -q php; then
    apt-get install -y libapache2-mod-php -qq
    systemctl restart apache2
  fi
  apt-get install -y curl -qq
  echo -e "${GREEN}  ✓ PHP activo${NC}"
}

check_sshplus() {
  if [ ! -d "/etc/SSHPlus" ]; then
    echo -e "${RED}  ✗ SSHPLUS no está instalado${NC}"
    echo -ne "${WHITE}  ¿Deseas instalarlo ahora? (s/n): ${NC}"
    read -r INST
    INST="${INST//$'\r'/}"
    if [ "$INST" = "s" ] || [ "$INST" = "S" ]; then
      install_sshplus
    else
      echo -e "${RED}  Instalación cancelada${NC}"
      return 1
    fi
  fi
  return 0
}

set_permissions() {
  echo -e "${YELLOW}  Configurando permisos...${NC}"
  chmod 755 /root
  chmod 777 /etc/SSHPlus/
  chmod 777 /etc/SSHPlus/senha/
  [ -f "/root/usuarios.db" ]        && chmod 666 /root/usuarios.db
  [ -f "/etc/SSHPlus/usuarios.db" ] && chmod 666 /etc/SSHPlus/usuarios.db
  [ ! -f "/root/usuarios.db" ] && touch /root/usuarios.db && chmod 666 /root/usuarios.db
  echo -e "${GREEN}  ✓ Carpeta senha con permisos correctos${NC}"
  
  SUDOERS_LINE="${APACHE_USER} ALL=(ALL) NOPASSWD: /usr/sbin/useradd, /usr/sbin/userdel, /usr/sbin/chpasswd, /usr/bin/chage, /usr/sbin/chage"
  sed -i "/${APACHE_USER} ALL=(ALL) NOPASSWD/d" /etc/sudoers 2>/dev/null
  sed -i '/# SSHPLUS Manager Panel/d' /etc/sudoers 2>/dev/null
  echo "" >> /etc/sudoers
  echo "# SSHPLUS Manager Panel" >> /etc/sudoers
  echo "$SUDOERS_LINE" >> /etc/sudoers
  echo -e "${GREEN}  ✓ Permisos y sudoers configurados${NC}"
  
  RC_LOCAL="/etc/rc.local"
  [ ! -f "$RC_LOCAL" ] && echo '#!/bin/bash' > $RC_LOCAL && echo 'exit 0' >> $RC_LOCAL && chmod +x $RC_LOCAL
  if ! grep -q "SSHPlus Manager" $RC_LOCAL; then
    sed -i '/^exit 0/d' $RC_LOCAL
    cat >> $RC_LOCAL << 'EOF'
# SSHPlus Manager - Permisos
chmod 755 /root
chmod 666 /root/usuarios.db 2>/dev/null
chmod 777 /etc/SSHPlus/ 2>/dev/null
chmod 666 /etc/SSHPlus/usuarios.db 2>/dev/null
chmod 777 /etc/SSHPlus/senha/ 2>/dev/null
exit 0
EOF
  fi
  echo -e "${GREEN}  ✓ Permisos permanentes en rc.local${NC}"
}

ask_password() {
  echo ""
  while true; do
    echo -ne "${WHITE}  Contraseña para el panel web: ${NC}"
    read -r -s PANEL_PASS
    echo ""
    echo -ne "${WHITE}  Confirma la contraseña: ${NC}"
    read -r -s PANEL_PASS2
    echo ""
    
    # Limpiar caracteres ocultos
    PANEL_PASS="${PANEL_PASS//$'\r'/}"
    PANEL_PASS2="${PANEL_PASS2//$'\r'/}"
    
    if [ "$PANEL_PASS" = "$PANEL_PASS2" ] && [ -n "$PANEL_PASS" ]; then
      echo -e "${GREEN}  ✓ Contraseña configurada${NC}"
      mkdir -p /etc/sshplus-panel
      chmod 755 /etc/sshplus-panel
      HASH=$(php -r "echo password_hash('$PANEL_PASS', PASSWORD_BCRYPT);")
      echo "$HASH" > /etc/sshplus-panel/.secret
      chmod 644 /etc/sshplus-panel/.secret
      chown www-data:www-data /etc/sshplus-panel/.secret
      echo -e "${GREEN}  ✓ Contraseña hasheada guardada de forma segura${NC}"
      break
    else
      echo -e "${RED}  ✗ No coinciden o están vacías, intenta de nuevo${NC}"
    fi
  done
}

# ─── DETECCIÓN DE ACTUALIZACIONES ────────────────────────────
check_panel_update() {
  LOCAL_FILE="/var/www/html/sshplus.php"
  TMP_FILE="/tmp/sshplus_panel_check.php"

  if [ ! -f "$LOCAL_FILE" ]; then
    echo -e "${YELLOW}  El panel no está instalado aún.${NC}"
    return 1
  fi

  echo -e "${YELLOW}  Verificando actualizaciones en GitHub...${NC}"
  if curl -fsSL "$PANEL_URL" -o "$TMP_FILE" 2>/dev/null; then
    LOCAL_MD5=$(md5sum "$LOCAL_FILE" | awk '{print $1}')
    REMOTE_MD5=$(md5sum "$TMP_FILE" | awk '{print $1}')

    if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]; then
      echo -e "${GREEN}  ✓ ¡Nueva versión disponible!${NC}"
      rm -f "$TMP_FILE"
      return 0 # Hay actualización
    else
      echo -e "${GREEN}  ✓ Ya tienes la última versión del panel.${NC}"
      rm -f "$TMP_FILE"
      return 1 # No hay actualización
    fi
  else
    echo -e "${RED}  ✗ No se pudo conectar a GitHub para verificar.${NC}"
    return 1
  fi
}

# ─── OPCIÓN 1: INSTALAR SSHPLUS ─────────────────────────────
install_sshplus() {
  show_banner
  echo -e "${WHITE}  [INSTALANDO SSHPLUS]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${YELLOW}  Actualizando sistema...${NC}"
  apt update -y -qq && apt upgrade -y -qq
  echo -e "${GREEN}  ✓ Sistema actualizado${NC}"
  echo ""
  echo -e "${YELLOW}  Descargando e instalando SSHPLUS...${NC}"
  echo -e "${YELLOW}  (Sigue las instrucciones en pantalla)${NC}"
  echo ""
  wget -q https://raw.githubusercontent.com/rogellevi/SSHPLUS/master/Plus -O /tmp/Plus
  chmod 777 /tmp/Plus
  /tmp/Plus
  rm -f /tmp/Plus
  echo ""
  echo -e "${GREEN}  ✓ SSHPLUS instalado${NC}"
  echo ""
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── OPCIÓN 2: INSTALAR PANEL HTTP ──────────────────────────
install_panel() {
  show_banner
  echo -e "${WHITE}  [INSTALANDO PANEL WEB HTTP]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  check_apache
  check_php
  check_sshplus || { echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"; read -r DUMMY; return; }
  ask_password
  
  while true; do
    echo -ne "${WHITE}  Puerto HTTP para el panel (ej: 8080): ${NC}"
    read -r HTTP_PORT
    HTTP_PORT="${HTTP_PORT//$'\r'/}"
    if [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] && [ "$HTTP_PORT" -ge 1 ] && [ "$HTTP_PORT" -le 65535 ]; then
      if ss -tlnp | grep -q ":${HTTP_PORT} "; then
        echo -e "${RED}  ✗ Puerto ${HTTP_PORT} en uso, elige otro${NC}"
      else
        echo -e "${GREEN}  ✓ Puerto HTTP: ${HTTP_PORT}${NC}"
        break
      fi
    else
      echo -e "${RED}  ✗ Puerto inválido${NC}"
    fi
  done

  if ! grep -q "Listen ${HTTP_PORT}" /etc/apache2/ports.conf; then
    echo "Listen ${HTTP_PORT}" >> /etc/apache2/ports.conf
  fi

  cat > /etc/apache2/sites-enabled/000-default.conf << EOF
<VirtualHost *:${HTTP_PORT}>
DocumentRoot /var/www/html
<Directory /var/www/html>
AllowOverride All
Require all granted
</Directory>
ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
  echo -e "${GREEN}  ✓ Puerto ${HTTP_PORT} configurado en Apache${NC}"
  set_permissions
  
  echo -e "${YELLOW}  Descargando panel desde GitHub...${NC}"
  TMP_FILE="/tmp/sshplus_panel.php"
  if curl -fsSL "$PANEL_URL" -o "$TMP_FILE" 2>/dev/null; then
    cp "$TMP_FILE" /var/www/html/sshplus.php
    chmod 644 /var/www/html/sshplus.php
    rm -f "$TMP_FILE"
    echo -e "${GREEN}  ✓ Panel instalado en /var/www/html/sshplus.php${NC}"
  else
    echo -e "${RED}  ✗ No se pudo descargar el panel desde GitHub${NC}"
    echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
    read -r DUMMY
    return
  fi
  
  sed -i "s|127.0.0.1:8888/server/online|127.0.0.1:${HTTP_PORT}/server/online|g" /var/www/html/sshplus.php
  systemctl restart apache2
  SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  echo ""
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo -e "${GREEN}  ✓ PANEL INSTALADO CORRECTAMENTE${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${WHITE}  URL del panel:${NC}"
  echo -e "${CYAN}  http://${SERVER_IP}:${HTTP_PORT}/sshplus.php${NC}"
  echo ""
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── OPCIÓN 3: INSTALAR SSL ──────────────────────────────────
install_ssl() {
  show_banner
  echo -e "${WHITE}  [CONFIGURANDO SSL - LET'S ENCRYPT]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  while true; do
    echo -ne "${WHITE}  Dominio (ej: panel.midominio.com): ${NC}"
    read -r DOMAIN
    DOMAIN="${DOMAIN//$'\r'/}"
    [ -n "$DOMAIN" ] && echo -e "${GREEN}  ✓ Dominio: ${DOMAIN}${NC}" && break
    echo -e "${RED}  ✗ El dominio no puede estar vacío${NC}"
  done
  while true; do
    echo -ne "${WHITE}  Puerto HTTPS a usar (ej: 8443): ${NC}"
    read -r SSL_PORT
    SSL_PORT="${SSL_PORT//$'\r'/}"
    if [[ "$SSL_PORT" =~ ^[0-9]+$ ]] && [ "$SSL_PORT" -ge 1 ] && [ "$SSL_PORT" -le 65535 ]; then
      if ss -tlnp | grep -q ":${SSL_PORT} "; then
        echo -e "${RED}  ✗ Puerto ${SSL_PORT} en uso, elige otro${NC}"
      else
        echo -e "${GREEN}  ✓ Puerto HTTPS: ${SSL_PORT}${NC}"
        break
      fi
    else
      echo -e "${RED}  ✗ Puerto inválido${NC}"
    fi
  done
  while true; do
    echo -ne "${WHITE}  Email para Let's Encrypt: ${NC}"
    read -r LE_EMAIL
    LE_EMAIL="${LE_EMAIL//$'\r'/}"
    if [[ "$LE_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
      echo -e "${GREEN}  ✓ Email: ${LE_EMAIL}${NC}"
      break
    else
      echo -e "${RED}  ✗ Email inválido${NC}"
    fi
  done
  echo ""
  echo -e "${YELLOW}  Instalando Certbot...${NC}"
  apt-get update -qq
  apt-get install -y certbot python3-certbot-apache curl -qq
  a2enmod ssl -q
  a2enmod rewrite -q
  a2enmod headers -q
  echo -e "${GREEN}  ✓ Certbot instalado${NC}"
  ufw allow 80/tcp >/dev/null 2>&1
  ufw allow ${SSL_PORT}/tcp >/dev/null 2>&1
  SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  DOMAIN_IP=$(dig +short $DOMAIN 2>/dev/null | head -1)
  echo -e "${WHITE}  IP servidor: ${SERVER_IP} | IP dominio: ${DOMAIN_IP}${NC}"
  if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    echo -e "${YELLOW}  ⚠ El dominio no apunta a este servidor${NC}"
    echo -ne "${WHITE}  ¿Continuar de todas formas? (s/n): ${NC}"
    read -r CONTINUE
    CONTINUE="${CONTINUE//$'\r'/}"
    [ "$CONTINUE" != "s" ] && [ "$CONTINUE" != "S" ] && return
  fi
  echo -e "${YELLOW}  Obteniendo certificado SSL...${NC}"
  systemctl stop apache2
  certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "$LE_EMAIL" \
    -d "$DOMAIN" \
    --preferred-challenges http 2>&1
  CERTBOT_STATUS=$?
  systemctl start apache2
  if [ $CERTBOT_STATUS -ne 0 ]; then
    echo -e "${RED}  ✗ Error al obtener certificado SSL${NC}"
    echo -e "${YELLOW}  Verifica que el dominio apunte a este servidor y el puerto 80 esté accesible${NC}"
    echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
    read -r DUMMY
    return
  fi
  echo -e "${GREEN}  ✓ Certificado SSL obtenido${NC}"
  CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
  if ! grep -q "Listen ${SSL_PORT}" /etc/apache2/ports.conf; then
    echo "Listen ${SSL_PORT}" >> /etc/apache2/ports.conf
  fi
  cat > /etc/apache2/sites-enabled/sshplus-ssl.conf << EOF
<VirtualHost *:${SSL_PORT}>
ServerName ${DOMAIN}
DocumentRoot /var/www/html
SSLEngine on
SSLCertificateFile ${CERT_PATH}/fullchain.pem
SSLCertificateKeyFile ${CERT_PATH}/privkey.pem
SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite HIGH:!aNULL:!MD5
SSLHonorCipherOrder on
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
<Directory /var/www/html>
AllowOverride All
Require all granted
</Directory>
ErrorLog \${APACHE_LOG_DIR}/sshplus-ssl-error.log
CustomLog \${APACHE_LOG_DIR}/sshplus-ssl-access.log combined
</VirtualHost>
EOF
  CRON_JOB="0 3 * * * certbot renew --quiet --pre-hook 'systemctl stop apache2' --post-hook 'systemctl start apache2'"
  (crontab -l 2>/dev/null | grep -v certbot; echo "$CRON_JOB") | crontab -
  systemctl restart apache2
  sleep 1
  echo ""
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo -e "${GREEN}  ✓ SSL CONFIGURADO CORRECTAMENTE${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${WHITE}  URL HTTPS del panel:${NC}"
  echo -e "${CYAN}  https://${DOMAIN}:${SSL_PORT}/sshplus.php${NC}"
  echo ""
  echo -e "${WHITE}  Renovación automática:${NC} ${GREEN}Activa (cada 90 días)${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── OPCIÓN 4: INSTALACIÓN COMPLETA ─────────────────────────
install_complete() {
  show_banner
  echo -e "${WHITE}  [INSTALACIÓN COMPLETA]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${WHITE}  Se instalará:${NC}"
  echo -e "  ${GREEN}✓${NC} SSHPLUS"
  echo -e "  ${GREEN}✓${NC} Apache + PHP"
  echo -e "  ${GREEN}✓${NC} Panel Web"
  echo -e "  ${GREEN}✓${NC} SSL Let's Encrypt"
  echo ""
  echo -ne "${WHITE}  ¿Confirmas la instalación completa? (s/n): ${NC}"
  read -r CONFIRM
  CONFIRM="${CONFIRM//$'\r'/}"
  [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ] && return
  install_sshplus
  install_panel
  install_ssl
}

# ─── OPCIÓN 5: ACTUALIZAR PANEL (INTELIGENTE) ───────────────
update_panel() {
  show_banner
  echo -e "${WHITE}  [ACTUALIZAR PANEL WEB]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  
  if ! check_panel_update; then
    echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
    read -r DUMMY
    return
  fi

  echo -ne "${WHITE}  ¿Deseas instalar la actualización? (s/n): ${NC}"
  read -r CONFIRM
  CONFIRM="${CONFIRM//$'\r'/}"
  [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ] && return

  if [ -f "/etc/sshplus-panel/.secret" ]; then
    echo -e "${GREEN}  ✓ Contraseña hasheada existente conservada${NC}"
  else
    echo -e "${YELLOW}  ⚠ No se encontró contraseña previa. Configura una nueva.${NC}"
    ask_password
  fi

  cp /var/www/html/sshplus.php /root/sshplus_backup_$(date +%Y%m%d_%H%M%S).php 2>/dev/null
  echo -e "${GREEN}  ✓ Backup creado en /root/${NC}"
  
  echo -e "${YELLOW}  Descargando panel desde GitHub...${NC}"
  TMP_FILE="/tmp/sshplus_panel.php"
  if curl -fsSL "$PANEL_URL" -o "$TMP_FILE" 2>/dev/null; then
    cp "$TMP_FILE" /var/www/html/sshplus.php
    chmod 644 /var/www/html/sshplus.php
    rm -f "$TMP_FILE"
    echo -e "${GREEN}  ✓ Panel actualizado correctamente${NC}"
  else
    echo -e "${RED}  ✗ No se pudo descargar el panel desde GitHub${NC}"
  fi
  
  systemctl restart apache2
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── OPCIÓN 6: RENOVAR SSL ───────────────────────────────────
renew_ssl() {
  show_banner
  echo -e "${WHITE}  [RENOVANDO CERTIFICADO SSL]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${YELLOW}  Renovando certificado...${NC}"
  systemctl stop apache2
  certbot renew 2>&1
  systemctl start apache2
  echo ""
  echo -e "${GREEN}  ✓ Proceso de renovación completado${NC}"
  echo ""
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── OPCIÓN 7: USAR CERTIFICADO ACME.SH ────────────────────
use_acme_cert() {
  show_banner
  echo -e "${WHITE}  [USAR CERTIFICADO EXISTENTE DE ACME.SH]${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${YELLOW}  Certificados disponibles en acme.sh:${NC}"
  echo ""
  ~/.acme.sh/acme.sh --list 2>/dev/null || echo -e "${RED}  acme.sh no instalado${NC}"
  echo ""
  while true; do
    echo -ne "${WHITE}  Dominio del certificado (ej: v2ray.cloudgt.xyz): ${NC}"
    read -r ACME_DOMAIN
    ACME_DOMAIN="${ACME_DOMAIN//$'\r'/}"
    [ -n "$ACME_DOMAIN" ] && break
    echo -e "${RED}  ✗ El dominio no puede estar vacío${NC}"
  done
  if [ -d "$HOME/.acme.sh/${ACME_DOMAIN}_ecc" ]; then
    CERT_DIR="$HOME/.acme.sh/${ACME_DOMAIN}_ecc"
  elif [ -d "$HOME/.acme.sh/${ACME_DOMAIN}" ]; then
    CERT_DIR="$HOME/.acme.sh/${ACME_DOMAIN}"
  else
    echo -e "${RED}  ✗ No se encontró certificado para ${ACME_DOMAIN}${NC}"
    echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
    read -r DUMMY
    return
  fi
  CERT_FILE="${CERT_DIR}/fullchain.cer"
  KEY_FILE="${CERT_DIR}/${ACME_DOMAIN}.key"
  if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}  ✗ Archivos de certificado no encontrados en ${CERT_DIR}${NC}"
    echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
    read -r DUMMY
    return
  fi
  echo -e "${GREEN}  ✓ Certificado encontrado en: ${CERT_DIR}${NC}"
  while true; do
    echo -ne "${WHITE}  Puerto HTTPS a usar (ej: 8443): ${NC}"
    read -r SSL_PORT
    SSL_PORT="${SSL_PORT//$'\r'/}"
    if [[ "$SSL_PORT" =~ ^[0-9]+$ ]] && [ "$SSL_PORT" -ge 1 ] && [ "$SSL_PORT" -le 65535 ]; then
      if ss -tlnp | grep -q ":${SSL_PORT} "; then
        echo -e "${RED}  ✗ Puerto ${SSL_PORT} en uso, elige otro${NC}"
      else
        echo -e "${GREEN}  ✓ Puerto HTTPS: ${SSL_PORT}${NC}"
        break
      fi
    else
      echo -e "${RED}  ✗ Puerto inválido${NC}"
    fi
  done
  apt-get install -y curl -qq
  a2enmod ssl -q
  a2enmod rewrite -q
  a2enmod headers -q
  if ! grep -q "Listen ${SSL_PORT}" /etc/apache2/ports.conf; then
    echo "Listen ${SSL_PORT}" >> /etc/apache2/ports.conf
  fi
  cat > /etc/apache2/sites-enabled/sshplus-ssl.conf << EOF
<VirtualHost *:${SSL_PORT}>
ServerName ${ACME_DOMAIN}
DocumentRoot /var/www/html
SSLEngine on
SSLCertificateFile ${CERT_FILE}
SSLCertificateKeyFile ${KEY_FILE}
SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite HIGH:!aNULL:!MD5
SSLHonorCipherOrder on
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
<Directory /var/www/html>
AllowOverride All
Require all granted
</Directory>
ErrorLog \${APACHE_LOG_DIR}/sshplus-ssl-error.log
CustomLog \${APACHE_LOG_DIR}/sshplus-ssl-access.log combined
</VirtualHost>
EOF
  echo -e "${GREEN}  ✓ VirtualHost SSL creado${NC}"
  CRON_JOB="0 3 * * * $HOME/.acme.sh/acme.sh --cron --home $HOME/.acme.sh > /dev/null"
  (crontab -l 2>/dev/null | grep -v "acme.sh --cron"; echo "$CRON_JOB") | crontab -
  echo -e "${GREEN}  ✓ Renovación automática configurada${NC}"
  systemctl restart apache2
  sleep 1
  echo ""
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo -e "${GREEN}  ✓ SSL CON ACME.SH CONFIGURADO CORRECTAMENTE${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "${WHITE}  URL HTTPS del panel:${NC}"
  echo -e "${CYAN}  https://${ACME_DOMAIN}:${SSL_PORT}/sshplus.php${NC}"
  echo ""
  echo -e "${WHITE}  Certificado:${NC} ${CYAN}${CERT_DIR}${NC}"
  echo -e "${WHITE}  Renovación automática:${NC} ${GREEN}Activa${NC}"
  echo -e "${BLUE}  ─────────────────────────────────────────────────${NC}"
  echo ""
  echo -ne "${WHITE}  Presiona Enter para continuar...${NC}"
  read -r DUMMY
}

# ─── LOOP PRINCIPAL ─────────────────────────────────────────
while true; do
  show_menu
  case $OPTION in
    1) install_sshplus ;;
    2) install_panel ;;
    3) install_ssl ;;
    4) install_complete ;;
    5) update_panel ;;
    6) renew_ssl ;;
    7) use_acme_cert ;;
    0) echo -e "${GREEN}  ¡Hasta luego!${NC}"; echo ""; exit 0 ;;
    *) echo -e "${RED}  ✗ Opción inválida. Por favor, ingresa un número del 0 al 7.${NC}"; sleep 1 ;;
  esac
done