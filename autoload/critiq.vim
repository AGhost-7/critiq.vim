
if !exists('g:critiq_comment_symbol')
	let g:critiq_comment_symbol = '↪'
endif

fu! s:trigger_event(event)
	if exists('#User#' . a:event)
		exe 'doautocmd User ' a:event
	endif
endfu

fu! s:on_pr_comments(response)
	let t:critiq_pr_comments = a:response.body
	call s:render_pr_comments()
endfu

fu! critiq#echo_cursor_comment()
	if exists('t:critiq_pr_comments')
		if !exists('b:critiq_last_position') || b:critiq_last_cursor_position != line('.')
			let b:critiq_last_cursor_position = line('.')
			if has_key(t:critiq_pr_comments_map, line('.'))
				let comment = t:critiq_pr_comments_map[line('.')]
				echom comment.body
				let b:critiq_echo_cleared = 0
			elseif exists('b:critiq_echo_cleared') && !b:critiq_echo_cleared
				echo
				let b:critiq_echo_cleared = 1
			endif
		endif
	endif
endfu

fu! s:render_pr_comments()
	if !exists('t:critiq_pr_comments_loaded') && exists('t:critiq_pull_request') && exists('t:critiq_pr_comments')
		let t:critiq_pr_comments_loaded = 1
		let t:critiq_pr_comments_map = {}
		exe 'sign define critiqcomment text=' . g:critiq_comment_symbol . ' texthl=Search'

		let pr = t:critiq_pull_request
		for comment in t:critiq_pr_comments
			if pr.head.sha == comment.commit_id
				let line_number = 1
				for line_diff in t:critiq_pr_diff
					if empty(line_diff)
						let line_number += 1
						continue
					endif

					if comment.path == line_diff.file && line_diff.file_index == comment.position
						let t:critiq_pr_comments_map[line_number] = comment
						exe 'sign place ' . line_number ' line=' . line_number . ' name=critiqcomment buffer=' . bufnr('%')
					endif
					let line_number += 1
				endfor
			endif
		endfor
		" This is for truncating the message body...
		setl shortmess+=T
		autocmd CursorMoved <buffer> call critiq#echo_cursor_comment()
	endif
endfu

fu! critiq#submit_comment()
	" For some reason double quotes are causing this to display line breaks
	" properly...
	let body = join(getline(1, '$'), "\n")
	let pr = t:critiq_pull_request
	call critiq#github#submit_comment(pr, b:critiq_line_diff, body)
	bd
endfu

fu! s:pr_tab_commands()
	command! -buffer CritiqBrowsePr call critiq#github#browse_pr(t:critiq_pull_request)
	command! -buffer CritiqBrowseIssue call critiq#jira#browse_issue(t:critiq_pull_request)
	command! -buffer CritiqMerge call critiq#github#merge_pr(t:critiq_pull_request)
	command! -buffer CritiqCheckout call critiq#checkout()
	command! -buffer CritiqPull call critiq#pull()
endfu

fu! s:pr_tab_mappings()
	nnoremap <buffer> gp :CritiqBrowsePr<cr>
	nnoremap <buffer> gi :CritiqBrowseIssue<cr>
	nnoremap <buffer> m :CritiqMerge<cr>
	nnoremap <buffer> <leader>c :CritiqCheckout<cr>
	nnoremap <buffer> <leader>p :CritiqPull<cr>
endfu

fu! critiq#comment()
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

		command! -buffer CritiqSubmitComment call critiq#submit_comment()
		call s:pr_tab_commands()

		if !exists('g:critiq_no_mappings')
			nnoremap <buffer> q :bd<cr>
			nnoremap <buffer> <cr> :CritiqSubmitComment<cr>
			call s:pr_tab_mappings()
		endif

		call s:trigger_event('CritiqComment')

		startinsert
	endif
endfu

fu! critiq#pull()
	let pr = t:critiq_pull_request
	let branch = critiq#github#pull(pr)
	echo 'Pulled down PR changes into branch: ' . branch
endfu

fu! critiq#checkout()
	let pr = t:critiq_pull_request
	let branch = critiq#github#checkout(pr)
	echo 'Checked out to branch: ' . branch
endfu

fu! critiq#submit_review(event)
	let body = join(getline(1, '$'), "\n")
	call critiq#github#submit_review(t:critiq_pull_request, a:event, body)
	bd
endfu

fu! critiq#review(state)
	let pr = t:critiq_pull_request
	belowright new
	resize 10
	let t:critiq_pull_request = pr
	let b:critiq_state = a:state
	setl buftype=nofile
	setl noswapfile

	command! -buffer CritiqSubmitReview call critiq#submit_review(b:critiq_state)

	call s:pr_tab_commands()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :bd<cr>
		nnoremap <buffer> <cr> :CritiqSubmitReview<cr>
		call s:pr_tab_mappings()
	endif

	call s:trigger_event('CritiqReview')

	startinsert
endfu

fu! s:hollow_tab(lines)
	setl buftype=nofile
	setl noswapfile
	call setline(1, a:lines)
	setl nomodifiable
endfu

