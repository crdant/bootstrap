create_certificate () {
  local common_name=${1}
  local org_unit=${2}

  request_certificate ${common_name} ${org_unit}
  sign_certificate ${common_name}
}

request_certificate () {
  local common_name=${1}
  local org_unit=${2}
  shift 2

  local address_args=
  if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
      case $1 in
        domains )
          address_args="${extra_args} --domain ${2}"
          shift
          ;;
        ip )
          address_args="${extra_args} --ip ${2}"
          ;;
        * )
          echo "Unrecognized option: $1" 1>&2
          exit 1
          ;;
      esac
      shift
    done
  fi

  certstrap --depot-path ${ca_dir} request-cert --common-name ${common_name} ${address_args} \
    --country ${country} --province ${state} --locality ${city} \
    --organization ${organization} --organizational-unit ${org_unit}
}

sign_certificate () {
  local common_name=${1}
  certstrap --depot-path ${ca_dir} sign ${common_name} --CA "${ca_name}"
}
