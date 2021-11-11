#Input Variables
refresh_token="MYTOKEN"
org="MYORGID"
sddc="MYSDDCID"
cluster="Cluster-1"
ingress_cidr="10.130.1.0/24"
egress_cidr="10.130.2.0/24"
service_cidr="10.96.0.0/24"
namespace_cidr="10.244.0.0/21"

#Get Access Token for Authentication
results=$(curl -s -X POST -H "application/x-www-form-urlencoded" "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -d "refresh_token=$refresh_token")
csp_access_token=$(echo $results | jq -r .access_token)

#Get SDDC Resource Config
resource_config=$(curl --location -X GET "vmc.vmware.com/vmc/api/orgs/$org/sddcs/$sddc" --header 'Accept: application/json' --header "csp-auth-token: $csp_access_token" --header 'Content-Type: application/json' | tr '\r\n' ' ' | jq .resource_config)

#Loop Through Clusters looking for Cluster Named $cluster and obtain it's ID
while read i; do
    name=$(echo $i | jq -r .cluster_name)
    if [[ $name = $cluster ]] 
    then
        #Cluster Found - Retrieve ClusterID
        cluster_id=$(echo $i | jq -r .cluster_id)
    fi
    echo $cluster_id
done <<<$(echo $resource_config | tr '\r\n' ' ' | jq -c '.clusters[]')

#Enable TKG Service
echo $cluster_id
curl -L -X POST "http://vmc.vmware.com/api/wcp/v1/orgs/$org/deployments/$sddc/clusters/$cluster_id/operations/enable-wcp" --header 'Accept: application/json' --header "csp-auth-token: $csp_access_token" --header 'Content-Type: application/json' --data-raw '{
    "ingress_cidr": ["'$ingress_cidr'"],
    "egress_cidr": ["'$egress_cidr'"],
    "service_cidr": "'$service_cidr'",
    "namespace_cidr": ["'$namespace_cidr'"]
}'