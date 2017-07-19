
" Github client!

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

fu! critiq#github#repo_url()
	 return g:critiq_github_url . '/repos/' . critiq#github#parse_url(systemlist('git remote -v'))
endfu

fu! critiq#github#parse_url(lines)
	let matches = matchlist(a:lines, 'origin\s\+\(git@\|https://\)github\.com:\(.\+\)\(\.git\)\?\s\+(fetch)')
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
	let req = s:requests[id]
	call remove(s:requests, id)

	call s:check_gh_error(a:response)

	let body = a:response['body']
	if(empty(body))
		call req['callback'](a:response)
	else
		let reviews = {
			\ 'callback': req['callback'],
			\ 'pending': {},
			\ 'response': a:response,
			\ }
		for pr in body
			let opts = {
				\ 'callback': function('s:on_list_reviews'),
				\ 'user': s:user . ':' . s:pass,
				\ }
			let id = critiq#request#send(s:repo_url . '/pulls/' . pr['number'] . '/reviews', opts)
			let reviews['pending'][id] = pr['number']
			let s:requests[id] = reviews
		endfor
	endif
endfu

" Includes loading the reviews in parallel...
fu! critiq#github#list_open_prs(callback)
	let opts = {
		\ 'user': s:user . ':' . s:pass,
		\ 'callback': function('s:on_list_open_prs')
		\ }

	let id = critiq#request#send(s:repo_url . '/pulls?state=open', opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

fu! critiq#github#on_diff(response)
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
		\ 'callback': function('critiq#github#on_diff'),
		\ 'headers': headers,
		\ 'raw': 1,
		\ }
	let url = s:repo_url . '/pulls/' . a:pr['number']
	let id = critiq#request#send(url, opts)
	let s:requests[id] = { 'callback': a:callback }
endfu

fu! critiq#github#on_submit_review(response)
	call s:check_gh_error(a:response)
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
		\ 'callback': function('critiq#github#on_submit_review'),
		\ 'data': data,
		\ }
	let url = s:repo_url . '/pulls/' . a:pr['number'] . '/reviews'
	call critiq#request#send(url, opts)
endfu

fu! critiq#github#reload_url()
	let s:repo_url = critiq#github#repo_url()
endfu

let s:repo_url = critiq#github#repo_url()

