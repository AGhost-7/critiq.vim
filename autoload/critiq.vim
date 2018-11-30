
if !exists('g:critiq_comment_symbol')
	let g:critiq_comment_symbol = '↪'
endif

fu! critiq#trigger_event(event)
	if exists('#User#' . a:event)
		exe 'doautocmd User ' a:event
	endif
endfu

fu! critiq#pr_tab_commands()
	command! -buffer CritiqBrowsePr call critiq#pr#browse_pr(t:critiq_pull_request)
	command! -buffer CritiqBrowseIssue call critiq#jira#browse_issue(t:critiq_pull_request)
	command! -buffer CritiqMerge call critiq#pr#merge_pr(t:critiq_pull_request)
	command! -buffer CritiqCheckout call critiq#checkout()
	command! -buffer CritiqPull call critiq#pull()
	command! -buffer CritiqDeleteBranch call critiq#pr#delete_branch(t:critiq_pull_request)
endfu

fu! critiq#pr_tab_mappings()
	nnoremap <buffer> gp :CritiqBrowsePr<cr>
	nnoremap <buffer> gi :CritiqBrowseIssue<cr>
	nnoremap <buffer> m :CritiqMerge<cr>
	nnoremap <buffer> <leader>c :CritiqCheckout<cr>
	nnoremap <buffer> <leader>p :CritiqPull<cr>
	nnoremap <buffer> <leader>d :CritiqDeleteBranch<cr>
endfu

fu! critiq#pull()
	let pr = t:critiq_pull_request
	let branch = critiq#pr#pull(pr)
	let t:critiq_pull = 1
	echo 'Pulled down PR changes into branch: ' . branch
endfu

fu! critiq#checkout()
	let pr = t:critiq_pull_request
	let branch = critiq#pr#checkout(pr)
	let t:critiq_checkout = 1
	echo 'Checked out to branch: ' . branch
endfu

fu! critiq#log(message)
	if !exists('b:critiq_logs')
		let b:critiq_logs = []
	endif
	call add(b:critiq_logs, a:message)
	if !exists('t:critiq_logs')
		let t:critiq_logs = []
	endif
	call add(t:critiq_logs, a:message)
endfu

fu! critiq#show_logs(scope)
	new
	exe 'call setline(1, ' . a:scope . ':critiq_logs)'
	setl noswapfile
	setl nomodifiable
	setl buftype=nofile
	nnoremap <buffer> q :bd<cr>
endfu
