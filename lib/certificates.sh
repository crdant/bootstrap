create_certificate () {
  local certificate_name=${1}
  shift

  request_certificate "${certificate_name}" $*
  # sign_certificate "${common_name}"
}

request_certificate () {
  local common_name=${1}
  shift

  local log_dir=${workdir}/logs

  local address_args=
  if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
      case $1 in
        --domain )
          address_args="${address_args} --domain \"${2}\""
          shift 2
          ;;
        --ip )
          address_args="${address_args} --domain \"${2}\""
          shift 2
          ;;
        * )
          echo "Unrecognized option: $1" 1>&2
          exit 1
          ;;
      esac
    done
  fi

  certbot certonly --server https://acme-v02.api.letsencrypt.org/directory \
    --cert-name "${common_name}" ${address_args} \
    --dns-google --dns-google-credentials ${key_file} --dns-google-propagation-seconds 120 \
    --config-dir ${certbot_dir} --logs-dir ${log_dir} --work-dir ${key_dir}/certbot
}
