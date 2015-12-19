mkdir build
node ../cli build \
  --entry-file index.updated.js \
  -o build/tmp_build.zip \
  --dev true \
  --plist-file iOS/Info.plist
cd build
unzip tmp_build.zip
cd build
zip -r ../../build.zip ios.bundle
