#!/bin/bash
export PATH=.:/usr/local/hpe/csa/openjre/bin:$PATH
export CSA_HOME=/usr/local/hpe/csa


if grep -q 18444 /usr/local/hpe/csa/jboss-as/standalone/deployments/idm-service.war/WEB-INF/spring/applicationContext.properties
then
        service csa restart
else
        cd /tmp
        rm -f /tmp/csadocker.crt  > /dev/null 2>&1
        rm -f /tmp/csadockerkeystore > /dev/null 2>&1
        service csa stop


        ##########################IDM PART###########################################
        keytool -noprompt -genkey -dname "CN=$dockerclient_hostname, OU=HPE, O=HPE, L=Palo Alto, ST=CA, C=US" -keyalg RSA  -alias csadocker -keystore csadockerkeystore -storepass changeit -keypass changeit -validity 3600 -keysize 2048  -ext SAN=IP:$dockerclient_ipaddress
        sleep 1
        keytool -exportcert -file /tmp/csadocker.crt  -alias csadocker -keystore csadockerkeystore -storepass changeit
        keytool -delete -alias csadocker -keystore /usr/local/hpe/csa/openjre/lib/security/cacerts -storepass changeit -keypass changeit > /dev/null 2>&1
        keytool -noprompt -importcert -file /tmp/csadocker.crt -alias csadocker  -keystore /usr/local/hpe/csa/openjre/lib/security/cacerts -storepass changeit -keypass changeit
        keytool -importkeystore -srckeystore /tmp/csadockerkeystore -deststoretype PKCS12 -destkeystore /tmp/csadockermppkeystore -deststorepass changeit -srckeypass changeit -noprompt -srcstorepass changeit -alias csadocker

        cp /tmp/csadockerkeystore /share
        cp /tmp/csadocker.crt /share
        cp /tmp/csadockermppkeystore /share
		cd /usr/local/hpe/csa/jboss-as/standalone/configuration
        cp /tmp/csadockerkeystore .
		rm jboss.crt
		cp /tmp/csadocker.crt jboss.crt

        echo "changing the keystore in standlaone.xml"
        sed -e 's/\.keystore/csadockerkeystore/' standalone.xml > standalone1.xml
        mv standalone1.xml standalone.xml

 
		echo "adding community edition"
        cd /usr/local/hpe/csa/jboss-as/standalone/deployments/csa.war/WEB-INF/classes
        echo "product.community.edition=true" >> csa.properties
        echo "proxy=$proxy_host_name" >> csa.properties
        echo "proxyPort=$proxy_port" >> csa.properties

        echo "changing applicationContext.properties"
        cd /usr/local/hpe/csa/jboss-as/standalone/deployments/idm-service.war/WEB-INF/spring

        #sed -e "s/localhost/$dockerclient_ipaddress/g" -e "s/8444/18444/g"  -e "s/localhostdb:5432/$db_ipaddress:$db_port/g" applicationContext.properties > applicationContext.properties1
		sed -e "s/localhost/$dockerclient_ipaddress/g" -e "s/8444/18444/g"  applicationContext.properties > applicationContext.properties1
        mv applicationContext.properties1 applicationContext.properties

        echo "changing applicationContext.xml"
        sed -e "s/localhost/$dockerclient_ipaddress/"  applicationContext.xml > applicationContext.xml1
        mv applicationContext.xml1 applicationContext.xml



        ###########################END OF IDM PART####################################

        ############################ CSA PART #########################################


        cd /usr/local/hpe/csa/jboss-as/standalone/deployments/csa.war/WEB-INF

        sed  -e "s/localhost/$dockerclient_ipaddress/" -e "s/8444/18444/" applicationContext-security.xml > applicationContext-security1.xml
        mv applicationContext-security1.xml applicationContext-security.xml


        #sed -e "s/localhost/$dockerclient_ipaddress/" -e "s/8444/18444/" hpssoConfig.xml > hpssoConfig1.xml
        #mv hpssoConfig1.xml hpssoConfig.xml
	cd /usr/local/hpe/csa/jboss-as/standalone/deployments/csa.war/WEB-INF/classes

        sed -e "s/localhost/$dockerclient_ipaddress/" -e "s#8444/idm-service#18444/idm-service#" -e "s/csa\.provider\.port\=8444/csa\.provider\.port\=18444/"   csa.properties > csa1.properties
        mv csa1.properties csa.properties

        cd /usr/local/hpe/csa/jboss-as/standalone/deployments/mpp.war
        sed  -e "s/localhost/$dockerclient_ipaddress/" -e "s/8089/18089/" index.html > index1.html
        mv index1.html index.html

		cd /usr/local/hpe/csa/portal/conf
        sed  -e "s/localhost/$dockerclient_ipaddress/g" -e "s/8444/18444/g" -e "s/:8089/:18089/g" mpp.json > mpp1.json
        mv mpp1.json mpp.json
		
		
        echo "Import OO Certificate"
        cp /share/oodocker.crt /tmp/oodocker.crt
        keytool -delete -alias oodocker -keystore /usr/local/hpe/csa/openjre/lib/security/cacerts -storepass changeit -keypass changeit > /dev/null 2>&1
        keytool -noprompt -importcert -file /tmp/oodocker.crt -alias oodocker  -keystore /usr/local/hpe/csa/openjre/lib/security/cacerts -storepass changeit -keypass changeit

        service csa start
        echo "Starting CSA"
		
		service mpp start
        echo "Starting CSA"


        sleep 2m

        ############################ CSA PART END #########################################

        ##################IDM CHECK PART########################
        dirString=`tail -300 /usr/local/hpe/csa/jboss-as/standalone/log/server.log |  grep "rename"  | sed 's#.*rename \(.*\)#\1#'`

        if [ ! -z "$dirString" -a "$dirString" != " " ]; then
        srcdir=`echo $dirString| awk '{print $dockerclient_hostname}'`
        destdir=`echo $dirString| awk '{print $3}'`
        echo "Src = $srcdir  dest= $destdir "
        mv $srcdir $destdir > /dev/null 2>&1
        service idm restart
        sleep 2m
        else
        echo "IDM Server started successfully"
		fi
		##################IDM CHECK PART END########################

		
		# cp /usr/local/hpe/csa/CSAKit-4.7/OO\ Flow\ Content/10X/oo10-csa-integrations-cp-4.70.0000.jar /usr/local/hpe/csa/oo/OOContentPack/.
		# cp /usr/local/hpe/csa/CSAKit-4.7/OO\ Flow\ Content/10X/EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000.jar /usr/local/hpe/csa/oo/OOContentPack/.
		# cd /usr/local/hpe/csa/oo/OOContentPack
		# chmod 754 oo10-csa-integrations-cp-4.70.0000.jar
		# chmod 754 EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000.jar
			
		cd /usr/local/hpe/csa/oo/OOContentPack
		curl -k  -H "Content-Type: application/json" -H "X-CSRF-Token: $token" -X POST -d '{"username":"admin","password":"cloud","roles":[{"name":"ADMINISTRATOR"},{"name":"SYSTEM_ADMIN"}]}'  https://$dockerclient_ipaddress:18445/oo/rest/latest/users/

		curl -k  -H "Content-Type: application/json" -H "X-CSRF-Token: $token" -X PUT -d '{ "enable":true }'  https://$dockerclient_ipaddress:18445/oo/rest/authns
		
		curl -k -c /usr/local/hpe/csa/oo/OOContentPack/cookie.txt -X GET https://$dockerclient_ipaddress:18445/oo/rest/version
		token=$(cat /usr/local/hpe/csa/oo/OOContentPack/cookie.txt|grep X-CSRF-TOKEN-OO| sed 's/^.*X-CSRF-TOKEN-OO\s*//')
		

		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-base-cp-1.8.0.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-base-cp-1.8.0	
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-cloud-cp-1.8.2.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-cloud-cp-1.8.2
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-hp-solutions-cp-1.7.0.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-hp-solutions-cp-1.7.0
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-virtualization-cp-1.8.0.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-virtualization-cp-1.8.0
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-sa-cp-1.2.2.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-sa-cp-1.2.2
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10-sm-cp-1.0.3.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10-sm-cp-1.0.3	
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/oo10.50-csa-integrations-cp-4.70.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/oo10.50-csa-integrations-cp-4.70.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/oo/OOContentPack/EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/EXISTING-INFRASTRUCTURE-WINDOWS-cp-1.50.0000

		cd /usr/local/hpe/csa/Tools/ComponentTool/contentpacks
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-CONFIG-CP-04.10.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-CONFIG-CP-04.10.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/04.10.0000/CSA-VMWARE-CP-04.10.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-VMWARE-CP-04.10.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/04.20.0000/CSA-AMAZON-CP-04.20.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-AMAZON-CP-04.20.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/04.20.0000/CSA-VMWARE-CP-04.20.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-VMWARE-CP-04.20.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-SA-CP-04.10.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-SA-CP-04.10.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-CHEF-CP-04.60.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-CHEF-CP-04.60.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/EXISTING-INFRASTRUCTURE-CP-4.20.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/EXISTING-INFRASTRUCTURE-CP-4.20.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-Docker-CP-4.20.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-Docker-CP-4.20.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-PUPPET-CP-4.70.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-PUPPET-CP-4.70.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CSA-UTIL-CP-04.50.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CSA-UTIL-CP-04.50.0000
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/csa-hpoo-4.50.0000.jar https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/csa-hpoo-4.50.0000.jar
		curl -k -u admin:cloud -X PUT -T  /usr/local/hpe/csa/Tools/ComponentTool/contentpacks/CODAR-cp-1.60.0000.jar  https://$dockerclient_ipaddress:18445/oo/rest/latest/content-packs/CODAR-cp-1.60.0000.jar
		

		
        echo "Import the oo contents and service blue prints for CSA and Codar"
        cd /usr/local/hpe/csa/Tools/CSLContentInstaller/

        export CSA_HOME=/usr/local/hpe/csa
        export CSA_JRE_HOME=/usr/local/hpe/csa/openjre
        export JAVA_HOME=$CSA_JRE_HOME
        export PATH=$PATH:/sbin

        $CSA_JRE_HOME/bin/java -jar csl-content-installer.jar -silent silent_install.xml
	tail -f /usr/local/hpe/csa/jboss-as/standalone/log/server.log
fi





