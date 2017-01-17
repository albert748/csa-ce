#!/bin/bash
set -e -x

oouser=$1
password=$2
url=$3

ipaddress=$(ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://')

service=/usr/local/hp/oo/central/bin/central
oosh=/usr/local/hp/oo/central/bin/oosh

# start server
export PATH=.:/usr/local/hp/oo/java/bin:$PATH
sudo -u postgres /usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql/9.3/main -c config_file=/etc/postgresql/9.3/main/postgresql.conf &
#sleep 30
cd /usr/local/hp/oo/central/var/security
mv /usr/local/hp/oo/central/var/security/key.store /usr/local/hp/oo/central/var/security/key.store_orig

keytool -noprompt -genkey -dname "CN=${HOSTNAME}, OU=HPE, O=HPE, L=Palo Alto, ST=CA, C=US" -keyalg RSA  -alias tomcat -keystore key.store -storepass changeit -keypass changeit -validity 3600 -keysize 2048  -ext SAN=IP:${ipaddress}
keytool -exportcert -file /tmp/oodocker.crt  -alias tomcat -keystore key.store -storepass changeit
cp /tmp/oodocker.crt  /share

echo "jdbc.url=jdbc\:postgresql\://$HOSTNAME\:5432/oodb" >> /usr/local/hp/oo/central/conf/database.properties

${service} stop
${service} start

while true
do
    # HPE Operations Orchestration Central is running: PID:1732, Wrapper:STARTED, Java:STARTED
    status=$(${service} status | grep -E ".*is running.*?STARTED.*?STARTED$")
    if [ -z "${status}" ]; then
        sleep 3
    else
        break
    fi
done

# recover from admin
# to resolve oosh error "unable to deploy, reason: 401 Unauthorized"
sudo -u postgres -- psql -d oodb -c "BEGIN;INSERT INTO oo_users(id, username, password, enabled, salt) VALUES(114300001, 'admin', '0OSSMv1jCFJIV5zHbZIiH9Vw4HM=', 't', 'UytTfdIKjxyOtC6REUq5eNA88lWej4EXus6uGUKjI98=');INSERT INTO oo_users_roles(user_id, role_id) VALUES(114300001, 104600004);INSERT INTO oo_users_roles(user_id, role_id) VALUES(114300001, 104600001);COMMIT;"

## upload sequence
#oo10-base-cp-1.8.0.jar
#oo10-cloud-cp-1.8.2.jar
#oo10-hp-solutions-cp-1.7.0.jar
#oo10-virtualization-cp-1.8.0.jar
#oo10-sa-cp-1.2.2.jar
#oo10-sm-cp-1.0.3.jar

#internal_contents=(oo10-base-cp oo10-cloud-cp oo10-hp-solutions-cp oo10-virtualization-cp oo10-sa-cp oo10-sm-cp)
cp_files_internal=('oo10-base-cp-1.8.0.jar' 'oo10-cloud-cp-1.8.2.jar' 'oo10-hp-solutions-cp-1.7.0.jar' 'oo10-virtualization-cp-1.8.0.jar' 'oo10-sa-cp-1.2.2.jar' 'oo10-sm-cp-1.0.3.jar')

# Get content packs list
for file in $(find /tmp/image_deploy -name "*.jar"); do
    file=$(basename ${file})
    for f in ${cp_files_internal[@]}; do
        if [ "${f}" == "${file}" ]; then
            is_internal=true
            break
        fi
    done

    if [ "${is_internal}" == "true" ]; then
        continue
    fi

    if [ -z "${cp_files}" ]; then
        cp_files=$file
    else
        cp_files=$cp_files,$file
    fi
done

target=https://${ipaddress}:8443/oo

# wait until rest API server up, otherwise cp injection will not happen.
#echo $(curl --insecure -c /usr/local/hp/oo/content/cookie.txt -X GET ${target}/rest/version)

# list all
#${oosh} lcp --user ${oouser} --password ${password} --url ${target}

cd /tmp/image_deploy

result=$(${oosh} deploy --user ${oouser} --password ${password} --url ${target} --files oo10-base-cp-1.8.0.jar,oo10-cloud-cp-1.8.2.jar,oo10-hp-solutions-cp-1.7.0.jar,oo10-virtualization-cp-1.8.0.jar,oo10-sa-cp-1.2.2.jar,oo10-sm-cp-1.0.3.jar)

if [ "${result}" != "all content packs deployed" ]; then
    exit 1
fi

result=$(${oosh} deploy --user ${oouser} --password ${password} --url ${target} --files ${cp_files})

if [ "${result}" != "all content packs deployed" ]; then
    exit 1
fi

#sudo -u postgres -- /usr/lib/postgresql/9.3/bin/pg_dump oodb > /tmp/pg_dump.oodb

#tail -f /usr/local/hp/oo/central/var/logs/server.log

#for cp in $(find /tmp/image_deploy -name "*.jar"); do
#    #curl --insecure -c /usr/local/hp/oo/content/cookie.txt -X GET http://${target}/oo/rest/version
#    token=$(cat /usr/local/hp/oo/content/cookie.txt|grep X-CSRF-TOKEN-OO| sed 's/^.*X-CSRF-TOKEN-OO\s*//')
#    curl --insecure -b /usr/local/hp/oo/content/cookie.txt -H "Content-Type: application/json" -H "X-CSRF-Token: $token" -X PUT -T ${cp} ${target}/rest/latest/content-packs/$(basename ${cp})
#
#done

# if database was not properly shutdown, crash-recovery will be
# performed, and all data will be lost.
# sudo -u postgres -- /usr/lib/postgresql/9.3/bin/psql -d oodb -c "COMMIT;"
sudo -u postgres -- /usr/lib/postgresql/9.3/bin/pg_ctl -m fast -t 120 -D /var/lib/postgresql/9.3/main stop

# clean temp files.
rm -rf /tmp/image_deploy