
let g:critiq_comment_symbol = '↪'

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
endfu

fu! s:on_open_pr_diff(response)
	let text = a:response['body']
	let pr = b:critiq_pull_requests[line('.') - 1]
	call s:hollow_tab(text)
	let b:critiq_pull_request = pr
	let b:critiq_diff = critiq#diff#parse(text)
	setf diff
	call critiq#github#full_pull_request(pr, function('s:on_open_pr'))
endfu

fu! critiq#browse_from_pr_list()
	let pr = b:critiq_pull_requests[line('.') - 1]
	call critiq#github#browse_pr(pr)
endfu


fu! critiq#open_pr()
	let pr = b:critiq_pull_requests[line('.') - 1]
	call critiq#github#diff(pr, function('s:on_open_pr_diff'))
endfu

fu! critiq#colorize_labels()
endfu

fu! critiq#on_pull_requests(response)
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
	call critiq#github#list_open_prs(function('critiq#on_pull_requests'))
endfu

