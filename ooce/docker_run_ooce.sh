#!/bin/bash

container=$(docker run -p 18443:8443 -d localhost:5000/ooce)

docker logs -f ${container}