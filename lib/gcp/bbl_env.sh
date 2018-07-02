export BBL_IAAS=${iaas}

if [ -f "${key_file}" ] ; then
  export BBL_GCP_SERVICE_ACCOUNT_KEY=$(cat ${key_file})
elif [ -f "${plan_key_file}" ] ; then
  export BBL_GCP_SERVICE_ACCOUNT_KEY=$(cat ${plan_key_file})
fi

export BBL_GCP_REGION=${region}
