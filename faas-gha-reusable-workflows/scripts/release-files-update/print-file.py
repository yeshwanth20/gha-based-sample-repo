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



def get_repo_file_content(repo, path):

    url = f"{GITHUB_API_URL}/repos/{repo}/contents/{path}"

    print(f"Getting file from {url}")

    response = requests.get(url, headers=HEADERS)

    if response.status_code == 200:

        return response.json()

    return None



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



    # Combine all parts into the full markdown table

    markdown_table = '### Services to be deployed:\n' + header_row + '\n' + separator_row + '\n' + '\n'.join(version_rows)



    return markdown_table



def main():

    file = os.getenv('INPUTS_FILE')

    repo = os.getenv('INPUTS_REPO', REPO)



    if not file:

        print("File is not set")

        sys.exit(1)



    path = f"releases/{file}"



    # Fetch YAML

    repo_response_content = get_repo_file_content(repo, path)

    if not repo_response_content:

        print("File not found")

        sys.exit(1)

    

    data = yaml.safe_load(base64.b64decode(repo_response_content['content']))



    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:

        markdown_title = "Release services"

        markdown_data = version_data_to_markdown_table(data)

        f.write(f"## {markdown_title}\n\n{markdown_data}\n")



if __name__ == "__main__":

    main()

