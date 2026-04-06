#!/bin/bash
echo "Starting Moodle services..."
sudo service mysql start
sudo service apache2 start
echo "Moodle is running at: http://$(hostname -I | awk '{print $1}')"
