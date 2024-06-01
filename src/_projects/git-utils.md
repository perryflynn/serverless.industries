---
author: christian
title: git-utils
projecttype: script
projecturl: https://github.com/perryflynn/git-utils
ref: git-utils
---

`git-clean-sync` automates fetch all branches, link remote and local branches together,
pull changes on all branches, delete orphaned local branches, push all branches.

Very helpful when working with alot of feature branches and pull requests.

```txt
-t, --temp-branch     Create a temporary branch to make
                      operations on the current working copy possible
-f, --fetch           Download all current changes
-l, --link            Link local und remote branches with the same name
-p, --pull            Merge fetched changes into local branches
-d, --delete-orpaned  Delete orphaned local branches
-p, --push            Push all local branches and tags to all remotes
-s, --summary         Show an summary after all other operations
```
