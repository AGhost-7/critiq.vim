
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

fu! s:set_text(pr)
	call setline(1, 'Title: ' . a:pr.title . ' #' . a:pr.number)
	" If certain things aren't defined it means that the pull request data is not
	" finished loading.
	if exists('t:critiq_pr_reviews')
		let last_reviewed = t:critiq_pr_reviews[len(t:critiq_pr_reviews) - 1].user.login
	else
		let last_reviewed = '<loading...>'
	endif

	call setline(2, 'Last Reviewer: ' . last_reviewed)
	call setline(3, 'Last Updated: ' . a:pr.updated_at)

	call setline(4, 'Body: ' . a:pr.body)
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
		set nomodifiable
		call win_gotoid(current_window)
	endif
endfu

fu! critiq#views#pr_header#render(pr)
	let diff_window = win_getid()
	new
	setl buftype=nofile
	setl noswapfile
	resize 15
	call s:set_text(a:pr)
	call s:commands()
	call s:mappings()
	set nomodifiable
	let t:critiq_header_window = win_getid()
	call critiq#github#pr_reviews(a:pr, function('s:on_pr_reviews'))
	call win_gotoid(diff_window)
endfu
