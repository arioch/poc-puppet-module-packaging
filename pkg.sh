#!/bin/sh

DATE=$(date '+%Y%m%d%H%M')
MODULE=${2:-stdlib}
PUPPET_ENVIRONMENT=${1:-production}

MODULE_NAME=$(
  grep -i ^name modules/${MODULE}/Modulefile \
    | sed -e "s+\"+'+g" \
    | cut -d "'" -f2 \
    | cut -d '-' -f2
)
MODULE_VERSION=$(
  grep -i ^version modules/${MODULE}/Modulefile \
    | sed -e "s+\"+'+g" \
    | cut -d "'" -f2
)
MODULE_LICENSE=$(
  grep -i ^license modules/${MODULE}/Modulefile \
    | sed -e "s+\"+'+g" \
    | cut -d "'" -f2
)
MODULE_DESCRIPTION=$(
  grep -i ^description modules/${MODULE}/Modulefile \
    | sed -e "s+\"+'+g" \
    | cut -d "'" -f2
)

if [ -n "$(grep -i ^dependency modules/${MODULE}/Modulefile)" ]
then
  DEPENDENCY_NAME=$(
    grep -i ^dependency modules/${MODULE}/Modulefile \
      | sed -e "s+\"+'+g" \
      | cut -d "'" -f2 \
      | cut -d '/' -f2
  )
  DEPENDENCY_VERSION=$(
    grep -i ^dependency modules/${MODULE}/Modulefile \
      | sed -e "s+\"+'+g" \
      | cut -d "'" -f4
  )

  for DEPENDENCY_NAME in $(
    grep -i dependency modules/${MODULE}/Modulefile \
      | sed -e "s+\"+'+g" \
      | cut -d "'" -f2 \
      | cut -d '/' -f2
    )
  do
    DEPENDENCY_VERSION=$(grep -iE '^dependency.*\'$DEPENDENCY_NAME modules/${MODULE}/Modulefile \
      | sed -e "s+\"+'+g" \
      | cut -d ',' -f2 \
      | cut -d "'" -f2
    )

    if [ -n "${DEPENDENCY_VERSION}" ]
    then
      if [ -n "${DEPENDENCY_VERSION}" ]
      then
        FPM_DEPENDS="${DEPS} --depends 'puppet-module-${PUPPET_ENVIRONMENT}-${DEPENDENCY_NAME} ${DEPENDENCY_VERSION}'"
      else
        FPM_DEPENDS="--depends 'puppet-module-${PUPPET_ENVIRONMENT}-${DEPENDENCY_NAME} ${DEPENDENCY_VERSION}'"
      fi
    else
      if [ -n "${DEPENDENCY_VERSION}" ]
      then
        FPM_DEPENDS="${DEPS} --depends 'puppet-module-${PUPPET_ENVIRONMENT}-${DEPENDENCY_NAME}'"
      else
        FPM_DEPENDS="--depends 'puppet-module-${PUPPET_ENVIRONMENT}-${DEPENDENCY_NAME}'"
      fi
    fi
  done
fi

pre_build() {
  [   -d .build ] && rm -rf .build
  [ ! -d .build ] && mkdir .build

  cp -r modules/${MODULE} .build/

  rm -rf .build/${MODULE}/*.lock
  rm -rf .build/${MODULE}/*.swp
  rm -rf .build/${MODULE}/.fixtures.yml
  rm -rf .build/${MODULE}/.gem*
  rm -rf .build/${MODULE}/.git*
  rm -rf .build/${MODULE}/.project
  rm -rf .build/${MODULE}/.puppet-lint.rc
  rm -rf .build/${MODULE}/.rspec
  rm -rf .build/${MODULE}/.travis.yml
  rm -rf .build/${MODULE}/.vim*
  rm -rf .build/${MODULE}/Gemfile
  rm -rf .build/${MODULE}/Rakefile
  rm -rf .build/${MODULE}/spec
  rm -rf .build/${MODULE}/tests
}

post_build() {
  [ -d .build ] && rm -rf .build
}

build_rhel() {
  pre_build
  fpm -s dir -t rpm \
    --architecture all \
    -n puppet-module-${PUPPET_ENVIRONMENT}-${MODULE_NAME} \
    -v ${MODULE_VERSION} \
    --license "${MODULE_LICENSE}" \
    --prefix /etc/puppet/environments/${PUPPET_ENVIRONMENT} \
    --description "${MODULE_DESCRIPTION}" \
    ${FPM_DEPENDS} \
    -C .build \
    ${MODULE_NAME}
  post_build
}

build_squeeze() {
  pre_build
  fpm -s dir -t deb \
    --architecture all \
    -n puppet-module-${PUPPET_ENVIRONMENT}-${MODULE_NAME} \
    -v ${MODULE_VERSION}-${DATE}+squeeze1 \
    --license "${MODULE_LICENSE}" \
    --prefix /etc/puppet/environments/${PUPPET_ENVIRONMENT} \
    --description "${MODULE_DESCRIPTION}" \
    ${FPM_DEPENDS} \
    -C .build ${MODULE_NAME}
  post_build
}

build_wheezy() {
  pre_build
  fpm -s dir -t deb \
    --architecture all \
    -n puppet-module-${PUPPET_ENVIRONMENT}-${MODULE_NAME} \
    -v ${MODULE_VERSION}-${DATE}+wheezy1 \
    --license "${MODULE_LICENSE}" \
    --prefix /etc/puppet/environments/${PUPPET_ENVIRONMENT} \
    --description "${MODULE_DESCRIPTION}" \
    ${FPM_DEPENDS} \
    -C .build ${MODULE_NAME}
  post_build
}

build_debian() {
  build_squeeze
  build_wheezy
}

build_debian
build_rhel

