if(empty('$JIRA_URL'))
	throw 'JIRA_URL environment variable must be specified for Jira integration to work'
endif

let s:pattern = '\w\+-\d\+'

fu! s:browse(issue)
	let url = $JIRA_URL . '/browse/' . a:issue
	call netrw#BrowseX(url, 0)
endfu

fu! critiq#jira#browse_issue(pr)
	let issue = matchstr(a:pr.title, s:pattern)

	if empty(issue)
		throw "Coud not find match for JIRA token"
	else
		call s:browse(issue)
	endif
endfu

fu! critiq#jira#cursor_browse_issue()
	let current_line = getline(line('.'))
	let nearest = search('\w\{1,4\}-\d\+', 'n')
	let row = getcurpos()[1]
	let forward = searchpos(s:pattern, 'np')
	let backward = searchpos(s:pattern, 'npb')
	
	if(forward[2] && forward[0] == row)
		let start_line = forward[1]
	elseif(backward[2] && backward[0] == row)
		let start_line = backward[1]
	else
		throw "Could not find match for JIRA token"
	endif

	let issue = matchlist(strpart(current_line, start_line - 1), s:pattern)[0]
	call s:browse(issue)
endfu

