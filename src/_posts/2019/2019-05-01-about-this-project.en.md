---
author: christian
title: About this project
lang: en
ref: about-this-project
tags: [ docker, git, continuous integration, projects ]
---

serverless.industries is just another blog from a Nerd about
IT stuff.

The blog is open for constributions. If you interested in
write a article, visit the
[gitlab repository](https://git.brickburg.de/serverless.industries/blog)
and file a merge request. (The registration form for new accounts
is disabled because of SPAM. Write me a email.)

## Workflow

- Clone git repository
- Create a new branch
- Create a new article as markdown file in `src/_posts/`
- Push changes
- Create merge request

## How its work

The blog is generated with [Jekyll](https://jekyllrb.com/).
The software, which is also used for GitHub Pages.

On new commits on the master branch, a CI pipeline compiles
the Jekyll project into static HTML files and uploads them
to the server.

Each merge request branch is deployed as a password protected preview to
the staging server. The credencials can be found in the output of the
deployment task.

When a merge request is complete, the Pipeline makes sure, that the preview
is deleted again.

**Further infos:**

- [Jekyll Quickstart](https://jekyllrb.com/docs/)
- [Jekyll & Sass](https://jekyllrb.com/docs/assets/)
- [gitlab: CI Configuration Reference](https://docs.gitlab.com/ce/ci/yaml/)
- [gitlab: Environments and deployments](https://docs.gitlab.com/ce/ci/environments.html)
