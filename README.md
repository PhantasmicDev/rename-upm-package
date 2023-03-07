# Bash Action Template

A template for a [custom GitHub action](https://docs.github.com/en/actions/creating-actions/about-custom-actions) that runs a bash script. This is a [composite action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action) that runs the `run.sh` script to execute custom logic for the action. Since it's a composite action, you can still add other steps such as calling other GitHub actions or running code in a `- run: ...` block.

## Usage
1. Click the green **Use this template** button then **Create a new repository**
2. Fill in your new repo's information and click **Create repository from template**
3. The **Initialize** workflow will be trigger which will:
    - Replace the README.md text with a heading of you action's name based on the repo name
    - Remove the current license
    - Update the following entries in the action.yml file
      - 'name' is set to your action's name based on the repo's name
      - 'author' is set to the name of the repo's owner
      - 'description' is set to the description provided when creating the new repo
    - Delete the initialization.yml workflow file
