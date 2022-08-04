#!/bin/bash
docker run -itd --name postgres -e POSTGRES_DB=food -e POSTGRES_PASSWORD=password -v ./db:/var/lib/postgresql postgres:13
