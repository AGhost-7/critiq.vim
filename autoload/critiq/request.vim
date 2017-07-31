
" Http client written using the neovim job api. Relies on cUrl to make http
" requests, meaning you will need to have it installed for this to work.

let s:requests = {}

fu! s:chunk_handler(id, data, event)
	if !has_key(s:requests, a:id)
		throw "Could not find http handler"
	endif
	let chunks = s:requests[a:id][a:event]
	for line in a:data
		call add(chunks, line)
	endfor
endfu

fu! s:exit_handler(id, data, event)
	if !has_key(s:requests, a:id)
		throw "Could not find http handler"
	endif
	let response = s:requests[a:id]
	call remove(s:requests, a:id)
	let stdout = response['stdout']
	let response['code'] = +stdout[len(stdout) - 1]
	let raw = has_key(response['options'], 'raw') && response['options']['raw']
	if len(stdout) == 1
		let response['body'] = raw ? '' : {}
	else
		let body = stdout[0: len(stdout) - 2]
		if raw
			let response['body'] = body
		else
			let response['body'] = json_decode(join(body, ''))
		endif
	endif
	call response['options']['callback'](response)
endfu

let s:handler_options = {
	\ 'on_stdout': function('s:chunk_handler'),
	\ 'on_stderr': function('s:chunk_handler'),
	\ 'on_exit': function('s:exit_handler'),
	\ }

fu! s:method_parameter(options)
	if !has_key(a:options, 'method')
		return '-XGET'
	else
		return '-X' . toupper(a:options['method'])
	endif
endfu

fu! critiq#request#send(url, options)
	let cmd = [
		\ 'curl',
		\ '-q',
		\ '-L',
		\ '-w',
		\ '%{http_code}',
		\ s:method_parameter(a:options)
		\ ]

	if has_key(a:options, 'headers')
		for header in a:options['headers']
			call add(cmd, '-H')
			call add(cmd, header)
		endfor
	endif

	if has_key(a:options, 'data')
		call add(cmd, '--data')
		call add(cmd, json_encode(a:options['data']))
	endif

	if has_key(a:options, 'user')
		call add(cmd, '--user')
		call add(cmd, a:options['user'])
	endif

	call add(cmd, a:url)

	let id = jobstart(cmd, s:handler_options)

	let s:requests[id] = {
		\ 'id': id,
		\ 'url': a:url,
		\ 'options': a:options,
		\ 'stderr': [],
		\ 'stdout': [],
		\ }

	return id
endfu

fu! critiq#request#await_response()
	let cnt = 10000
	while !empty(s:requests)
		sleep 10m
		let cnt -= 10
		if cnt == 0
			throw "Request timeout"
		endif
	endwhile
endfu

