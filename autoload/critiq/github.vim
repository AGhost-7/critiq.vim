
" Github functions.

let s:pass = $GH_PASS
let s:user = $GH_USER

let s:requests = {}

if !exists('g:critiq_github_url')
	let g:critiq_github_url = 'https://api.github.com'
endif

fu! s:check_gh_error(response)
	if(a:response['code'] != 200)
		if(has_key(a:response['body'], 'errors'))
			throw a:response['body']['errors'][0]
		else
			throw a:response['code'] . ': ' . a:response['body']['message'] . ' at url ' . a:response['url']
		endif
	endif
endfu

fu! s:repo_url()
	 return g:critiq_github_url . '/repos/' . s:repo
endfu

fu! s:parse_repo(lines)
	let matches = matchlist(a:lines, 'origin\s\+\(git@\|https://\)github\.com[:/]\(.\+\)\(\.git\)\?\s\+(fetch)')
	if empty(matches)
		throw 'Could not parse git url from remote'
	else
		return substitute(matches[2], '.git$', '', '')
	endif
endfu

fu! s:on_list_reviews(response)
	let id = a:response['id']
	let reviews = s:requests[id]
	call remove(s:requests, id)

	let pr_number = reviews['pending'][id]
	call remove(reviews['pending'], id)

	for pr in reviews['response']['body']
		if(pr['number'] == pr_number)
			let pr['reviews'] = a:response['body']
			break
		endif
	endfor

	if(empty(reviews['pending']))
		call reviews['callback'](reviews['response'])
	endif

endfu

fu! s:on_list_open_prs(response)
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)

	call s:check_gh_error(a:response)
	let a:response['body'] = a:response['body']['items']
	call request['callback'](a:response)
endfu

" Includes loading the reviews in parallel...
fu! critiq#github#list_open_prs(callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_list_open_prs'),
		\ }

	let page = 1
	let base_url = g:critiq_github_url . '/search/issues'
	let search_query = 'q=repo:' . s:repo . '+is:pr+state:open'
	let url = base_url . '?per_page=50&page=' . page . '&' . search_query

	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

fu! s:on_diff(response)
	let id = a:response['id']
	let request = s:requests[id]
	call remove(s:requests, id)

	call s:check_gh_error(a:response)

	call request['callback'](a:response)
endfu

fu! critiq#github#diff(pr, callback)
	let headers = [
		\ 'Accept: application/vnd.github.v3.diff'
		\ ]
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_diff'),
		\ 'headers': headers,
		\ 'raw': 1,
		\ }
	let url = s:repo_url() . '/pulls/' . a:pr['number']
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

fu! critiq#github#submit_review(pr, event, body)
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
	let url = s:repo_url() . '/pulls/' . a:pr['number'] . '/reviews'
	call critiq#request#send(url, opts)
endfu

fu! critiq#github#merge_pr(pr)
	let opts = {
		\ 'method': 'PUT',
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:check_gh_error'),
		\ }
	let url = s:repo_url() . '/pulls/' . a:pr['number'] . '/merge'
	call critiq#request#send(url, opts)
endfu

fu! critiq#github#browse_pr(pr)
	let repo = critiq#github#parse_url(systemlist('git remote -v'))
	let url = 'https://github.com/' . repo . '/pull/' . a:pr['number']
	call netrw#BrowseX(url, 0)
endfu

let s:repo = s:parse_repo(systemlist('git remote -v'))

