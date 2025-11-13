release_names=("$@")



# Get all failed helm releases

failed_releases=$(helm ls --failed --all-namespaces --output json | jq -r '.[] | .name')



print_pod_details() {

    pod_names=("$@")

    # Loop through each pod and get its events

    for pod in $pod_names; do

        

        # Capture the events for the pod

        pod_events=$(kubectl get events --field-selector involvedObject.name="$pod" -o json -n "$kubernetes_namespace" | jq -r '.items[] | "\(.lastTimestamp): \(.message)"')



        echo "::group::Events for pod: $pod"

        echo "$pod_events"

        echo "::endgroup::"



        # Get the containers in the pod

        containers=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].name}' -n "$kubernetes_namespace")



        # Loop through each container and get logs

        for container in $containers; do

            # Capture the logs for the container

            pod_logs=$(kubectl logs "$pod" -c "$container" -n "$kubernetes_namespace" --tail 200)



            echo "::group::Logs for container: $container in pod: $pod"

            echo "$pod_logs"

            echo "::endgroup::"

        done

    done

}



# Loop through each release name in the array

for release in "${release_names[@]}"; do

    # Check if the release is in the list of failed releases

    if echo "$failed_releases" | grep -q "^$release$"; then

        config_file_path="${CONFIGS_ROOT_PATH}/${release}/${CONFIG_FILE_NAME}"

        kubernetes_namespace=$(yq -r '.deployment.namespaceOverride // env(K8S_NAMESPACE)' "${config_file_path}" || echo "${K8S_NAMESPACE}")



        echo "Details of failed release ${release} in namespace ${kubernetes_namespace}:"



        # Capture the output of helm status

        status_output=$(helm status --show-resources "$release" -n "$kubernetes_namespace")



        echo "::group::Helm status for release: $release"

        echo "$status_output"

        echo "::endgroup::"

        

        echo "Details of service pods:"

        service_pods=$(kubectl get pods -l "service=$release" -o jsonpath='{.items[*].metadata.name}' -n "$kubernetes_namespace")

        print_pod_details "$service_pods"



        echo "Details of post-deploy pods:"

        post_deploy_pods=$(kubectl get pods -l "workbench.pwc.com/post-deploy-for-service=$release" -o jsonpath='{.items[*].metadata.name}' -n "$kubernetes_namespace")

        print_pod_details "$post_deploy_pods"



        echo "Details of ExternalSecret:"

        external_secret_status=$(kubectl get ExternalSecret "$release" -o jsonpath='{.status}' -n "$kubernetes_namespace" | jq)

        echo "::group::Status of ExternalSecret: $release"

        echo "$external_secret_status"

        echo "::endgroup::"



        external_secret_events=$(kubectl get events --field-selector involvedObject.kind=ExternalSecret --field-selector involvedObject.name="$release" -o json -n "$kubernetes_namespace" | jq -r '.items[] | "\(.lastTimestamp): \(.message)"')

        echo "::group::Events for ExternalSecret: $release"

        echo "$external_secret_events"

        echo "::endgroup::"

    fi

done

