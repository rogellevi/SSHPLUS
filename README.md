### INSTALL SCRIPT SSHPLUS

<pre><code>apt update -y && apt upgrade -y && wget https://raw.githubusercontent.com/rogellevi/SSHPLUS/master/Plus && chmod 777 Plus && ./Plus</code></pre>

#### ROOT Y ABRIR PUERTOS
Primero Teclee : sudo su

Habilitar ROOT
~~~~
wget https://raw.githubusercontent.com/rogellevi/PORT_OC/master/root && bash root
~~~~

Abrir Puertos:

~~~~
wget -O firewall https://raw.githubusercontent.com/rogellevi/PORT_OC/main/firewall && chmod +x firewall && sudo ./firewall
~~~~
