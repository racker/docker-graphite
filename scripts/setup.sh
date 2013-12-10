#!/usr/bin/env bash

# https://gist.github.com/bhang/2703599

set -o errexit
set -o verbose

depsfile=$( tempfile )

cat << EOF > $depsfile
carbon==0.9.10
django-tagging
django==1.3
graphite-web==0.9.10
python-memcached
twisted<12.0
gunicorn
whisper==0.9.10
EOF

pip install -r $depsfile

rm -f $depsfile

pushd /opt/graphite/conf

cp -f carbon.conf.example carbon.conf

cat << EOF > storage-schemas.conf
[stats]
priority = 110
pattern = ^stats\..*
retentions = 10s:6h,1m:7d,10m:1y
EOF

cat <<EOF > storage-aggregation.conf
[min]
pattern = \.lower$
xFilesFactor = 0.1
aggregationMethod = min

[max]
pattern = \.upper$
xFilesFactor = 0.1
aggregationMethod = max

[sum]
pattern = \.sum$
xFilesFactor = 0
aggregationMethod = sum

[count]
pattern = \.count$
xFilesFactor = 0
aggregationMethod = sum

[count_legacy]
pattern = ^stats_counts.*
xFilesFactor = 0
aggregationMethod = sum

[default_average]
pattern = .*
xFilesFactor = 0.3
aggregationMethod = average
EOF

popd

mkdir -p /opt/graphite/storage/log/webapp

pushd /opt/graphite/webapp/graphite

cp -f local_settings.py.example \
      local_settings.py

python manage.py syncdb --noinput

popd

git clone git://github.com/etsy/statsd.git /opt/statsd

pushd /opt/statsd

npm install

cat << EOF > config.js
{
  graphitePort: 2003,
  graphiteHost: "127.0.0.1",
  port: 8125,
  deleteCounters: true,
  flushInterval: 10 * 1000,
  graphite: {
    legacyNamespace: false,
  }
}
EOF

popd
