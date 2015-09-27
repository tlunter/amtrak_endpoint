#!/bin/bash

set -e

bundle exec app-deployer destroy-old-application amtrak
bundle exec app-deployer start-application amtrak
bundle exec app-deployer update-load-balancer amtrak
