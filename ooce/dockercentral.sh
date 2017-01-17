#!/bin/bash
set -e -x

host=$dockerclient_hostname
ip=$dockerclient_ipaddress
port=$dockerclient_port

export PATH=.:/usr/local/hp/oo/java/bin:$PATH

sudo -u postgres /usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf &
sleep 30
cd /usr/local/hp/oo/central/var/security
mv /usr/local/hp/oo/central/var/security/key.store /usr/local/hp/oo/central/var/security/key.store_orig

keytool -noprompt -genkey -dname "CN=${host}, OU=HPE, O=HPE, L=Palo Alto, ST=CA, C=US" -keyalg RSA  -alias tomcat -keystore key.store -storepass changeit -keypass changeit -validity 3600 -keysize 2048  -ext SAN=IP:${ip}
sleep 1
keytool -exportcert -file /tmp/oodocker.crt  -alias tomcat -keystore key.store -storepass changeit
cp /tmp/oodocker.crt  /share

echo "jdbc.url=jdbc\:postgresql\://$HOSTNAME\:5432/oodb" >> /usr/local/hp/oo/central/conf/database.properties

/usr/local/hp/oo/central/bin/central start

# configure and import content packs
cp_dir=/tmp
curl -k  -H "Content-Type: application/json" -H "X-CSRF-Token: $token" -X POST -d '{"username":"admin","password":"cloud","roles":[{"name":"ADMINISTRATOR"},{"name":"SYSTEM_ADMIN"}]}'  https://${ip}:${port}/oo/rest/latest/users/

curl -k  -H "Content-Type: application/json" -H "X-CSRF-Token: $token" -X PUT -d '{ "enable":true }'  https://${ip}:${port}/oo/rest/authns

curl -k -c ${cp_dir}/cookie.txt -X GET https://${ip}:${port}/oo/rest/version
token=$(cat ${cp_dir}/cookie.txt|grep X-CSRF-TOKEN-OO| sed 's/^.*X-CSRF-TOKEN-OO\s*//')

curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-base-cp-1.8.0.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-base-cp-1.8.0
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-cloud-cp-1.8.2.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-cloud-cp-1.8.2
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-hp-solutions-cp-1.7.0.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-hp-solutions-cp-1.7.0
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-virtualization-cp-1.8.0.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-virtualization-cp-1.8.0
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-sa-cp-1.2.2.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-sa-cp-1.2.2
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10-sm-cp-1.0.3.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10-sm-cp-1.0.3
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/oo10.50-csa-integrations-cp-4.70.0000.jar https://${ip}:${port}/oo/rest/latest/content-packs/oo10.50-csa-integrations-cp-4.70.0000
curl -k -u admin:cloud -X PUT -T  ${cp_dir}/EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000.jar https://${ip}:${port}/oo/rest/latest/content-packs/EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000


tail -f  /usr/local/hp/oo/central/var/logs/server.log