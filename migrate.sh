#!/bin/bash
conduit db generate
conduit db upgrade --connect postgres://postgres:password@postgres:5432/food
