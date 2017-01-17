# -*- conf -*-

FROM hpsoftware/csa:latest
MAINTAINER Albert Zhou <shengboz@hpe.com>

EXPOSE 8089 8444
VOLUME /share

# copy trial license
#COPY [ "CSACommunityEdition_4.7.xml", "CSACommunityEdition_4.7.pd", "/usr/share/apregid.com.hpe/" ]
#COPY [ "TrialRegistration_CSA Community Edition_4.7.xml", "csa_ce.pd", "/usr/local/hpe/csa/Autopass/" ]
#COPY [ "lsstore.properties", "pd.properties", "/usr/share/com.hp.autopass/" ]

# crack license without check and license banner.
COPY [ "licenseCheck.jsp", "/usr/local/hpe/csa/jboss-as/standalone/deployments/csa.war/html-lib/pages/partials/" ]
COPY [ "index.jsp", "/usr/local/hpe/csa/jboss-as/standalone/deployments/csa.war/dashboard/" ]

CMD [ "/bin/bash", "-c", "sleep 120 && /tmp/csaconfig.sh && tail -f /dev/null"]
