
if !exists("$GH_USER") || !exists("$GH_PASS")
	echoerr "GH_USER and GH_PASS must be set for critiq.vim to work."
	finish
endif

if exists("g:critiq_loaded")
	finish
endif
let g:critiq_loaded = 1

command! Critiq call critiq#list_pull_requests()

command! CritiqReload call critiq#github#reload_url()
