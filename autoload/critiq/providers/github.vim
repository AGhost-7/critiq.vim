
" Github functions.

let s:pass = $GH_PASS
let s:user = $GH_USER

let s:requests = {}
let s:handlers = {}

if !exists('g:critiq_github_url')
	let g:critiq_github_url = 'https://api.github.com'
endif

" {{{ misc
fu! s:check_gh_error(response)
	if a:response['code'] >= 300 || a:response['code'] < 200
		if has_key(a:response['body'], 'errors')
			let message = a:response['body']['message'] . ': '
			let i = 0
			for error in a:response['body']['errors']
				let message .= error['field']
				let i += 1
				if len(a:response['body']['errors']) > i
					let message += ', '
				endif
			endfor
			throw message
		else
			throw a:response['code'] . ': ' . a:response['body']['message'] . ' at url ' . a:response['url']
		endif
	endif
endfu

fu! s:issue_repo_url(issue)
	return a:issue.repository_url
endfu

" Returns the repo url for both issues and pull requests.
fu! s:repo_url(issue)
	if has_key(a:issue, 'repository_url')
		return a:issue.repository_url
	else
		return a:issue.head.repo.url
	endif
endfu
let s:handlers['repo_url'] = function('s:repo_url')

fu! s:pr_repo_url(pr)
	return g:critiq_github_url . '/repos/' . a:pr['head']['repo']['full_name']
endfu

fu! s:parse_repo(lines)
	let matches = matchlist(a:lines, 'origin\s\+\(git@\|https://\)github\.com[:/]\(.\+\)\(\.git\)\?\s\+(fetch)')
	if empty(matches)
		throw 'Could not parse git url from remote'
	else
		return substitute(matches[2], '.git$', '', '')
	endif
endfu

fu! s:format_object(obj)
	for key in keys(a:obj)
		let value = a:obj[key]
		if type(value) == v:t_string
			let a:obj[key] = substitute(value, "\r\n", "\n", 'g')
		endif
	endfor
endfu

fu! s:format_list(items)
	for item in a:items
		call s:format_object(item)
	endfor
endfu
" }}}

" {{{ list_open_prs
fu! s:on_list_open_prs(response) abort
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)

	call s:check_gh_error(a:response)
	let prs = a:response.body.items
	call s:format_list(prs)
	let total = a:response.body.total_count
	call request['callback'](prs, total)
endfu

fu! s:list_open_prs(callback, page, ...)

	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_list_open_prs'),
		\ }

	let base_url = g:critiq_github_url . '/search/issues'

	if a:0 == 0
		let repo = s:parse_repo(systemlist('git remote -v'))
		let search_query = 'q=repo:' . repo . '+is:pr+state:open'
	else
		let search_query = 'q='
		for repo in a:000
			let search_query .= 'repo:' . repo . '+'
		endfor
		let search_query .= 'is:pr+state:open'
	endif

	let url = base_url . '?per_page=50&page=' . a:page . '&' . search_query

	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['list_open_prs'] = function('s:list_open_prs')
" }}}

" {{{ pull_request
fu! s:on_pull_request(response)
	let id = a:response.id
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)
	call s:format_object(a:response['body'])
	call request['callback'](a:response)
endfu

" Loads the pull request from the issue
fu! s:pull_request(issue, callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_pull_request'),
		\ }
	let url = s:issue_repo_url(a:issue) . '/pulls/' . a:issue['number']
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['pull_request'] = function('s:pull_request')
" }}}

" {{{ diff
fu! s:on_diff(response) abort
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)

	call request['callback'](a:response)
endfu

fu! s:diff(issue, callback)
	let headers = [
		\ 'Accept: application/vnd.github.v3.diff'
		\ ]
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_diff'),
		\ 'headers': headers,
		\ 'raw': 1,
		\ }
	let url = s:issue_repo_url(a:issue) . '/pulls/' . a:issue['number']
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['diff'] = function('s:diff')
" }}}

" {{{ submit_review
fu! s:submit_review(pr, event, body)
	let data = {
		\ 'body': a:body,
		\ 'event': a:event,
		\	'comments': [],
		\ }

	let opts = {
		\ 'method': 'POST',
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:check_gh_error'),
		\ 'data': data,
		\ }
	let url = s:pr_repo_url(a:pr) . '/pulls/' . a:pr['number'] . '/reviews'
	call critiq#request#send(url, opts)
endfu

let s:handlers['submit_review'] = function('s:submit_review')
" }}}

" {{{ submit_comment
fu! s:submit_comment(pr, line_diff, body)
	let data = {
		\ 'body': a:body,
		\ 'commit_id': a:pr['head']['sha'],
		\ 'position': a:line_diff['file_index'],
		\ 'path': a:line_diff['file'],
		\ }

	let opts = {
		\ 'method': 'POST',
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:check_gh_error'),
		\ 'data': data,
		\ }

	let url = s:pr_repo_url(a:pr) . '/pulls/' . a:pr['number'] . '/comments'

	let id = critiq#request#send(url, opts)
