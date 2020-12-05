#!/bin/bash

swift_versions=('5.3' '5.2')
ubuntu_versions=('bionic' 'xenial' 'focal')

for swift_version in ${swift_versions[@]}
do
    for ubuntu_version in ${ubuntu_versions[@]}
    do
      (
      docker build -t brightdigit/mistkit-sql:$swift_version-$ubuntu_version . --build-arg TAG=$swift_version-$ubuntu_version
      docker push brightdigit/mistkit-sql:$swift_version-$ubuntu_version
      ) &
    done
done
wait
