#!/bin/bash
set -e

source .env

flask db stamp head

flask db migrate

flask db upgrade