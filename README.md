Vim GitLab Issue Plugin
=======================

Introduction
------------

You want to access gitlab issues from within vim? With this plugin you can
access your issues. They are listed in a new buffer, but it requires vim
version 8 (json stuff), curl and grep.

Installation
------------

When using [vim-pathogen][]:

        cd /path/to/your/.vim/bundle
        git clone https://github.com/sirjofri/vim-glissues.git

You need to setup the following global vim variables:

- `g:gitlab_token`: Your gitlab token. You get this via gitlabs web interface.
- `g:gitlab_server`: The gitlab server you want to access. Defaults to
  `https://gitlab.com`. Don't use a trailing `/`!
- `g:gitlab_server_port`: Defaults to 443
- (`g:gitlab_projectid`): Your project ID. You get this via gitlabs web
  interface (project settings). The project id can be specified in a settings.json file. Whichs content should look like this:
  ```{"projectId": "your-project-id"}```
- (`g:gitlab_alter`): Should the plugin send altering requests to the server?
  (default true)
- (`g:gitlab_debug`): Print debug messages

The project id is now extracted from the `git remote -v` url! So you need to
run vim from somewhere inside your git repository. If you want to set your
project id manually:

_Optional_: For example I have in my `.vimrc`:

        if filereadable(".settings.vim")
          source .settings.vim
        endif

This way I can put a `.settings.vim` in my project repository and insert
project specific vim settings. For example:

        let g:gitlab_projectid="<my project id>"

As long as I start vim from the root directory of my project my settings are
here.

Commands
--------

- `:GLOpenIssues` Opens your open issues in a new buffer. Provided details are
  issue id (used for closing and commenting to issues via commit), title,
  description and milestone.
- `:GLOpenIssuesExt` Extended version of `:GLOpenIssues`, loads comments, too.
- `:GLClosedIssues` and `:GLClosedIssuesExt` behave similar with closed
  issues.
- `:GLNewIssue` let's you create a new issue with a formular. (`:GLSave` to
  save it)

Roadmap
-------

- <s>Create new issue</s>
- Close issue (without commit)
- View issue details (eg. <s>comments</s>, <s>milestone</s>)
- Comment to issue

License
-------

You are free to steal code from this repository. You are free to use it and to
redistribute it, in portions or the full product. When using the functional
code in any way you need to provide the full author information with it. If
you fork this software or distribute it in a modified way you need to use a
similar license. You should _not_ blame me if your software crashes, your
hardware explodes, your cat dies or anything else happens. You are free to
send me a gift. I am also happy if you tell me that you like this software.

[vim-pathogen]: https://github.com/tpope/vim-pathogen/

<!-- vim:tw=78:et:ts=8:sw=2:
-->
