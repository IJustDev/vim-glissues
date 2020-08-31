" Vim global plugin for accessing GitLab issues
"
" Maintainer:	sirjofri <https://github.com/sirjofri>
"
if exists("g:loaded_glissues") || &cp
	finish
endif
let g:loaded_glissues = 1

" Section: Default Values
"
if !exists("g:gitlab_token")
	let g:gitlab_token = ""
endif

if !exists("g:gitlab_server")
	let g:gitlab_server = "https://gitlab.com"
endif

if !exists("g:gitlab_server_port")
	let g:gitlab_server_port = "443"
endif

if !exists("g:gitlab_alter")
	let g:gitlab_alter = v:true
endif

if !exists("g:gitlab_debug")
	let g:gitlab_debug = v:false
endif


function! s:ReadGitLabProjectIdFromConfig()
    if !exists("g:gitlab_projectid")
        " try to fetch id from git remote
        if filereadable(glob("./settings.json"))
            let l:lines = readfile(glob("./settings.json"))
            let l:json = join(l:lines, "\n")
            let l:settings = json_decode(l:json)
            let g:gitlab_projectid = l:settings["projectId"]
        else
            let g:gitlab_projectid = ""
        endif
    endif
endfunction

function! s:LoadMergeRequests()
    call s:ReadGitLabProjectIdFromConfig()
	let l:command = "sh -c \"curl -s --header 'PRIVATE-TOKEN: ".g:gitlab_token."' ".g:gitlab_server.":".g:gitlab_server_port."/api/v4/projects/".g:gitlab_projectid."/merge_requests\""

    let l:json = system(l:command)
    let l:data = json_decode(l:json)

    execute "vnew"

    syntax match Success /success/
    syntax match Failed /failed/
    syntax match Pending /pending/
    syntax match Canceled /canceled/

    highlight Success ctermfg=green
    highlight Failed ctermfg=red
    highlight Pending ctermfg=cyan
    highlight Canceled ctermfg=grey

    let l:index = 0 

    for l:pipeline in l:data
        let l:timestamp = l:pipeline["created_at"]
        let l:time = system("date -d ".l:timestamp." \"+%d.%m.%Y %H:%M:%S\"")
        let l:str = l:pipeline["merge_status"]." - "." - ".l:time

        if l:index == 0
            execute "normal i".l:str
        else
            execute "normal o".l:str
        endif

        let l:index += 1
    endfor
endfunction

function! s:LoadPipelines()
    call s:ReadGitLabProjectIdFromConfig()
	let l:command = "sh -c \"curl -s --header 'PRIVATE-TOKEN: ".g:gitlab_token."' ".g:gitlab_server.":".g:gitlab_server_port."/api/v4/projects/".g:gitlab_projectid."/pipelines\""

    let l:json = system(l:command)
    let l:data = json_decode(l:json)

    execute "vnew"

    syntax match Success /success/
    syntax match Failed /failed/
    syntax match Pending /pending/
    syntax match Canceled /canceled/

    highlight Success ctermfg=green
    highlight Failed ctermfg=red
    highlight Pending ctermfg=cyan
    highlight Canceled ctermfg=grey

    let l:index = 0 

    for l:pipeline in l:data
        let l:timestamp = l:pipeline["created_at"]
        let l:time = system("date -d ".l:timestamp." \"+%d.%m.%Y %H:%M:%S\"")
        let l:str = l:pipeline["status"]." - ".l:pipeline["ref"]. " - ".l:time

        if l:index == 0
            execute "normal i".l:str
        else
            execute "normal o".l:str
        endif

        let l:index += 1
    endfor
endfunction

