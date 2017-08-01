
let g:critiq_comment_symbol = '↪'

fu! s:on_pr_comments(response)
	let b:critiq_pr_comments = a:response.body
	call s:render_pr_comments()
endfu

fu! critiq#echo_cursor_comment()
	if exists('b:critiq_pr_comments')
		if !exists('b:critiq_last_position') || b:critiq_last_cursor_position != line('.')
			let b:critiq_last_cursor_position = line('.')
			if has_key(b:critiq_pr_comments_map, line('.'))
				let comment = b:critiq_pr_comments_map[line('.')]
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
	if !exists('b:critiq_pr_comments_loaded') && exists('b:critiq_pull_request')
		let b:critiq_pr_comments_loaded = 1
		let b:critiq_pr_comments_map = {}
		exe 'sign define critiqcomment text=' . g:critiq_comment_symbol . ' texthl=Search'

		let pr = b:critiq_pull_request
		for comment in b:critiq_pr_comments
			if pr.head.sha == comment.commit_id
				let line_number = 1
				for line_diff in b:critiq_diff
					if empty(line_diff)
						let line_number += 1
						continue
					endif

					if comment.path == line_diff.file && line_diff.position == comment.position
						let b:critiq_pr_comments_map[line_number] = comment
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
	let body = join(getline(1, '$'), '\n')
	let pr = b:critiq_pull_request
	call critiq#github#submit_comment(pr, b:critiq_line_diff, body)
	bd
endfu

fu! critiq#comment()
	let line_diff = b:critiq_diff[line('.') - 1]
	let pr = b:critiq_pull_request
	if empty(line_diff)
		echoerr "Invalid comment location"
	else
		belowright new
		resize 10
		let b:critiq_line_diff = line_diff
		let b:critiq_pull_request = pr
		setl buftype=nofile
		setl noswapfile
		startinsert
		nnoremap <buffer> q :bd<cr>
		nnoremap <buffer> s :call critiq#submit_comment()<cr>
	endif
endfu

fu! critiq#checkout()
	let pr = b:critiq_pull_request
	let branch = critiq#github#checkout(pr)
	echo 'Checked out to branch: ' . branch
endfu

fu! critiq#send_review(event)
	let body = join(getline(1, '$'), '\n')
	call critiq#github#submit_review(b:critiq_pull_request, a:event, body)
	bd
endfu

fu! critiq#review(state)
	let pr = b:critiq_pull_request
	belowright new
	resize 10
	let b:critiq_pull_request = pr
	let b:critiq_state = a:state
	setl buftype=nofile
	setl noswapfile
	startinsert
	setf critiq_review
endfu

fu! s:hollow_tab(lines)
	tabnew
	setl buftype=nofile
	setl noswapfile
	call setline(1, a:lines)
	setl nomodifiable
endfu

fu! s:on_open_pr(response)
	let b:critiq_pull_request = a:response['body']
	nnoremap <buffer> q :tabc<cr>
	nnoremap <buffer> ra :call critiq#review('APPROVE')<cr>
	nnoremap <buffer> rr :call critiq#review('REQUEST_CHANGES')<cr>
	nnoremap <buffer> rc :call critiq#review('COMMENT')<cr>
	nnoremap <buffer> c :call critiq#comment()<cr>
	nnoremap <buffer> m :call critiq#github#merge_pr(b:critiq_pull_request)<cr>
	nnoremap <buffer> <leader>c :call critiq#checkout()<cr>
	nnoremap <buffer> b :call critiq#github#browse_pr(b:critiq_pull_request)<cr>
	nnoremap <buffer> <leader>i :call critiq#jira#browse_issue(b:critiq_pull_request)<cr>
	call s:render_pr_comments()
endfu

fu! s:on_open_pr_diff(response)
	let text = a:response['body']
	let pr = b:critiq_pull_requests[line('.') - 1]
	call s:hollow_tab(text)
	let b:critiq_diff = critiq#diff#parse(text)
	setf diff
	call critiq#github#full_pull_request(pr, function('s:on_open_pr'))
	call critiq#github#pr_comments(pr, function('s:on_pr_comments'))
endfu

fu! critiq#browse_from_pr_list()
	let pr = b:critiq_pull_requests[line('.') - 1]
	call critiq#github#browse_pr(pr)
endfu

fu! critiq#open_pr()
	let pr = b:critiq_pull_requests[line('.') - 1]
	call critiq#github#diff(pr, function('s:on_open_pr_diff'))
endfu

fu! s:on_pull_requests(response)
	let b:critiq_pull_requests = a:response['body']

	let labels = {}
	let lines = []
	for pr in a:response['body']
		let line = '#' . pr['number'] . ' (' . pr['user']['login'] . '): ' . pr['title'] . ' '
		let i = 0
		for label in pr['labels']
			let labels[label['id']] = label
			let line .= '[' . label['name'] . ']'
			let i += 1
			if(i < len(pr['labels']))
				let line .= ' '
			endif
		endfor
		call add(lines, line)
	endfor


	call s:hollow_tab(lines)

	let b:critiq_pull_requests = a:response['body']
	let b:critiq_labels = values(labels)
	setf critiq_pr_list
endfu

fu! critiq#list_pull_requests()
	call critiq#github#list_open_prs(function('s:on_pull_requests'))
endfu

