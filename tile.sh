#!/usr/bin/env bash
BASEDIR=`dirname $0`
. "${BASEDIR}/lib/env.sh"
. "${BASEDIR}/lib/secrets.sh"
. "${BASEDIR}/lib/generate_passphrase.sh"

pcf_subdomain=pcf.${subdomain}
concourse_team=pcf
concourse_target=${env_id}-${concourse_team}
concourse_url=`./concourse.sh url`
parameter_file="${workdir}/${slug}-upgrade-params.yml"
pipeline_file=${workdir}/pcf-pipelines/upgrade-tile/pipeline.yml

download () {
  product_slug=${1}
  release_version=${2}

  mkdir -p ${workdir}/${product_slug}/${release_version}
  pivnet download-product-files --product-slug ${product_slug} --release-version ${release_version} \
    --glob '*.pivotal' --download-dir=${workdir}/${product_slug}/${release_version} --accept-eula
}

upload () {
  product_slug=${1}
  release_version=${2}

  om -k --target opsman.${pcf_subdomain} --username ${opsman_username} --password ${opsman_password} \
    upload-product --product ${workdir}/${product_slug}/${release_version}/*
}

stage () {
  product_slug=${1}
  release_version=${2}

  om -k --target opsman.${pcf_subdomain} --username ${opsman_username} --password ${opsman_password} \
    stage-product --product-name ${product_slug} --product-version ${release_version}
}

pipeline () {
  local product_slug=${1}
  local release_version=${2}
  local tile_upgrade_pipeline="update-${product_slug}"

  ${BASEDIR}/pcf.sh login

  base_version=$(echo ${release_version} | awk -F. '{print $1 "\." $2 }')
  product_name="$(unzip -p ${workdir}/${product_slug}/${release_version}/* "metadata/*.yml" | egrep "^name: (.+)" | cut -d" " -f 2)"

  cat <<PARAMS > ${parameter_file}
  pivnet_token: ${PIVNET_TOKEN}
  product_version_regex: ^${base_version}\..*$
  opsman_admin_username: ${opsman_username}
  opsman_admin_password: ${opsman_password}
  opsman_domain_or_ip_address: opsman.${pcf_subdomain}
  iaas_type: google
  product_slug: ${product_slug}
  product_name: ${product_name}
PARAMS

  fly --target ${concourse_target} set-pipeline --pipeline ${tile_upgrade_pipeline} \
    --config ${pipeline_file} --load-vars-from ${parameter_file}
}

if [ $# -gt 0 ]; then
  while [ $# -gt 0 ]; do
    case $1 in
      --slug | --product-slug | -p)
        slug=${2}
        shift
        ;;
      --release | --release-version | -r)
        release=${2}
        shift
        ;;
      concourse_login | login )
        login=1
        ;;
      download)
        download=1
        ;;
      pipeline | pipelines )
        pipeline=1
        ;;
      upload )
        upload=1
        ;;
      stage )
        stage=1
        ;;
      deploy )
        download=1
        stage=1
        pipeline=1
        ;;
      * )
        echo "Unrecognized option: $1" 1>&2
        exit 1
        ;;
    esac
    shift
  done
fi

if [ -z "$slug" ] ; then
  echo "Tile not specified. Please provide the argument '-p, --product-slug' with a valid Pivotal Network product slug"
  exit 1
fi

if [ -z "$release" ] ; then
  echo "Version not specified. Please provide the argument '-r, --release-version' with the version you want"
  exit 1
fi

opsman_username=$(${BASEDIR}/pcf.sh secret pcf_opsman_admin_username)
opsman_password=$(${BASEDIR}/pcf.sh secret pcf_opsman_admin_password)

if [ -n "$download" ] ; then
  echo "Download was $download"
  download ${slug} ${release}
fi

if [ -n "$upload" ] ; then
  upload ${slug} ${release}
fi

if [ -n "$stage" ] ; then
  stage ${slug} ${release}
fi

if [ -n "$pipeline" ] ; then
  pipeline ${slug} ${release}
fi
