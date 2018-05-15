
fu! s:logs()
	let pr = t:critiq_pull_request

	if t:critiq_pull
		let pr_branch = pr.head.ref
	else
		let pr_branch = 'critiq/pr/' pr.number
	endif
	
	let command = 'git log --format=format:"(%aN): %s" '
	let command .= shellescape('origin/' . pr.base.ref)
	let command .= '..'
	let command .= shellescape(pr_branch)
	return systemlist(command)
endfu

fu! critiq#views#commit_list#render()
	if !exists('t:critiq_pull') && !exists('t:critiq_checkout')
		echoerr 'Must have the pull request locally'
		return
	endif

	belowright new
	resize 10
	setl buftype=nofile
	setl noswapfile
	call setline(1, s:logs())
	setl nomodifiable

	nnoremap <buffer> q :bd<cr>
endfu
