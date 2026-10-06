### INSTALL SCRIPT SSHPLUS

<pre><code>apt update -y && apt upgrade -y && wget https://raw.githubusercontent.com/rogellevi/SSHPLUS/master/Plus && chmod 777 Plus && ./Plus</code></pre>

### Instalación con Menú
```
wget -qO- https://raw.githubusercontent.com/rogellevi/SSHPLUS/main/install.sh | sed 's/\r$//' | bash
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
