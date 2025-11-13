import datetime

import os

import sys

import yaml



def read_file(file_path):

    try:

        with open(file_path, 'r') as file:

            data = yaml.safe_load(file)

            return data

    except FileNotFoundError:

        print(f"Error: The file {file_path} was not found.")

    except yaml.YAMLError as e:

        print(f"Error parsing YAML file: {e}")



def get_overridden_namespace(configs_root_path, config_path, default_namespace):

    try:

        service_config = read_file(os.path.join(configs_root_path, config_path))

        if service_config and service_config.get('deployment') and service_config.get('deployment').get('namespaceOverride'):

            return service_config['deployment']['namespaceOverride']

        else:

            return default_namespace

    except Exception as e:

        print(f"Error reading config file {configs_root_path} {config_path}: {e}")

        return default_namespace



def generate_helmfile_yaml(release_data, latest_data, output_path, environment, k8s_namespace, configs_root_path, configs_root_path_helmfile):

    releases = []

    deployment_timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()



    # First, add entries from rollback (prioritizing rollback versions)

    rollback = release_data.get('rollback', {})

    for service, version in rollback.items():

        config_path = f"{service}/{environment}.yaml"

        namespace = get_overridden_namespace(configs_root_path, config_path, k8s_namespace)

        service_replaced = service.replace("-", "_")

        force = bool(os.getenv(f"FORCE_UPGRADE_{service_replaced}", False))

        releases.append({

            'name': service,

            'namespace': namespace,

            'chart': f'oci://{{{{ requiredEnv "HELM_REGISTRY" }}}}/helm-charts/{service}',

            'version': version,

            'values': [

                f"{configs_root_path_helmfile}/{config_path}"

            ],

            'set': [

                {

                    'name': 'global.environment',

                    'value': environment

                },

                {

                    'name': 'general.deploymentTimestamp',

                    'value': deployment_timestamp

                }

            ],

            'force': force

        })



    # Then, add entries from versions, if not already in rollback

    versions = release_data.get('versions', {})

    for service, version in versions.items():

        config_path = f"{service}/{environment}.yaml"

        namespace = get_overridden_namespace(configs_root_path, config_path, k8s_namespace)

        service_replaced = service.replace("-", "_")

        force = bool(os.getenv(f"FORCE_UPGRADE_{service_replaced}", False))

        if service not in rollback:

            releases.append({

                'name': service,

                'namespace': namespace,

                'chart': f'oci://{{{{ requiredEnv "HELM_REGISTRY" }}}}/helm-charts/{service}',

                'version': version,

                'values': [

                    f"{configs_root_path_helmfile}/{config_path}"

                ],

                'set': [

                    {

                        'name': 'global.environment',

                        'value': environment

                    },

                    {

                        'name': 'general.deploymentTimestamp',

                        'value': deployment_timestamp

                    }

                ],

                'force': force

            })



    # Then, add entries from latest to add remaining services

    latest = latest_data.get('versions', {})

    for service, version in latest.items():

        if service not in rollback and service not in versions:

            config_path = f"{service}/{environment}.yaml"

            namespace = get_overridden_namespace(configs_root_path, config_path, k8s_namespace)

            releases.append({

                'name': service,

                'namespace': namespace,

                'reuseValues': True,

                'chart': f'oci://{{{{ requiredEnv "HELM_REGISTRY"}}}}/helm-charts/{service}',

                'version': version,

                'values': [

                    f"{configs_root_path_helmfile}/{config_path}"

                ],

                'set': [

                    {

                        'name': 'global.environment',

                        'value': environment

                    }

                ]

            })



    helmDefaults = {

        'wait': True,

        'timeout': 900,

        # Workaround for https://github.com/databus23/helm-diff/issues/782

        'diffArgs': ['--no-hooks']

    }



    # Prepare the final data structure

    output_data = {

        'helmDefaults': helmDefaults,

        'releases': releases

    }



    # Write the output YAML file

    try:

        with open(output_path, 'w') as file:

            yaml.dump(output_data, file, default_flow_style=False)

        print(f"Output YAML file generated at {output_path}")

    except Exception as e:

        print(f"Error writing YAML file: {e}")



def main():

    source_file = os.getenv('INPUTS_SOURCE_FILE')

    latest_file = os.getenv('INPUTS_LATEST_FILE')

    target_file = os.getenv('INPUTS_TARGET_FILE')

    environment = os.getenv('INPUTS_ENVIRONMENT')

    k8s_namespace = os.getenv('INPUTS_K8S_NAMESPACE')



    # These defaults are a workaround for when the script is invoked from an old version of workflow file

    configs_root_path = os.getenv('INPUTS_CONFIGS_ROOT_PATH', 'configs')

    configs_root_path_helmfile = os.getenv('INPUTS_CONFIGS_ROOT_PATH_HELMFILE', '../configs')



    if not source_file or not target_file or not latest_file or not environment or not k8s_namespace:

        print("Source, latest, target file, environment or namespace are not set")

        sys.exit(1)



    # Read the release YAML file

    release_data = read_file(source_file)



    # Read the latest YAML file

    latest_data = read_file(latest_file)



    if release_data and latest_data:

        # Generate the output YAML file

        generate_helmfile_yaml(release_data, latest_data, target_file, environment, k8s_namespace, configs_root_path, configs_root_path_helmfile)



if __name__ == '__main__':

    main()

