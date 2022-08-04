#!/bin/bash
conduit db generate
conduit db upgrade --connect postgres://postgres:password@127.0.0.1:5432/food