fu! s:on_open_pr(response)
	let t:critiq_pull_request = a:response['body']

	command! -buffer CritiqApprove call critiq#review('APPROVE')
	command! -buffer CritiqRequestChanges call critiq#review('REQUEST_CHANGES')
	command! -buffer CritiqComment call critiq#review('COMMENT')
	command! -buffer CritiqCommentLine call critiq#comment()
	command! -buffer CritiqOpenFile call critiq#open_file()
	call s:pr_tab_commands()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :tabc<cr>
		nnoremap <buffer> ra :CritiqApprove<cr>
		nnoremap <buffer> rr :CritiqRequestChanges<cr>
		nnoremap <buffer> rc :CritiqComment<cr>
		nnoremap <buffer> c :CritiqCommentLine<cr>
		nnoremap <buffer> gf :CritiqOpenFile<cr>
		call s:pr_tab_mappings()
	endif

	call s:trigger_event("CritiqPr")

	call s:render_pr_comments()
endfu

fu! critiq#open_file()
	let line_diff = t:critiq_pr_diff[line('.') - 1]
	if !empty(line_diff)
		exe 'botright vsplit ' line_diff.file

		exe ':' line_diff.position

		call s:pr_tab_commands()

		if !exists("g:critiq_no_mappings")
			nnoremap <buffer> q :bd<cr>
			call s:pr_tab_mappings()
		endif

		call s:trigger_event("CritiqOpenFile")

		setl nomodifiable
	endif
endfu

fu! s:render_pr_labels()
	set modifiable
	let repo_labels = t:critiq_pr_labels.repo
	let pr_labels = t:critiq_pr_labels.pr
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
	let t:critiq_pr_labels.pr = a:pr_labels
	call s:render_pr_labels()
endfu

fu! critiq#toggle_label()
	call critiq#github#toggle_label(
		\ t:critiq_pull_request,
		\ t:critiq_pr_labels,
		\ line('.') - 1,
		\ function('s:on_toggle_label'))
endfu

fu! critiq#edit_labels()
	belowright new
	resize 10
	setl buftype=nofile
	setl noswapfile

	command! -buffer CritiqToggleLabel call critiq#toggle_label()
	call s:pr_tab_commands()
	call s:render_pr_labels()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :bd<cr>
		nnoremap <buffer> <cr> :CritiqToggleLabel<cr>
	endif
	
	call s:trigger_event('CritiqEditLabel')

endfu

fu! s:on_pr_labels(response)
	let t:critiq_pr_labels = a:response
	command! -buffer CritiqEditLabels call critiq#edit_labels()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> <leader>l :CritiqEditLabels<cr>
	endif
endfu

fu! s:on_open_pr_diff(response)
	let text = a:response['body']
	let pr = t:critiq_pull_requests[line('.') - 1]
	tabnew
	call s:hollow_tab(text)
	let t:critiq_pr_diff = critiq#diff#parse(text)
	setf diff
	call critiq#github#pull_request(pr, function('s:on_open_pr'))
	call critiq#github#pr_comments(pr, function('s:on_pr_comments'))
	call critiq#github#pr_labels(pr, function('s:on_pr_labels'))
endfu

fu! critiq#browse_from_pr_list()
	let pr = t:critiq_pull_requests[line('.') - 1]
	call critiq#github#browse_pr(pr)
endfu

fu! critiq#open_pr()
	let pr = t:critiq_pull_requests[line('.') - 1]
	call critiq#github#diff(pr, function('s:on_open_pr_diff'))
endfu

fu! s:on_load_more_prs(prs, total)
	let t:critiq_pull_requests = t:critiq_pull_requests + a:prs
	let lines = s:format_pr_list(a:prs)
	setl modifiable
	call setline('$', lines)
	setl nomodifiable
endfu

fu! critiq#load_more_prs()
	if len(t:critiq_pull_requests) < t:critiq_pull_request_total
		let t:critiq_pull_request_page += 1
		let args = [function('s:on_load_more_prs'), t:critiq_pull_request_page] +
			\ t:critiq_repositories
		call call("critiq#github#list_open_prs", args)
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

fu! s:on_pull_requests(prs, total)
	let t:critiq_pull_requests = a:prs
	let t:critiq_pull_request_total = a:total
	let lines = s:format_pr_list(a:prs)

	call s:hollow_tab(lines)

	command! -buffer CritiqOpenPr call critiq#open_pr()
	command! -buffer CritiqBrowsePr call critiq#browse_from_pr_list()
	command! -buffer CritiqBrowseIssue call critiq#jira#cursor_browse_issue()
	command! -buffer CritiqLoadMorePrs call critiq#load_more_prs()

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> l :CritiqLoadMorePrs<cr>
		nnoremap <buffer> q :tabc<cr>
		nnoremap <buffer> o :CritiqOpenPr<cr>
		nnoremap <buffer> <cr> :CritiqOpenPr<cr>
		nnoremap <buffer> gp :CritiqBrowsePr<cr>
		nnoremap <buffer> gi :CritiqBrowseIssue<cr>
	endif
	
	call s:trigger_event('CritiqPrList')

endfu

fu! critiq#list_pull_requests(...)
	tabnew
	let t:critiq_pull_request_page = 1
	let t:critiq_repositories = a:000
	let args = [function('s:on_pull_requests'), 1] + a:000
	call call("critiq#github#list_open_prs", args)
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

