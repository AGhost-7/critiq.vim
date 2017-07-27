if(empty('$JIRA_URL'))
	throw 'JIRA_URL environment variable must be specified for Jira integration to work'
endif

fu! critiq#jira#browse_issue()
	let current_line = getline(line('.'))
	let nearest = search('\w\{1,4\}-\d\+', 'n')
	let row = getcurpos()[1]
	let pattern = '\w\+-\d\+'
	let forward = searchpos(pattern, 'np')
	let backward = searchpos(pattern, 'npb')
	
	if(forward[2] && forward[0] == row)
		let start_line = forward[1]
	elseif(backward[2] && backward[0] == row)
		let start_line = backward[1]
	else
		throw "Could not find match for JIRA token"
	endif

	let issue = matchlist(strpart(current_line, start_line - 1), pattern)[0]
	let url = $JIRA_URL . '/browse/' . issue
	
	call netrw#BrowseX(url, 0)
endfu