" Section: Loading of issues is done here
"
function! s:LoadIssues(state, notes)
    call s:ReadGitLabProjectIdFromConfig()
	let l:command = "sh -c \"curl -s --header 'PRIVATE-TOKEN: ".g:gitlab_token."' ".g:gitlab_server.":".g:gitlab_server_port."/api/v4/projects/".g:gitlab_projectid."/issues?state=".a:state."\""
	let l:json = system(l:command)
	let l:data = json_decode(l:json)

    execute "vnew"
    syn match IssueNumber /(#\d+)/

    highlight IssueNumber ctermfg=magenta

    let l:index = 0
    for l:iss in l:data
        let l:id = l:iss["iid"]
        let l:title = l:iss["title"]
        let l:tags = l:iss["labels"]
        let l:description = l:iss["description"]

        let l:issue_item_stringified = "#".l:id." - ".l:title." - [".join(l:tags,", ")."]"

        if l:index == 0
            execute "normal i".l:issue_item_stringified
        else
            execute "normal o".l:issue_item_stringified
        endif

        exec "normal o{{{".l:iss["description"]
        exec "normal o"

        let l:index += 1
    endfor

	setlocal buftype=nofile
    setlocal foldmethod=marker
    setlocal ro
    set syntax="markdown"
	normal gg
endfunction

" Section: Create a new issue
"
" Text will appear before the actual form
let s:pre_formular = "Fill in the form. The \"Title\" field is required, everything else is\noptional. Do __not__ remove the separating space!\nThe \"Description\" field can be multiline.\nUse `:GLSave` to send data to your gitlab server.\n"
" Number of lines in the form preamble
let s:pre_formular_count = 6

" Name of the fields
let s:title = "Title:"
let s:description = "Description:"
let s:confidential = "Confidential (true|false):"
let s:labels = "Labels:"
let s:due = "Due Date (YYYY-MM-DD):"

" Opens the NewIssue window
function! s:NewIssue()
	if !exists("g:gl_newissue_bufnr")
		new
		setlocal switchbuf=useopen,usetab
		setlocal buftype=nofile
		syntax on
		setlocal syntax=markdown
		let g:gl_newissue_bufnr = bufnr("%")
		command! -buffer GLSave :call s:SaveIssue()
	else
		execute "sb".g:gl_issues_bufnr
		normal ggVGd
	endif

	" create formular
	let l:formular = s:title." \n".s:description." \n".s:confidential." false\n".s:labels." \n".s:due." "

	" write formular
	execute "normal i".s:pre_formular
	normal G
	execute "normal o".l:formular
	execute "normal ".s:pre_formular_count."G$"
endfunction

" Send the filled form to the gitlab server
function! s:SaveIssue()
	if exists("g:gl_newissue_bufnr")
		execute "sb".g:gl_newissue_bufnr

		let l:title = substitute(getline(search("^".s:title)), "^".s:title." ", "", "")
		let l:description = substitute(join(getline(search("^".s:description), search("^".s:confidential)-1), "\n"), "^".s:description." ", "", "")
		let l:confidential = substitute(getline(search("^".s:confidential)), "^".s:confidential." ", "", "")
		let l:labels = substitute(getline(search("^".s:labels)), "^".s:labels." ", "", "")
		let l:due = substitute(getline(search("^".s:due)), "^".s:due." ", "", "")

		" debug messages
		if g:gitlab_debug
			echo l:title
			echo l:description
			echo l:confidential
			echo l:labels
			echo l:due
		endif

		let l:command = "sh -c \"curl --request POST --header 'PRIVATE-TOKEN: ".g:gitlab_token."' -G '".g:gitlab_server.":".g:gitlab_server_port."/api/v4/projects/".g:gitlab_projectid."/issues' --data-urlencode 'title=".l:title."' --data-urlencode 'description=".l:description."' --data-urlencode 'confidential=".l:confidential."' --data-urlencode 'labels=".l:labels."' --data-urlencode 'due_date=".l:due."'\""
		echo l:command

		if g:gitlab_alter
			let l:response = system(l:command)
			echo l:response
		endif

		" close buffer window
		execute "sb".g:gl_newissue_bufnr
		execute "q!"
		unlet g:gl_newissue_bufnr
	else
		echo "No formular found!"
	endif
endfunction


" Section: Mappings
"
function! <SID>GLOpenIssues()
	call s:LoadIssues("opened", v:false)
endfunction

function! <SID>GLOpenPipelines()
	call s:LoadPipelines()
endfunction

function! <SID>GLOpenMergeRequests()
	call s:LoadMergeRequests()
endfunction

function! <SID>GLOpenIssuesExt()
	call s:LoadIssues("opened", v:true)
endfunction

function! <SID>GLClosedIssues()
	call s:LoadIssues("closed", v:false)
endfunction

function! <SID>GLClosedIssuesExt()
	call s:LoadIssues("closed", v:true)
endfunction

function! <SID>GLNewIssue()
	call s:NewIssue()
endfunction

command! GLOpenIssues :call <SID>GLOpenIssues()
command! GLOpenPipelines :call <SID>GLOpenPipelines()
command! GLOpenMergeRequests :call <SID>GLOpenMergeRequests()
command! GLOpenIssuesExt :call <SID>GLOpenIssuesExt()
command! GLClosedIssues :call <SID>GLClosedIssues()
command! GLClosedIssuesExt :call <SID>GLClosedIssuesExt()
command! GLNewIssue :call <SID>GLNewIssue()


" folding stolen from tpope... again
" vim:ts=3:foldmethod=expr:foldexpr=getline(v\:lnum)=~'^\"\ Section\:'?'>1'\:getline(v\:lnum)=~#'^fu'?'a1'\:getline(v\:lnum)=~#'^endf'?'s1'\:'=':sw=3
