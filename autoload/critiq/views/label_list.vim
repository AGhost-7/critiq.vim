
fu! s:render_pr_labels()
	set modifiable
	let repo_labels = t:critiq_repo_labels[t:critiq_repo_url]
	let pr_labels = t:critiq_pull_request.labels
	let lines = []

	for repo_label in repo_labels
		let found = 0
		for pr_label in pr_labels
			if pr_label.id == repo_label.id
				let found = 1
				call add(lines, '[x] ' . repo_label.name)
			endif
		endfor
		if !found
			call add(lines, '[ ] ' . repo_label.name)
		endif
	endfor

	call setline(1, lines)
	setl nomodifiable
endfu

fu! s:on_toggle_label(pr_labels)
	let t:critiq_pull_request.labels = a:pr_labels
	call s:render_pr_labels()
endfu

fu! s:toggle_label()
	call critiq#pr#toggle_label(
		\ t:critiq_pull_request,
		\ t:critiq_repo_labels[t:critiq_repo_url],
		\ t:critiq_pull_request.labels,
		\ line('.') - 1,
		\ function('s:on_toggle_label'))
endfu

fu! critiq#views#label_list#render()
	belowright new
	resize 10
	setl buftype=nofile
	setl noswapfile

	command! -buffer CritiqToggleLabel call s:toggle_label()
	call critiq#pr_tab_commands()
	call s:render_pr_labels()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :bd<cr>
		nnoremap <buffer> <cr> :CritiqToggleLabel<cr>
	endif
	
	call critiq#trigger_event('CritiqEditLabel')
endfu
