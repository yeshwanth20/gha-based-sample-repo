import requests

import json

import base64

import sys

import os

import yaml



GITHUB_API_URL = "https://api.github.com"

REPO = "pwc-gx-data-services/wb-gha-release-workflows"

HEADERS = {

    "Accept": "application/vnd.github+json",

    "Authorization": f"Bearer {os.getenv('FAAS_GITHUB_TOKEN')}",

    "X-GitHub-Api-Version": "2022-11-28"

}



def create_branch(repo, branch):  

    # Check if the branch already exists  

    branch_url = f"{GITHUB_API_URL}/repos/{repo}/git/refs/heads/{branch}"  

    response = requests.get(branch_url, headers=HEADERS)  

    if response.status_code == 200:  

        print(f"Branch {branch} already exists")  

        return True  

  

    # Get the SHA from the develop branch  

    url = f"{GITHUB_API_URL}/repos/{repo}/git/refs/heads/develop"  

    print("Getting develop ref")  

    response = requests.get(url, headers=HEADERS)  

    if response.status_code == 200:  

        sha = response.json()['object']['sha']  

        url = f"{GITHUB_API_URL}/repos/{repo}/git/refs"  

        print(f"Creating branch {branch}")  

        data = {  

            "ref": f"refs/heads/{branch}",  # Corrected the typo here  

            "sha": sha  

        }  

        response = requests.post(url, headers=HEADERS, data=json.dumps(data))  

        if response.status_code == 201:  # Check for successful creation  

            return True  

        else:  

            print(f"Failed to create branch {branch}: {response.status_code} {response.text}")  

    else:  

        print(f"Failed to get develop branch SHA: {response.status_code} {response.text}")  

    return False  



def get_repo_file_content(repo, path, branch):

    url = f"{GITHUB_API_URL}/repos/{repo}/contents/{path}"

    if branch:  

        url += f"?ref={branch}"  



    print(f"Getting file from {url}")

    response = requests.get(url, headers=HEADERS)

    if response.status_code == 200:

        return response.json()

    return None



def update_file(repo, path, content, sha, message, branch):

    url = f"{GITHUB_API_URL}/repos/{repo}/contents/{path}"

    print(f"Updating file on {url} with content\n{content}")



    data = {

        "message": message,

        "committer": {

            "name": "GitHub Actions",

            "email": "octocat@github.com"

        },

        "content": base64.b64encode(content.encode()).decode(),

        "sha": sha

    }



    if branch:

        data["branch"] = branch



    response = requests.put(url, headers=HEADERS, data=json.dumps(data))

    return response.status_code in [200, 201]



def main():

    service_name = os.getenv('INPUTS_SERVICE_NAME')

    build_version = os.getenv('INPUTS_BUILD_VERSION')

    file = os.getenv('INPUTS_FILE')

    branch = os.getenv('INPUTS_BRANCH', '')

    repo = os.getenv('INPUTS_REPO', REPO)



    if not service_name or not build_version or not file:

        print("Service name, build version or file are not set")

        sys.exit(1)



    file_path = f"releases/{file}"



    # Fetch YAML

    repo_response_content = get_repo_file_content(repo, file_path, branch)

    if not repo_response_content:

        if branch and not create_branch(repo, branch):  

            print(f"Failed to create or verify branch {branch}")

            sys.exit(1)



        # Check again if the file exists, in case the file was in develop

        repo_response_content = get_repo_file_content(repo, file_path, branch)

        if not repo_response_content:

            print('File not found, will create empty file')

            sha = ""

            data = {}

        else:

            sha = repo_response_content['sha']

            data = yaml.safe_load(base64.b64decode(repo_response_content['content']))

    else:

        sha = repo_response_content['sha']

        data = yaml.safe_load(base64.b64decode(repo_response_content['content']))



    # Check if versions exist

    if 'versions' not in data:  

        data['versions'] = {}



    # Create backup file if INPUTS_BACKUP_FILE is defined

    if 'INPUTS_BACKUP_FILE' in os.environ:

        backup_file = os.getenv('INPUTS_BACKUP_FILE')

        target_path_backup = f"releases/{backup_file}"

        target_repo_backup_response_content = get_repo_file_content(repo, target_path_backup, branch)

        if target_repo_backup_response_content:

            print("Backup file already exists, skipping backup creation")

        else:

            print("Creating backup file")

            target_backup_sha = ""

            if not update_file(repo, target_path_backup, yaml.dump(data, indent=2), target_backup_sha, f"Create {backup_file} file", branch):  

                print("Failed to create backup file")  

                sys.exit(1)



    # Update the service with new version

    data['versions'].update({service_name: build_version}) 



    if not update_file(repo, file_path, yaml.dump(data, indent=2), sha,  

        f"Update {service_name} to version {build_version} in {file}", branch):  

        print("Failed to update file")  

        sys.exit(1)  

  

    print(f"{file} updated successfully")



if __name__ == "__main__":

    main()

