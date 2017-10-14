
if !exists('g:critiq_comment_list_width')
	let g:critiq_comment_list_width = 80
endif

fu! critiq#views#comment_list#render() abort

	let line_diff = t:critiq_pr_diff[line('.')]
	let position = line_diff.file_index - 1
	let comments = []
	let maxchars = g:critiq_comment_list_width - 5
	let bar = repeat('-', maxchars)

	for comment in t:critiq_pr_comments
		if comment.path == line_diff.file && comment.position == position
			if len(comments) > 0
				call extend(comments, ['', bar])
			endif
			let username = comment.user.login
			let timestamp = comment.created_at
			let padding = repeat(' ', maxchars - len(timestamp) - len(username))
			call add(comments, username . padding . timestamp)
			call add(comments, '')
			call extend(comments, split(comment.body, "\n"))
		endif
	endfor

	vertical belowright new
	exe 'vertical resize' g:critiq_comment_list_width
	setl buftype=nofile
	setl noswapfile
	call setline(1, comments)
	set ft=markdown
	setl nomodifiable

	if !exists('g:critiq_no_mappings')
		nnoremap <buffer> q :bd<cr>
	endif
endfu
