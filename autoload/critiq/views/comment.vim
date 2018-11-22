
fu! s:submit_comment()
	" For some reason double quotes are causing this to display line breaks
	" properly...
	let body = join(getline(1, '$'), "\n")
	let pr = t:critiq_pull_request
	call critiq#pr#submit_comment(pr, b:critiq_line_diff, body)
	bd
endfu

fu! critiq#views#comment#render()
	let line_diff = t:critiq_pr_diff[line('.') - 1]
	let pr = t:critiq_pull_request
	if empty(line_diff)
		echoerr "Invalid comment location"
	else
		belowright new
		resize 10
		let b:critiq_line_diff = line_diff
		let t:critiq_pull_request = pr
		setl buftype=nofile
		setl noswapfile

		command! -buffer CritiqSubmitComment call s:submit_comment()
		call critiq#pr_tab_commands()

		if !exists('g:critiq_no_mappings')
			nnoremap <buffer> q :bd<cr>
			nnoremap <buffer> <cr> :CritiqSubmitComment<cr>
			call critiq#pr_tab_mappings()
		endif

		call critiq#trigger_event('CritiqComment')

		startinsert
	endif
endfu

