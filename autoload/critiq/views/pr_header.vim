
" This is the buffer right above the diff when you open a pull request.

fu s:mappings()
	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :bd<cr>
	endif

	call critiq#pr_tab_mappings()
endfu

fu s:commands()
	call critiq#pr_tab_commands()
endfu

fu! s:format_datetime(data)
	return tr(strcharpart(a:data, 0, len(a:data) - 4), 'T', ' ')
endfu

fu! s:set_text(pr)
	1,$delete
	call setline(1, 'Title: ' . a:pr.title . ' #' . a:pr.number)
	" If certain things aren't defined it means that the pull request data is not
	" finished loading.
	if exists('t:critiq_pr_reviews')
		if len(t:critiq_pr_reviews) == 0
			let last_reviewed = '<none>'
		else
			let last_reviewed = t:critiq_pr_reviews[len(t:critiq_pr_reviews) - 1].user.login
		endif
		let head = t:critiq_pull_request.head
		let base = t:critiq_pull_request.base

		if head.repo.full_name == base.repo.full_name
			let from = head.ref
		else
			let from = head.label
		endif
		let into = base.ref
	else
		let last_reviewed = '<loading...>'
		let into = '<loading...>'
		let from = '<loading...>'
	endif
	
	call setline(2, 'Merging: into [' . into . '] from [' . from . ']')
	call setline(3, 'Last Reviewer: ' . last_reviewed)

	call setline(4, 'Last Updated: ' . s:format_datetime(a:pr.updated_at))
	let body = split(a:pr.body, "\n")
	let body[0] = 'Body: ' . body[0]
	call setline(5, body)
endfu

fu! s:on_pr_reviews(pr_reviews)
	if !exists('t:critiq_pull_request')
		call critiq#request#next_response(function('s:on_pr_reviews'), a:pr_reviews)
	else
		let current_window = win_getid()
		call win_gotoid(t:critiq_header_window)
		let t:critiq_pr_reviews = a:pr_reviews
		set modifiable

		call s:set_text(t:critiq_pull_request)
		resize 15
		setl nomodifiable
		call win_gotoid(current_window)
	endif
endfu

fu! critiq#views#pr_header#render(pr)
	let diff_window = win_getid()
	new
	setl buftype=nofile
	setl noswapfile
	resize 15
	set winfixheight
	call s:set_text(a:pr)
	resize 15
	call s:commands()
	call s:mappings()
	set nomodifiable
	let t:critiq_header_window = win_getid()
	call critiq#pr#pr_reviews(a:pr, function('s:on_pr_reviews'))
	call win_gotoid(diff_window)
endfu
