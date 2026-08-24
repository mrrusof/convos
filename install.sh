#!/bin/bash

cd /tmp
rm -rf convos
git clone http://github.com/mrrusof/convos

cd /tmp/convos
gem build convos.gemspec
gem install *.gem

cd /tmp
rm -rf convos