endfu

let s:handlers['submit_comment'] = function('s:submit_comment')
" }}}

" {{{ merge_pr
fu! s:merge_pr(pr)
	let opts = {
		\ 'method': 'PUT',
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:check_gh_error'),
		\ }
	let url = s:pr_repo_url(a:pr) . '/pulls/' . a:pr['number'] . '/merge'
	call critiq#request#send(url, opts)
endfu

let s:handlers['merge_pr'] = function('s:merge_pr')
" }}}

" {{{ browse_pr
fu! s:browse_pr(pr)
	let url = 'https://github.com/' . a:pr['head']['repo']['full_name'] . '/pull/' . a:pr['number']
	call netrw#BrowseX(url, 0)
endfu

let s:handlers['browse_pr'] = function('s:browse_pr')
" }}}

" {{{ pr_comments
fu! s:on_pr_comments(response) abort
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)
	call request['callback'](a:response)
endfu

fu! s:pr_comments(issue, callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_pr_comments'),
		\ }

	let url = s:issue_repo_url(a:issue) . '/pulls/' . a:issue['number'] . '/comments'
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['pr_comments'] = function('s:pr_comments')
" }}}

" {{{ git commands
fu! s:ensure_not_wip()
	let status = system('git status -s')
	if len(status) != 0
		throw 'Current branch as uncommited changes'
	endif
endfu

" {{{ checkout
fu! s:checkout(pr)
	call s:ensure_not_wip()
	let sha = a:pr.head.sha
	let branch = 'critiq/pr/' . a:pr.number
	let remote_branch = 'pull/' . a:pr.number . '/head:' . branch
	call system('git fetch --update-head-ok origin ' . shellescape(remote_branch))
	call system('git checkout ' . shellescape(branch))
	return branch
endfu

let s:handlers['checkout'] = function('s:checkout')
" }}}

" {{{ pull
fu! s:pull(pr)
	call s:ensure_not_wip()
	let branch = a:pr.head.ref
	call system('git fetch origin')
	call system('git checkout ' . shellescape(branch))
	call system('git merge '. shellescape('origin/' . branch))
	return branch
endfu

let s:handlers['pull'] = function('s:pull')
" }}}

" }}}

" {{{ repo_labels
fu! s:on_repo_labels(response)
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)

	call request['callback'](a:response.body)
endfu

fu! s:repo_labels(issue, callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_repo_labels'),
		\ }
	let url = s:issue_repo_url(a:issue) . '/labels'
	let id = critiq#request#send(url, opts)

	let s:requests[id] = { 'callback': a:callback, 'issue': a:issue }
endfu

let s:handlers['repo_labels'] = function('s:repo_labels')
" }}}

" {{{ toggle_label
fu! s:on_toggle_label(response)
	let id = a:response.id
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)
	call request.callback(a:response.body)
endfu

fu! s:toggle_label(pr, repo_labels, pr_labels, label_index, callback)
	let toggle_label = a:repo_labels[a:label_index]

	let found = 0
	for label in a:pr_labels
		if toggle_label.id == label.id
			let found = 1
			break
		endif
	endfor

	let url = s:pr_repo_url(a:pr) . '/issues/' . a:pr['number'] . '/labels'
	let request = {
		\ 'callback': a:callback,
		\ }

	let opts = {
		\ 'callback': function('s:on_toggle_label'),
		\ 'user': s:user . ':' . s:pass
		\ }

	if found
		let url .= '/' . substitute(toggle_label['name'], ' ', '%20', 'g')
		let opts.method = 'DELETE'
	else
		call extend(opts, { 'method': 'POST', 'data': [toggle_label.name] })
		let opts.method = 'POST'
	endif

	let id = critiq#request#send(url, opts)
	let s:requests[id] = request

endfu
let s:handlers['toggle_label'] = function('s:toggle_label')
" }}}

" {{{ pr_reviews
fu! s:on_pr_reviews(response) abort
	let id = a:response.id
	let request = s:requests[id]
	call remove(s:requests, id)
	call s:check_gh_error(a:response)
	call request['callback'](a:response.body)
endfu

fu! s:pr_reviews(issue, callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_pr_reviews')
		\ }
	let url = s:issue_repo_url(a:issue) . '/pulls/' . a:issue['number'] . '/reviews'
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

let s:handlers['pr_reviews'] = function('s:pr_reviews')
" }}}

" {{{ request
fu! critiq#providers#github#request(function_name, args)
	let Handler = s:handlers[a:function_name]
	return call(Handler, a:args)
endfu
" }}}
