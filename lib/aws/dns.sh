add_dns_host() {
  local zone_id="${1}"
  local hostname="${2}"
  local address="${3}"
  local dns_comment="${4}"
  local change_batch=`mktemp -t prepare.dns.zonefile`

  cat > ${change_batch} <<CHANGES
    {
      "Comment":"$dns_comment",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${address}"
              }
            ],
            "Name":"${hostname}",
            "Type": "A",
            "TTL":$dns_ttl
          }
        }
      ]
    }
CHANGES

  aws route53 change-resource-record-sets --hosted-zone-id ${zone_id} --change-batch file://"${change_batch}"
}

add_dns_alias() {
  local zone_id="${1}"
  local alias="${2}"
  local host="${3}"
  local comment="${4}"
  local change_batch=`mktemp -t prepare.dns.zonefile`

  cat > ${change_batch} <<CHANGES
    {
      "Comment":"$comment",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value": "${host}"
              }
            ],
            "Name":"${alias}",
            "Type": "CNAME",
            "TTL":$dns_ttl
          }
        }
      ]
    }
CHANGES

  aws route53 change-resource-record-sets --hosted-zone-id ${zone_id} --change-batch file://"${change_batch}"
}
