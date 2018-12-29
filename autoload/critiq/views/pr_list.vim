
" The pull request list when you type :Critiq

fu! s:browse_from_pr_list()
	let pr = t:critiq_pull_requests[line('.') - 1]
	call critiq#pr#browse_pr(pr)
endfu

fu! s:load_more_prs()
	if len(t:critiq_pull_requests) < t:critiq_pull_request_total
		let t:critiq_pull_request_page += 1
		let args = [function('s:on_load_more_prs'), t:critiq_pull_request_page] +
			\ t:critiq_repositories
		call call("critiq#pr#list_open_prs", args)
	else
		echoerr 'No more pull requests to load'
	endif
endfu

fu! s:format_pr_list(prs)
	let lines = []
	for pr in a:prs
		let line = '#' . pr['number'] . ' (' . pr['user']['login'] . '): ' . pr['title'] . ' '
		let i = 0
		for label in pr['labels']
			let line .= '[' . label['name'] . ']'
			let i += 1
			if(i < len(pr['labels']))
				let line .= ' '
			endif
		endfor
		call add(lines, line)
	endfor
	return lines
endfu

fu! s:hollow_tab(lines)
	setl buftype=nofile
	setl noswapfile
	call setline(1, a:lines)
	setl nomodifiable
endfu

fu! s:on_pull_requests(prs, total)
	let t:critiq_pull_requests = a:prs
	let t:critiq_pull_request_total = a:total
	let lines = s:format_pr_list(a:prs)

	call s:hollow_tab(lines)

	command! -buffer CritiqOpenPr call critiq#views#pr#render()
	command! -buffer CritiqBrowsePr call s:browse_from_pr_list()
	command! -buffer CritiqBrowseIssue call critiq#jira#cursor_browse_issue()
	command! -buffer CritiqLoadMorePrs call s:load_more_prs()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> l :CritiqLoadMorePrs<cr>
		nnoremap <buffer> q :tabc<cr>
		nnoremap <buffer> o :CritiqOpenPr<cr>
		nnoremap <buffer> <cr> :CritiqOpenPr<cr>
		nnoremap <buffer> gp :CritiqBrowsePr<cr>
		nnoremap <buffer> gi :CritiqBrowseIssue<cr>
	endif
	
	call critiq#trigger_event('CritiqPrList')

endfu

fu! s:on_load_more_prs(prs, total)
	let t:critiq_pull_requests = t:critiq_pull_requests + a:prs
	let lines = s:format_pr_list(a:prs)
	setl modifiable
	call setline('$', lines)
	setl nomodifiable
endfu

fu! critiq#views#pr_list#render(...)
	tabnew
	let t:critiq_pull_request_page = 1
	let t:critiq_pr_list_options = {}
	let t:critiq_repositories = []
	for command_arg in a:000
		let matched = matchlist(command_arg, '^-\([a-z_]\+\)=\(.*\)$')
		if len(matched) > 0
			let key = matched[1]
			let value = matched[2]
			if has_key(t:critiq_pr_list_options, key)
				call add(t:critiq_pr_list_options[key], value)
			else
				let t:critiq_pr_list_options[key] = [value]
			endif
		else
			call add(t:critiq_repositories, command_arg)
		endif
	endfor
	let t:critiq_repo_labels = {}
	call critiq#pr#list_open_prs(
		\ t:critiq_repositories,
		\ 1,
		\ t:critiq_pr_list_options,
		\ function('s:on_pull_requests')
		\ )
endfu
