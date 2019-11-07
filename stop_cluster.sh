#!/bin/bash

docker stop master worker0 worker1 worker2

docker container rm master worker0 worker1 worker2

docker volume rm $(docker volume ls -qf dangling=true)

