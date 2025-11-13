import requests

import json

import base64

import sys

import os

import yaml

import time



MAX_RETRIES = 3  

RETRY_DELAY = 2  # seconds  



GITHUB_API_URL = "https://api.github.com"

REPO = "pwc-gx-data-services/faas-gha-release-workflows"

HEADERS = {

    "Accept": "application/vnd.github+json",

    "Authorization": f"Bearer {os.getenv('FAAS_GITHUB_TOKEN')}",

    "X-GitHub-Api-Version": "2022-11-28"

}



def get_repo_file_content(repo, path):

    url = f"{GITHUB_API_URL}/repos/{repo}/contents/{path}"

    print(f"Getting file from {url}")

    response = requests.get(url, headers=HEADERS)

    if response.status_code == 200:

        return response.json()

    return None



def update_file_with_retries(repo, path, content, sha, message):  

    attempt = 0  

    while attempt < MAX_RETRIES:  

        if update_file(repo, path, content, sha, message):  

            return True  

        else:  

            print(f"Attempt {attempt + 1} failed, retrying after {RETRY_DELAY} seconds...")  

            attempt += 1  

            time.sleep(RETRY_DELAY)  

    return False  



def update_file(repo, path, content, sha, message):

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

    response = requests.put(url, headers=HEADERS, data=json.dumps(data))



    if response.status_code == 409:  

        # Handle conflict here, possibly by fetching the latest SHA and retrying  

        print("Conflict detected, fetching latest file version...")  

        latest_content = get_repo_file_content(repo, path)  

        if not latest_content:  

            print("Failed to fetch the latest file after conflict")  

            return False  

        sha = latest_content['sha']  # Update the SHA to the latest



    return response.status_code in [200, 201]



def version_data_to_markdown_table(data):



    # Extract the header

    headers = ["Service", "Version"]



    # Create the markdown table header

    header_row = '| ' + ' | '.join(headers) + ' |'

    separator_row = '| ' + ' | '.join(['---'] * len(headers)) + ' |'



    # Create the markdown table rows

    version_rows = []

    versions = data.get('versions', {})

    for service, version in versions.items():

        row = f'| {service} | {version} |'

        version_rows.append(row)



    rollback_rows = []

    rollback = data.get('rollback', {})  

    for service, version in rollback.items():

        row = f'| {service} | {version} |'

        rollback_rows.append(row)



    # Combine all parts into the full markdown table

    markdown_table = '### Services deployed:\n' + header_row + '\n' + separator_row + '\n' + '\n'.join(version_rows) + '\n### Services rollbacked:\n' + header_row + '\n' + separator_row + '\n' + '\n'.join(rollback_rows)



    return markdown_table



def main():

    source_file = os.getenv('INPUTS_SOURCE_FILE')

    target_file = os.getenv('INPUTS_TARGET_FILE')

    print_job_summary = os.getenv('INPUTS_PRINT_JOB_SUMMARY')

    repo = os.getenv('INPUTS_REPO', REPO)



    if not source_file or not target_file:

        print("Source or target file are not set")

        sys.exit(1)



    source_path = f"releases/{source_file}"

    target_path = f"releases/{target_file}"



    # Fetch source YAML

    source_repo_response_content = get_repo_file_content(repo, source_path)

    if not source_repo_response_content:

        print("Source file not found")

        sys.exit(1)

    source_data = yaml.safe_load(base64.b64decode(source_repo_response_content['content']))



    # Fetch target YAML

    target_repo_response_content = get_repo_file_content(repo, target_path)

    if not target_repo_response_content:

        print("Target file not found")

        if "ALLOW_MISSING_TARGET_FILE" in os.environ:

            print("Will create an empty target")

            target_sha = ""

            target_data = {}

        else:

            print("Missing target file not allowed")

            exit(1)

    else:

        target_sha = target_repo_response_content['sha']

        target_data = yaml.safe_load(base64.b64decode(target_repo_response_content['content']))



    # Create backup file if INPUTS_BACKUP_FILE is defined

    if 'INPUTS_BACKUP_FILE' in os.environ:

        backup_file = os.getenv('INPUTS_BACKUP_FILE')

        target_path_backup = f"releases/{backup_file}"

        target_repo_backup_response_content = get_repo_file_content(repo, target_path_backup)

        if target_repo_backup_response_content:

            print("Backup file already exists, skipping backup creation")

        else:

            print("Creating backup file")

            target_backup_sha = ""

            if not update_file_with_retries(repo, target_path_backup, yaml.dump(target_data, indent=2), target_backup_sha, f"Create {backup_file} file"):  

                print("Failed to create backup file")  

                sys.exit(1)  



    # Ensure target_data has a 'versions' key to merge into  

    if 'versions' not in target_data or "CLEAN_DESTINATION_CONTENT" in os.environ:

        target_data['versions'] = {}



    # Merge only the 'versions' from source_data into target_data  

    target_data['versions'].update(source_data.get('versions', {})) 



    # If INCLUDE_ROLLBACK_SERVICES is true, merge 'rollback' services with precedence  

    if "INCLUDE_ROLLBACK_SERVICES" in os.environ:

        rollback_services = source_data.get('rollback', {})  

        target_data['versions'].update(rollback_services)  # Rollback services take precedence  



    if not update_file_with_retries(repo, target_path, yaml.dump(target_data, indent=2), target_sha,  

        f"Update {target_file} file with versions from {source_file}"):  

        print("Failed to update target")  

        sys.exit(1)  



    if print_job_summary and "GITHUB_STEP_SUMMARY" in os.environ:

        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:

            if print_job_summary == "target":

                markdown_title = target_file

                markdown_data = version_data_to_markdown_table(target_data)

            if print_job_summary == "source":

                markdown_title = source_file

                markdown_data = version_data_to_markdown_table(source_data)

            f.write(f"## {markdown_title}\n\n{markdown_data}\n")



    if "GITHUB_ENV" in os.environ:  

        with open(os.environ["GITHUB_ENV"], "a") as f: 

            f.write('RELEASE_SERVICES<<EOF\n')

            f.write(yaml.dump(target_data, indent=2) + '\n')

            f.write('EOF\n') 



    print(f"{target_file} updated successfully")



if __name__ == "__main__":

    main()

