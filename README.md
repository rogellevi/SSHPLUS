# 🚀 SSHPLUS MANAGER - Panel Web & Instalador Completo

![GitHub](https://img.shields.io/github/license/rogellevi/SSHPLUS)
![GitHub last commit](https://img.shields.io/github/last-commit/rogellevi/SSHPLUS)
![Debian/Ubuntu](https://img.shields.io/badge/OS-Debian%2FUbuntu-blue)

**SSHPLUS MANAGER** es un script bash interactivo diseñado para automatizar la instalación y configuración de **SSHPLUS**, un **Panel Web (Apache + PHP)** y la gestión de **Certificados SSL (Let's Encrypt / ACME.sh)** en servidores VPS.

---

## ✨ Características

- 🛠️ **Instalación Automatizada:** Despliega SSHPLUS, Apache2, PHP y dependencias.
- 🌐 **Panel Web:** Interfaz web para gestión de usuarios y conexiones.
- 🔒 **Soporte SSL:** Integración con Let's Encrypt o certificados existentes de `acme.sh`.
- 🛡️ **Seguridad:** Configuración automática de permisos, `sudoers` y puertos.
- 🔄 **Menú Interactivo:** Fácil navegación para instalar, actualizar o renovar componentes.
- ⚡ **Optimizado:** Desactiva el puerto 443 en Apache para evitar conflictos con V2Ray/Stunnel.

---

## 📋 Requisitos Previos

- Sistema Operativo: **Debian** o **Ubuntu** (Recomendado Ubuntu 20.04 / 22.04).
- Acceso **Root** (sudo).
- Un dominio apuntando a la IP de tu servidor (Solo para la opción SSL).

---

## ⚡ Instalación Rápida

Ejecuta el siguiente comando como usuario `root` para iniciar el instalador:

```bash
apt update && apt upgrade -y
wget -qO- https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/install.sh | bash
```
*(Si usas curl: `curl -fsSL https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/install.sh | bash`)*

---

## 📖 Opciones del Menú

Al ejecutar el script, se desplegará un menú con las siguientes opciones:

| Opción | Descripción |
| :---: | :--- |
| **[1]** | **Instalar SSHPLUS:** Descarga e instala el gestor SSHPLUS base. |
| **[2]** | **Instalar Panel Web (HTTP):** Configura Apache, PHP y el panel web en un puerto personalizado. |
| **[3]** | **Instalar SSL (HTTPS):** Obtiene certificado de Let's Encrypt y configura Apache para HTTPS. |
| **[4]** | **Instalación Completa:** Ejecuta las opciones 1, 2 y 3 de forma secuencial y automática. |
| **[5]** | **Actualizar Panel:** Descarga la última versión del panel web conservando tu contraseña. |
| **[6]** | **Renovar SSL:** Fuerza la renovación manual del certificado Let's Encrypt. |
| **[7]** | **Usar ACME.SH:** Configura el panel usando un certificado SSL ya existente generado por acme.sh. |

---

## 🛠️ Estructura y Archivos Importantes

El script configura y utiliza las siguientes rutas en tu servidor:

- **Panel Web:** `/var/www/html/sshplus.php`
- **Contraseña Hasheada:** `/etc/sshplus-panel/.secret`
- **Base de datos de usuarios:** `/root/usuarios.db` o `/etc/SSHPlus/usuarios.db`
- **Configuración SSL:** `/etc/apache2/sites-enabled/sshplus-ssl.conf`

---

## ⚠️ Notas Importantes

1. **Puertos:** El script desactiva automáticamente `Listen 443` en Apache para evitar conflictos si usas proxies como V2Ray o Stunnel en ese puerto.
2. **Dominios:** Para la instalación de SSL, asegúrate de que el dominio (ej. `panel.tudominio.com`) apunte correctamente a la IP de tu VPS antes de ejecutar la opción 3.
3. **Renovación Automática:** El script crea tareas `cron` para renovar los certificados SSL automáticamente cada 90 días.

---

## 🤝 Contribuciones y Soporte

Si encuentras algún error o tienes sugerencias para mejorar el script, ¡las contribuciones son bienvenidas!

- 🐛 **Reportar errores:** [Issues](https://github.com/rogellevi/SSHPLUS/issues)
- 📧 **Contacto / Soporte:** [Tu enlace de Telegram o Discord aquí]

---

## 📜 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.

**¡Gracias por usar SSHPLUS MANAGER!** 🚀




### INSTALL SCRIPT SSHPLUS

<pre><code>apt update -y && apt upgrade -y && wget https://raw.githubusercontent.com/rogellevi/SSHPLUS/master/Plus && chmod 777 Plus && ./Plus</code></pre>

### Instalación con Menú
```
wget -O install.sh https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/install.sh && bash install.sh
```

#### ROOT Y ABRIR PUERTOS
Primero Teclee : sudo su

Habilitar ROOT
~~~~
wget https://raw.githubusercontent.com/rogellevi/SSHPLUS/master/root && bash root
~~~~

Abrir Puertos:

~~~~
wget -O firewall https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/firewall && chmod +x firewall && sudo ./firewall
~~~~
