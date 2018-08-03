#!/bin/bash
docker run -d --privileged -p 80:80 -p 5432:5432 --name  openattic openattic-dev 

